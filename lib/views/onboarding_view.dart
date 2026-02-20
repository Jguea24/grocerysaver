import 'package:flutter/material.dart';

import '../components/app_backdrop.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: 'Bienvenido a GrocerySaver',
      description:
          'Compara precios entre supermercados y tiendas locales para ahorrar en cada compra.',
      icon: Icons.waving_hand_rounded,
    ),
    _OnboardingStep(
      title: 'Beneficios para tu bolsillo',
      description:
          'Encuentra ofertas, arma tu lista y conoce en que tienda pagarias menos por tus productos.',
      icon: Icons.savings_outlined,
    ),
    _OnboardingStep(
      title: 'Permisos recomendados',
      description:
          'Activa ubicacion para ver promociones cercanas y notificaciones para enterarte de descuentos.',
      icon: Icons.shield_moon_outlined,
    ),
    _OnboardingStep(
      title: 'Acceso rapido',
      description:
          'Crea tu cuenta o inicia sesion para personalizar alertas, historial y comparaciones.',
      icon: Icons.login_rounded,
    ),
  ];

  bool get _isLastPage => _currentPage == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isLastPage) {
      _goToLogin();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        maxWidth: 520,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Introduccion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E5338),
                      ),
                    ),
                    TextButton(
                      onPressed: _goToLogin,
                      child: const Text('Saltar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 360,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _steps.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return _OnboardingPage(step: step);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF2F7D57)
                            : const Color(0xFFAED0BB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _next,
                  child: Text(_isLastPage ? 'Ir al acceso' : 'Siguiente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6EE),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(step.icon, size: 52, color: const Color(0xFF2F7D57)),
        ),
        const SizedBox(height: 24),
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E5338),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          step.description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF557865)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
