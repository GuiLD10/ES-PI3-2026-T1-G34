// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Tela de Recuperação de Senha do MesclaInvest

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  // final _cpfController = TextEditingController(); // CPF desativado temporariamente

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    // _cpfController.dispose(); // CPF desativado temporariamente
    super.dispose();
  }

  Future<void> _recuperar() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final resultado = await AuthService.recuperarSenha(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Instruções enviadas para o e-mail cadastrado.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Erro ao enviar e-mail. Tente novamente.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Logo no canto superior esquerdo
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Image.asset(
                  'assets/images/logoSmall.png',
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 48),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Center(
                      child: Text(
                        'Recuperar Senha',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Campo E-mail
                    _buildTextField(
                      controller: _emailController,
                      hint: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // Campo CPF desativado temporariamente
                    // const SizedBox(height: 10),
                    // _buildTextField(
                    //   controller: _cpfController,
                    //   hint: 'CPF',
                    //   keyboardType: TextInputType.number,
                    //   inputFormatters: [
                    //     FilteringTextInputFormatter.digitsOnly,
                    //     LengthLimitingTextInputFormatter(11),
                    //     _CpfInputFormatter(),
                    //   ],
                    // ),

                    const SizedBox(height: 32),

                    // Botão Recuperar centralizado
                    Center(
                      child: SizedBox(
                        width: 160,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _recuperar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Recuperar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Voltar para login
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Voltar para o login',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// Formatador de CPF: 000.000.000-00 — desativado temporariamente
// class _CpfInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue, TextEditingValue newValue) {
//     final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
//     final buffer = StringBuffer();
//     for (int i = 0; i < digits.length && i < 11; i++) {
//       if (i == 3 || i == 6) buffer.write('.');
//       if (i == 9) buffer.write('-');
//       buffer.write(digits[i]);
//     }
//     final text = buffer.toString();
//     return newValue.copyWith(
//       text: text,
//       selection: TextSelection.collapsed(offset: text.length),
//     );
//   }
// }