import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/scan_api.dart';

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

  Future<void> _startCamera() async {
    try {
      await _cameraController.start();
    } catch (_) {}
  }

  Future<void> _stopCamera() async {
    try {
      await _cameraController.stop();
    } catch (_) {}
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      if (!mounted) return;
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  Future<void> _resumeAutoScan() async {
    setState(() {
      _autoScanEnabled = true;
      _error = null;
      _lastDetectedCode = null;
      _lastDetectedAt = null;
    });
    await _startCamera();
  }

  Future<void> _pauseAutoScan() async {
    setState(() {
      _autoScanEnabled = false;
    });
    await _stopCamera();
  }

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

  String _codeTypeFromBarcode(Barcode barcode) {
    return barcode.format == BarcodeFormat.qrCode ? 'qr' : 'barcode';
  }

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
                    if (product['price'] != null)
                      _resultRow('Precio', '${product['price']}'),
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
