// Autor: Artur Henrique Pagno
// RA: 21013037
// Alterações feitas por Guilherme Lange Dallora - RA: 23012353
// Descrição: Tela de Cadastro do MesclaInvest

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _aceitouTermos = true;
  bool _obscureSenha = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final resultado = await AuthService.cadastrar(
      nome: _nomeController.text,
      email: _emailController.text,
      cpf: _cpfController.text,
      telefone: _telefoneController.text,
      senha: _senhaController.text,
      confirmarSenha: _confirmarSenhaController.text,
    );

    if (!mounted) return;

    if (resultado['success'] == true) {
      final login = await AuthService.login(
        email: _emailController.text,
        senha: _senhaController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (login['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              login['message'] ?? 'Cadastro realizado. Faca login para entrar.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['message'] ?? 'Cadastro realizado com sucesso!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, '/catalog');
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Erro ao realizar cadastro.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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
                    Center(
                      child: Text(
                        'Cadastro',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _nomeController,
                      hint: 'Nome completo',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _emailController,
                      hint: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),

                    // Campo CPF
                    _buildTextField(
                      controller: _cpfController,
                      hint: 'CPF',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                        _CpfInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _telefoneController,
                      hint: 'Telefone Celular',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                        _TelefoneInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _senhaController,
                      hint: 'Senha',
                      obscure: _obscureSenha,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureSenha = !_obscureSenha),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: _confirmarSenhaController,
                      hint: 'Confirme a senha',
                      obscure: _obscureConfirmar,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmar
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmar = !_obscureConfirmar,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Checkbox(
                          value: _aceitouTermos,
                          onChanged: (v) =>
                              setState(() => _aceitouTermos = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          'Li e concordo com os termos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 160,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: (_aceitouTermos && !_isLoading)
                              ? _cadastrar
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary
                                .withOpacity(0.5),
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
                                  'Cadastrar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
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
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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

// Formatador de CPF: 000.000.000-00
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Formatador de telefone: (00) 00000-0000
class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
