// Pantalla de escaneo por camara o ingreso manual de codigos.
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/scan_api.dart';

/// Permite consultar o crear productos a partir de un barcode o QR.
class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> with WidgetsBindingObserver {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _categoryIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _storeIdController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isLoading = false;
  bool _showCreateForm = false;
  bool _autoScanEnabled = true;
  bool _isTorchOn = false;
  bool _isHandlingDetect = false;

  String _codeType = 'barcode';
  String? _error;
  Map<String, dynamic>? _result;
  String? _lastDetectedCode;
  DateTime? _lastDetectedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _codeController.dispose();
    _categoryIdController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _storeIdController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      if (_autoScanEnabled) {
        _startCamera();
      }
      return;
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopCamera();
    }
  }

  /// Reanuda la camara cuando el usuario habilita autoescaneo.
  Future<void> _startCamera() async {
    try {
      await _cameraController.start();
    } catch (_) {}
  }

  /// Pausa la camara para ahorrar recursos y evitar lecturas duplicadas.
  Future<void> _stopCamera() async {
    try {
      await _cameraController.stop();
    } catch (_) {}
  }

  /// Alterna el flash y sincroniza el estado visible del boton.
  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      if (!mounted) return;
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  /// Restablece el flujo de autoescaneo despues de una pausa manual.
  Future<void> _resumeAutoScan() async {
    setState(() {
      _autoScanEnabled = true;
      _error = null;
      _lastDetectedCode = null;
      _lastDetectedAt = null;
    });
    await _startCamera();
  }

  /// Pausa el flujo de autoescaneo sin perder el estado del formulario.
  Future<void> _pauseAutoScan() async {
    setState(() {
      _autoScanEnabled = false;
    });
    await _stopCamera();
  }

  /// Procesa una deteccion de la camara evitando duplicados y rafagas.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_autoScanEnabled || _isLoading || _isHandlingDetect) return;

    final barcode = capture.barcodes.cast<Barcode?>().firstWhere(
      (item) => (item?.rawValue ?? '').trim().isNotEmpty,
      orElse: () => null,
    );
    if (barcode == null) return;

    final code = barcode.rawValue!.trim();
    final now = DateTime.now();
    if (_lastDetectedCode == code &&
        _lastDetectedAt != null &&
        now.difference(_lastDetectedAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastDetectedCode = code;
    _lastDetectedAt = now;
    _isHandlingDetect = true;

    setState(() {
      _codeType = _codeTypeFromBarcode(barcode);
      _codeController.text = code;
      _autoScanEnabled = false;
    });

    await _stopCamera();
    try {
      await _scanOnly();
    } finally {
      _isHandlingDetect = false;
    }
  }

  /// Clasifica el codigo detectado como QR o barcode tradicional.
  String _codeTypeFromBarcode(Barcode barcode) {
    return barcode.format == BarcodeFormat.qrCode ? 'qr' : 'barcode';
  }

  /// Consulta el backend usando solo el codigo actual.
  Future<void> _scanOnly() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = 'Ingresa un codigo para escanear.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _showCreateForm = false;
      _result = null;
    });

    try {
      final data = await ScanApi.scanCode(code: code, codeType: _codeType);
      if (!mounted) return;
      setState(() {
        _result = data;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ScanApiException && e.statusCode == 404) {
        setState(() {
          _showCreateForm = true;
          _error =
              'El codigo no existe en catalogo. Completa los datos para crear el producto.';
        });
      } else if (e is ScanApiException) {
        setState(() {
          _error = e.message;
        });
      } else {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Envia los datos manuales para crear un producto desde el escaneo.
  Future<void> _createFromScan() async {
    final code = _codeController.text.trim();
    final categoryId = int.tryParse(_categoryIdController.text.trim());
    final storeId = int.tryParse(_storeIdController.text.trim());

    if (code.isEmpty) {
      setState(() {
        _error = 'Ingresa un codigo para crear el producto.';
      });
      return;
    }
    if (categoryId == null) {
      setState(() {
        _error = 'Ingresa category_id valido.';
      });
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Ingresa nombre del producto.';
      });
      return;
    }
    if (storeId == null) {
      setState(() {
        _error = 'Ingresa store_id valido.';
      });
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      setState(() {
        _error = 'Ingresa precio.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await ScanApi.scanCode(
        code: code,
        codeType: _codeType,
        categoryId: categoryId,
        name: _nameController.text,
        brand: _brandController.text,
        description: _descriptionController.text,
        storeId: storeId,
        price: _priceController.text,
      );

      if (!mounted) return;
      setState(() {
        _result = data;
        _showCreateForm = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ScanApiException) {
        setState(() {
          _error = e.message;
        });
      } else {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _result?['product'];
    final matched = _result?['matched'] == true;
    final productMap = product is Map<String, dynamic> ? product : null;
    final priceRows = productMap == null ? const <Map<String, dynamic>>[] : _productPriceRows(productMap);

    return Scaffold(
      appBar: AppBar(title: const Text('Escaneo de productos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E6846), Color(0xFF2F7D57), Color(0xFF52A66C)],
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Escaneo real con camara o ingreso manual, conectado a tu API.',
                    style: TextStyle(
                      color: Color(0xFFEAF9ED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE3E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camara',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A33),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _cameraController,
                          onDetect: _onDetect,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0x66FFFFFF),
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _autoScanEnabled
                            ? (_isLoading ? null : _pauseAutoScan)
                            : (_isLoading ? null : _resumeAutoScan),
                        icon: Icon(
                          _autoScanEnabled
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                        ),
                        label: Text(
                          _autoScanEnabled ? 'Pausar autoescaneo' : 'Reanudar',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _toggleTorch,
                      icon: Icon(
                        _isTorchOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                      ),
                      label: const Text('Flash'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE3E8)),
            ),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'barcode',
                      icon: Icon(Icons.qr_code_2_rounded),
                      label: Text('Barcode'),
                    ),
                    ButtonSegment<String>(
                      value: 'qr',
                      icon: Icon(Icons.qr_code_scanner_rounded),
                      label: Text('QR'),
                    ),
                  ],
                  selected: {_codeType},
                  onSelectionChanged: (value) {
                    if (value.isEmpty) return;
                    setState(() {
                      _codeType = value.first;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Codigo',
                    hintText: 'Ej: 7501055300014',
                    prefixIcon: Icon(Icons.confirmation_num_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _scanOnly,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(_isLoading ? 'Consultando...' : 'Escanear manual'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEAEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFAC2E2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_showCreateForm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE3E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Producto no encontrado. Crear con datos reales',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2A33),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _categoryIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'category_id'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'brand'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'description'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _storeIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'store_id'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'price'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createFromScan,
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(
                        _isLoading ? 'Creando...' : 'Crear producto desde escaneo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE3E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matched ? 'Producto encontrado' : 'Respuesta de escaneo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2A33),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (product is Map<String, dynamic>) ...[
                    _resultRow('ID', '${product['id'] ?? '-'}'),
                    _resultRow('Nombre', '${product['name'] ?? '-'}'),
                    _resultRow('Marca', '${product['brand'] ?? '-'}'),
                    _resultRow('Descripcion', '${product['description'] ?? '-'}'),
                    if (_productBestPrice(product) != null)
                      _resultRow('Mejor precio', _productBestPrice(product)!),
                    _resultRow(
                      'Tiendas disponibles',
                      _productStoresAvailable(product),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Precios',
                      style: TextStyle(
                        color: Color(0xFF1F2A33),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (priceRows.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...priceRows.map(
                        (row) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDE3E8)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _priceRowStoreName(row),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2A33),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (_priceRowUpdatedAt(row) != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Actualizado: ${_priceRowUpdatedAt(row)!}',
                                        style: const TextStyle(
                                          color: Color(0xFF6A7884),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _priceRowPrice(row),
                                style: const TextStyle(
                                  color: Color(0xFF2F7D57),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      const Text(
                        'No hay precios registrados',
                        style: TextStyle(
                          color: Color(0xFF6A7884),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ] else
                    _resultRow('Respuesta', _result.toString()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Extrae una lista de precios por tienda tolerando distintos contratos.
  List<Map<String, dynamic>> _productPriceRows(Map<String, dynamic> product) {
    final prices = product['prices'];
    if (prices is! List) return const [];
    return prices.whereType<Map<String, dynamic>>().toList();
  }

  /// Devuelve el mejor precio disponible si existe una clave dedicada.
  String? _productBestPrice(Map<String, dynamic> product) {
    final raw = product['best_price'];
    if (raw == null || raw.toString().trim().isEmpty) return null;
    return '\$$raw';
  }

  /// Devuelve cuantas tiendas tienen precio para el producto.
  String _productStoresAvailable(Map<String, dynamic> product) {
    final raw = product['stores_available'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString();
    }
    return '${_productPriceRows(product).length}';
  }

  /// Resuelve el nombre de tienda para una fila de precios.
  String _priceRowStoreName(Map<String, dynamic> row) {
    final store = row['store'];
    if (store is Map<String, dynamic>) {
      final raw = store['name'] ?? store['store_name'] ?? store['title'];
      final text = (raw ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    final raw = row['store_name'] ?? row['store'] ?? row['market'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? 'Tienda' : text;
  }

  /// Devuelve la fecha de actualizacion de una fila de precios si existe.
  String? _priceRowUpdatedAt(Map<String, dynamic> row) {
    final raw = row['updated_at'];
    final text = (raw ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Formatea el precio de una fila individual.
  String _priceRowPrice(Map<String, dynamic> row) {
    final raw = row['price'] ?? row['amount'] ?? row['value'];
    if (raw == null || raw.toString().trim().isEmpty) return 'N/A';
    return '\$$raw';
  }

  /// Fila simple clave-valor para renderizar la respuesta del escaneo.
  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF6A7884),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2A33),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
