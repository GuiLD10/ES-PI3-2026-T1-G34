// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Tela de verificação OTP para autenticação 2FA

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

/// Define o motivo da verificação OTP.
enum OtpMotivo {
  /// Ativação do 2FA a partir da tela de perfil.
  ativacao,

  /// Verificação durante o login quando MFA está ativo.
  login,
}

class OtpVerificationScreen extends StatefulWidget {
  final String telefone;
  final OtpMotivo motivo;

  const OtpVerificationScreen({
    super.key,
    required this.telefone,
    required this.motivo,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isEnviando = true;
  String? _verificationId;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _enviarCodigo();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    setState(() {
      _isEnviando = true;
      _erro = null;
    });

    try {
      final vid = await AuthService.iniciarVerificacaoTelefone(widget.telefone);
      if (!mounted) return;
      setState(() {
        _verificationId = vid;
        _isEnviando = false;
      });
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _isEnviando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao enviar SMS. Tente novamente.';
        _isEnviando = false;
      });
    }
  }

  String get _codigoDigitado {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigoDigitado;
    if (codigo.length != 6) {
      setState(() => _erro = 'Digite o código completo de 6 dígitos.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _erro = 'Código de verificação não recebido. Reenvie.');
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      if (widget.motivo == OtpMotivo.ativacao) {
        // Ativar 2FA: vincular telefone + salvar flag
        await AuthService.confirmarCodigoOTP(
          verificationId: _verificationId!,
          smsCode: codigo,
        );
        await AuthService.toggleMfa(ativar: true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autenticação 2FA ativada com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Login MFA: verificar código
        await AuthService.verificarCodigoMfaLogin(
          verificationId: _verificationId!,
          smsCode: codigo,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/catalog');
      }
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao verificar código. Tente novamente.';
        _isLoading = false;
      });
    }
  }

  void _limparCampos() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildIcone(),
              const SizedBox(height: 24),
              _buildTitulo(),
              const SizedBox(height: 8),
              _buildSubtitulo(),
              const SizedBox(height: 32),
              if (_isEnviando) _buildCarregando(),
              if (!_isEnviando) _buildCamposOTP(),
              const SizedBox(height: 16),
              if (_erro != null) _buildErro(),
              const SizedBox(height: 24),
              if (!_isEnviando) _buildBotaoVerificar(),
              const SizedBox(height: 16),
              if (!_isEnviando) _buildReenviar(),
              const SizedBox(height: 16),
              _buildBotaoVoltar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcone() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.sms_outlined,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTitulo() {
    return Text(
      'Verificação de Código',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubtitulo() {
    return Text(
      'Digite o código de 6 dígitos enviado para\n${widget.telefone}',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textHint,
        fontSize: 14,
      ),
    );
  }

  Widget _buildCarregando() {
    return Column(
      children: [
        CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Enviando código SMS...',
          style: TextStyle(color: AppColors.textHint, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCamposOTP() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 46,
          height: 56,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              // Auto-verificar quando todos os 6 dígitos foram digitados
              if (_codigoDigitado.length == 6) {
                _verificarCodigo();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildErro() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _erro!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoVerificar() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verificarCodigo,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Verificar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildReenviar() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              _limparCampos();
              _enviarCodigo();
            },
      child: Text(
        'Reenviar código',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBotaoVoltar() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        'Voltar',
        style: TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),
    );
  }
}
