// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Tela de Configuracoes do MesclaInvest (Refatorada)

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../auth/otp_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
              _buildBotao2FA(),
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

  Widget _buildBotao2FA() {
    return Center(
      child: SizedBox(
        height: 44,
        child: OutlinedButton.icon(
          onPressed: _mostrarPopup2FA,
          style: OutlinedButton.styleFrom(
            foregroundColor: AuthService.isMfaAtivo
                ? Colors.red
                : AppColors.primary,
            side: BorderSide(
              color: AuthService.isMfaAtivo
                  ? Colors.red
                  : AppColors.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: Icon(
            AuthService.isMfaAtivo
                ? Icons.security
                : Icons.security_outlined,
          ),
          label: Text(
            AuthService.isMfaAtivo ? 'Desativar 2FA' : '2FA',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarPopup2FA() async {
    final mfaAtivo = AuthService.isMfaAtivo;

    if (mfaAtivo) {
      // 2FA já está ativo - oferecer desativação
      _mostrarPopupDesativar2FA();
      return;
    }

    // 2FA não está ativo - oferecer ativação
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
              Text('Ativar 2FA'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Um código de verificação será enviado por SMS para:',
              ),
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
              const SizedBox(height: 12),
              Text(
                'Você precisará digitar o código para concluir a ativação.',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _iniciarAtivacao2FA(telefoneUsuario);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar Código'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarPopupDesativar2FA() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Desativar 2FA'),
            ],
          ),
          content: const Text(
            'Tem certeza que deseja desativar a autenticação de dois fatores? '
            'Sua conta ficará menos protegida.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _desativar2FA();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Desativar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _iniciarAtivacao2FA(String telefone) async {
    // Formatar telefone para formato internacional se necessário
    String telefoneFormatado = telefone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!telefoneFormatado.startsWith('+')) {
      telefoneFormatado = '+55$telefoneFormatado';
    }

    final resultado = await Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: {
        'telefone': telefoneFormatado,
        'motivo': OtpMotivo.ativacao,
      },
    );

    if (resultado == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _desativar2FA() async {
    final response = await AuthService.toggleMfa(ativar: false);

    if (!mounted) return;

    if (response['success'] == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autenticação 2FA desativada.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Erro ao desativar 2FA.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
