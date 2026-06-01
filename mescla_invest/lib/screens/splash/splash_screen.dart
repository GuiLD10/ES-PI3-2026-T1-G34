// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Tela de Splash do MesclaInvest

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _controller.forward();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    final restaurada = await AuthService.restaurarSessao();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, restaurada ? '/catalog' : '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 400,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
