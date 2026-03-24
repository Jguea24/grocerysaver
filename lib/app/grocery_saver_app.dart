import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grocerysaver/app/app_routes.dart';
import 'package:grocerysaver/app/app_theme.dart';
import 'package:grocerysaver/core/google_auth_service.dart';
import 'package:grocerysaver/data/core/api_client.dart';
import 'package:grocerysaver/data/repositories/app_repository_impl.dart';
import 'package:grocerysaver/domain/repositories/app_repositories.dart';
import 'package:grocerysaver/presentation/providers/app_providers.dart';
import 'package:grocerysaver/presentation/screens/auth/login_screen.dart';
import 'package:grocerysaver/presentation/screens/auth/register_screen.dart';
import 'package:grocerysaver/presentation/screens/auth/splash_screen.dart';
import 'package:grocerysaver/presentation/screens/home/app_shell_screen.dart';
import 'package:grocerysaver/views/cart_page.dart';

class GrocerySaverApp extends StatelessWidget {
  const GrocerySaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        Provider<GoogleAuthService>(create: (_) => GoogleAuthService()),
        Provider<AuthRepository>(create: (context) => AuthRepositoryImpl(context.read<ApiClient>(), context.read<GoogleAuthService>())),
        Provider<HouseholdRepository>(create: (context) => HouseholdRepositoryImpl(context.read<ApiClient>())),
        ChangeNotifierProvider(create: (context) => AuthProvider(context.read<AuthRepository>())),
        ChangeNotifierProvider(create: (context) => DashboardProvider(context.read<HouseholdRepository>())),
        ChangeNotifierProvider(create: (context) => InventoryProvider(context.read<HouseholdRepository>())),
        ChangeNotifierProvider(create: (context) => ShoppingListProvider(context.read<HouseholdRepository>())),
        ChangeNotifierProvider(create: (context) => ProductDetailProvider(context.read<HouseholdRepository>())),
        ChangeNotifierProvider(create: (context) => ScannerProvider(context.read<HouseholdRepository>())),
      ],
      child: MaterialApp(
        title: 'Grocery Saver',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.login:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case AppRoutes.register:
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case AppRoutes.shell:
              return MaterialPageRoute(builder: (_) => const AppShellScreen());
            case AppRoutes.productDetail:
              final args = settings.arguments as ProductRouteArgs;
              return MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: args.productId));
            case AppRoutes.priceCompare:
              final args = settings.arguments as PriceCompareRouteArgs;
              return MaterialPageRoute(builder: (_) => PriceCompareScreen(productId: args.productId, productName: args.productName));
            case AppRoutes.productsCatalog:
              return MaterialPageRoute(builder: (_) => const ProductsCatalogScreen());
            case AppRoutes.cart:
              return MaterialPageRoute(builder: (_) => const CartPage());
            case AppRoutes.splash:
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    );
  }
}
