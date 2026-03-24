import 'package:flutter/material.dart';
import 'package:grocerysaver/models/address_model.dart';
import 'package:grocerysaver/models/checkout_model.dart';
import 'package:grocerysaver/services/address_service.dart';
import 'package:grocerysaver/services/checkout_service.dart';
import 'package:grocerysaver/views/orders_page.dart';
import 'package:grocerysaver/views/payment_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, this.checkoutService, this.addressService});

  final CheckoutService? checkoutService;
  final AddressService? addressService;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final CheckoutService _checkoutService;
  late final AddressService _addressService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingAddresses = true;
  bool _isBootstrapping = true;
  String? _errorMessage;
  CheckoutModel? _checkout;
  List<AddressModel> _addresses = const <AddressModel>[];
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _checkoutService = widget.checkoutService ?? CheckoutService();
    _addressService = widget.addressService ?? AddressService();
    _bootstrapPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapPage() async {
    setState(() {
      _isBootstrapping = true;
      _errorMessage = null;
    });

    await _loadAddresses();
    if (!mounted) return;

    if (_checkout == null) {
      try {
        final checkout = await _checkoutService.createCheckout();
        if (!mounted) return;
        setState(() {
          _checkout = checkout;
          _selectedAddressId = checkout.addressId ?? _selectedAddressId;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _errorMessage = error.toString());
      }
    }

    if (mounted) {
      setState(() => _isBootstrapping = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          180,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
      _errorMessage = null;
    });
    try {
      final addresses = await _addressService.fetchAddresses();
      if (!mounted) return;
      int? selected = _selectedAddressId;
      if (selected == null && addresses.isNotEmpty) {
        final defaultIndex = addresses.indexWhere((item) => item.isDefault);
        selected = defaultIndex >= 0 ? addresses[defaultIndex].id : addresses.first.id;
      }
      setState(() {
        _addresses = addresses;
        _selectedAddressId = selected;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddresses = false);
      }
    }
  }

  Future<void> _createCheckout() async {
    await _runAction(() async {
      final checkout = await _checkoutService.createCheckout(notes: _notesController.text.trim());
      if (!mounted) return;
      setState(() {
        _checkout = checkout;
        _selectedAddressId = checkout.addressId ?? _selectedAddressId;
      });
    });
  }

  Future<void> _saveAddress() async {
    final checkout = _checkout;
    final addressId = _selectedAddressId;
    if (checkout == null || addressId == null) {
      _showMessage('Selecciona una direccion antes de continuar.');
      return;
    }

    await _runAction(() async {
      final updated = await _checkoutService.updateCheckout(
        checkoutId: checkout.id,
        addressId: addressId,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _checkout = updated);
      _showMessage('Direccion guardada en el checkout.');
    });
  }

  Future<void> _openCreateAddressModal() async {
    final created = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => _CreateAddressSheet(addressService: _addressService),
    );
    if (created == null || !mounted) return;

    await _loadAddresses();
    if (!mounted) return;
    setState(() => _selectedAddressId = created.id);
    _showMessage('Direccion creada correctamente.');
  }

  Future<void> _continueToPayment() async {
    final checkout = _checkout;
    final addressId = _selectedAddressId;
    if (checkout == null) {
      _showMessage('Primero crea el checkout.');
      return;
    }
    if (addressId == null) {
      _showMessage('Selecciona una direccion antes de pagar.');
      return;
    }

    CheckoutModel readyCheckout = checkout;
    if (checkout.addressId != addressId) {
      await _runAction(() async {
        readyCheckout = await _checkoutService.updateCheckout(
          checkoutId: checkout.id,
          addressId: addressId,
          notes: _notesController.text.trim(),
        );
        if (!mounted) return;
        setState(() => _checkout = readyCheckout);
      });
      if (!mounted || _errorMessage != null) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          checkoutId: readyCheckout.id,
          amount: readyCheckout.subtotal > 0 ? readyCheckout.subtotal : null,
        ),
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final checkout = _checkout;
    final canContinue = checkout != null && _selectedAddressId != null && !_isLoading && !_isBootstrapping;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Mis ordenes',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersPage())),
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, -6))],
          ),
          child: FilledButton(
            onPressed: canContinue ? _continueToPayment : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE90059),
              disabledBackgroundColor: const Color(0xFFF2B9CF),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            child: Text(
              canContinue ? 'Continuar al pago' : 'Selecciona una direccion para continuar',
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _bootstrapPage,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16423C), Color(0xFF4E7A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Direccion y checkout',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkout == null
                          ? 'Estamos preparando tu checkout.'
                          : 'Checkout #${checkout.id} listo para continuar al pago.',
                      style: const TextStyle(color: Color(0xFFE6F2EC), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_errorMessage != null) ...[
                _CheckoutErrorCard(message: _errorMessage!),
                const SizedBox(height: 14),
              ],
              _CheckoutCard(
                title: 'Direccion de entrega',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona una direccion guardada o crea una nueva para seguir al pago.',
                      style: TextStyle(color: Color(0xFF6E6B77), height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _openCreateAddressModal,
                            icon: const Icon(Icons.add_location_alt_rounded),
                            label: const Text('Agregar direccion'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (checkout != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading || _selectedAddressId == null ? null : _saveAddress,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Guardar'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_isBootstrapping || _isLoadingAddresses)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'No tienes direcciones guardadas. Pulsa "Agregar direccion" para crear una y continuar.',
                          style: TextStyle(color: Color(0xFF6E4E1F), height: 1.4),
                        ),
                      )
                    else ...[
                      ..._addresses.map(
                        (address) => _AddressOptionCard(
                          address: address,
                          isSelected: address.id == _selectedAddressId,
                          onTap: _isLoading ? null : () => setState(() => _selectedAddressId = address.id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (checkout != null)
                _CheckoutCard(
                  title: 'Resumen del checkout',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CheckoutStatChip(label: 'Checkout', value: '#${checkout.id}'),
                      _CheckoutStatChip(label: 'Estado', value: checkout.status),
                      _CheckoutStatChip(label: 'Subtotal', value: '\$${checkout.subtotal.toStringAsFixed(2)}'),
                      _CheckoutStatChip(
                        label: 'Address ID',
                        value: checkout.addressId?.toString() ?? 'Sin asignar',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutStatChip extends StatelessWidget {
  const _CheckoutStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF17142A)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6E6B77)),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAddressSheet extends StatefulWidget {
  const _CreateAddressSheet({required this.addressService});

  final AddressService addressService;

  @override
  State<_CreateAddressSheet> createState() => _CreateAddressSheetState();
}

class _CreateAddressSheetState extends State<_CreateAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();

  bool _isDefault = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _labelController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final address = await widget.addressService.createAddress(
        label: _labelController.text,
        contactName: _contactController.text,
        phone: _phoneController.text,
        line1: _line1Controller.text,
        city: _cityController.text,
        isDefault: _isDefault,
      );
      if (!mounted) return;
      Navigator.of(context).pop(address);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar direccion',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              if (_errorMessage != null) ...[
                _CheckoutErrorCard(message: _errorMessage!),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Etiqueta'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Ingresa una etiqueta.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Nombre de contacto'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Ingresa el contacto.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefono'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Ingresa el telefono.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line1Controller,
                decoration: const InputDecoration(labelText: 'Direccion'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Ingresa la direccion.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Ingresa la ciudad.' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: _isSaving ? null : (value) => setState(() => _isDefault = value),
                title: const Text('Usar como direccion principal'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Guardar direccion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AddressOptionCard extends StatelessWidget {
  const _AddressOptionCard({required this.address, required this.isSelected, required this.onTap});

  final AddressModel address;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5EEFF) : const Color(0xFFF8F6F2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE5E1DA),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F6EE),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'Principal',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(address.subtitle, style: const TextStyle(color: Color(0xFF6E6B77), height: 1.35)),
                  if (address.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(address.phone, style: const TextStyle(color: Color(0xFF6E6B77))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFAAA6B2),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutInfoRow extends StatelessWidget {
  const _CheckoutInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6E6B77)))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CheckoutErrorCard extends StatelessWidget {
  const _CheckoutErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1B7AC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD94841)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
