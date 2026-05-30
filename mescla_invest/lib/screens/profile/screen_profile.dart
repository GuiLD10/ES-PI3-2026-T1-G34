// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Tela de Configuracoes do MesclaInvest (Refatorada)

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nomeController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();

  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    super.dispose();
  }

  void _salvar() {}

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
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTitulo(),
              const SizedBox(height: 24),
              _buildFormulario(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 32, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: AppColors.primary),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/logo.png',
            width: 100,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTitulo() {
    return Center(
      child: Text(
        'Configurações',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecaoDadosPessoais(),
          const SizedBox(height: 24),
          _buildSecaoAlterarSenha(),
          const SizedBox(height: 24),
          _buildBotaoSalvar(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSecaoDadosPessoais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dados Pessoais',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nome do Usuário',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildTextField(controller: _nomeController, hint: ''),
      ],
    );
  }

  Widget _buildSecaoAlterarSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alterar senha',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _senhaAtualController,
          hint: 'Digite a senha atual',
          obscure: _obscureSenhaAtual,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSenhaAtual ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textHint,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureSenhaAtual = !_obscureSenhaAtual),
          ),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _novaSenhaController,
          hint: 'Digite a nova senha',
          obscure: _obscureNovaSenha,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNovaSenha ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textHint,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureNovaSenha = !_obscureNovaSenha),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoSalvar() {
    return Row(
      children: [
        SizedBox(
          height: 44,
          width: 100,
          child: ElevatedButton(
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Salvar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _mostrarPopup2FA,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.security),
            label: const Text(
              '2FA',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
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

  void _mostrarPopup2FA() {
    final telefoneUsuario =
        AuthService.getTelefoneUsuario() ?? 'Telefone não encontrado';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.security),
              SizedBox(width: 8),
              Text('Autenticação 2FA'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('O código de autenticação será enviado para:'),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone),
                    const SizedBox(width: 10),
                    Text(
                      telefoneUsuario,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Ativar'),
            ),
          ],
        );
      },
    );
  }
}
