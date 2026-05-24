// Autor: Artur Pagno
// RA: 21013037
// Descrição: Configuração central do aplicativo - tema e rotas

import 'package:flutter/material.dart';
import 'core/constants/app_routes.dart';

// Telas
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/catalog/startup_detail_screen.dart';
import 'screens/balcao/balcao_screen.dart';
import 'screens/settings/settings_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MesclaInvest',
      debugShowCheckedModeBanner: false,
      // theme: null removido por enquanto
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash:             (_) => const SplashScreen(),
        AppRoutes.login:              (_) => const LoginScreen(),
        AppRoutes.register:           (_) => const RegisterScreen(),
        AppRoutes.forgotPassword:     (_) => const ForgotPasswordScreen(),
        AppRoutes.catalog:            (_) => const CatalogScreen(),
        AppRoutes.startupDetail:      (_) => const StartupDetailScreen(),
        AppRoutes.balcao:             (_) => const BalcaoScreen(),
        AppRoutes.settings:           (_) => const SettingsScreen(),
      },
    );
  }
}
