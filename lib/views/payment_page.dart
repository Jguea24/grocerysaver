import 'package:flutter/material.dart';
import 'package:grocerysaver/services/payment_service.dart';
import 'package:grocerysaver/views/payment_success_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.checkoutId, this.amount, this.paymentService});

  final int checkoutId;
  final double? amount;
  final PaymentService? paymentService;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final PaymentService _paymentService;

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedMethod = 'card';

  @override
  void initState() {
    super.initState();
    _paymentService = widget.paymentService ?? PaymentService();
  }

  Future<void> _payNow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _paymentService.createPayment(checkoutId: widget.checkoutId, method: _selectedMethod, provider: 'sandbox');
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PaymentSuccessPage(result: result)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSelect(String value) {
    setState(() => _selectedMethod = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F2),
      appBar: AppBar(title: const Text('Metodo de pago'), centerTitle: true),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -8))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AmountSummary(amount: widget.amount),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _payNow,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE90059), minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white)) : const Text('Pagar ahora'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 160),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Elige como quieres pagar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)), const SizedBox(height: 8), Text('Checkout #${widget.checkoutId}', style: const TextStyle(color: Color(0xFFEAE8FF), fontWeight: FontWeight.w600))]),
          ),
          const SizedBox(height: 18),
          if (_errorMessage != null) ...[_PaymentErrorCard(message: _errorMessage!), const SizedBox(height: 16)],
          const Text('Metodos disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17142A))),
          const SizedBox(height: 12),
          _PaymentMethodCard(title: 'Tarjeta', subtitle: 'Pago inmediato con tarjeta de debito o credito', icon: Icons.credit_card_rounded, value: 'card', groupValue: _selectedMethod, onChanged: _isLoading ? null : _onSelect),
          _PaymentMethodCard(title: 'Efectivo', subtitle: 'Paga al recibir tu pedido', icon: Icons.payments_rounded, value: 'cash', groupValue: _selectedMethod, onChanged: _isLoading ? null : _onSelect),
          _PaymentMethodCard(title: 'Transferencia', subtitle: 'Transferencia bancaria o deposito', icon: Icons.account_balance_rounded, value: 'transfer', groupValue: _selectedMethod, onChanged: _isLoading ? null : _onSelect),
        ],
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  const _AmountSummary({required this.amount});

  final double? amount;

  @override
  Widget build(BuildContext context) {
    return Row(children: [const Expanded(child: Text('Total a pagar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF17142A)))), Text(amount == null ? 'Checkout listo' : '\$${amount!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF17142A)))]);
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.title, required this.subtitle, required this.icon, required this.value, required this.groupValue, required this.onChanged});

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE5E1DA), width: isSelected ? 2 : 1), boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, 6))]),
        child: Row(
          children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: isSelected ? const Color(0xFFF0EAFF) : const Color(0xFFF6F4EF), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF49455A))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF6E6B77), height: 1.35))])),
            const SizedBox(width: 10),
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFAAA6B2)),
          ],
        ),
      ),
    );
  }
}

class _PaymentErrorCard extends StatelessWidget {
  const _PaymentErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFEEEA), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1B7AC))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline_rounded, color: Color(0xFFD94841)), const SizedBox(width: 12), Expanded(child: Text(message))]),
    );
  }
}
