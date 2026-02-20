import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api_config.dart';
import 'services/auth_api.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'views/onboarding_view.dart';
import 'views/register_view.dart';

void main() {
  runApp(const GrocerySaverApp());
}

class GrocerySaverApp extends StatefulWidget {
  const GrocerySaverApp({super.key});

  @override
  State<GrocerySaverApp> createState() => _GrocerySaverAppState();
}

class _GrocerySaverAppState extends State<GrocerySaverApp> {
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(api: AuthApi(ApiConfig.baseUrl));
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F7D57),
      primary: const Color(0xFF2F7D57),
      secondary: const Color(0xFFFFB84D),
      surface: const Color(0xFFFFFFFF),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Grocery Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.dmSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF4FBF6),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FCFA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBFD8C7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBFD8C7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2F7D57), width: 1.7),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFC53939)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.94),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFDFECE4)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F7D57),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF246549),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      initialRoute: '/onboarding',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingView());
          case '/register':
            return MaterialPageRoute(
              builder: (_) => RegisterView(viewModel: _authViewModel),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomeView(viewModel: _authViewModel),
            );
          case '/login':
          default:
            return MaterialPageRoute(
              builder: (_) => LoginView(viewModel: _authViewModel),
            );
        }
      },
    );
  }
}
