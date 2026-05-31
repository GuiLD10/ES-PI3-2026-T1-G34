// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descricao: Widget reutilizavel que exibe o saldo disponivel do usuario

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/auth_service.dart';
import '../core/services/wallet_service.dart';

/// Widget que busca e exibe o saldo disponível do usuário no canto superior direito.
/// Lê o campo 'saldo_disponivel_centavos' da tabela 'usuarios' via WalletService.
class SaldoDisplay extends StatefulWidget {
  const SaldoDisplay({super.key});

  @override
  State<SaldoDisplay> createState() => _SaldoDisplayState();
}

class _SaldoDisplayState extends State<SaldoDisplay> {
  int? _saldoCentavos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarSaldo();
  }

  Future<void> _carregarSaldo() async {
    try {
      final uid = AuthService.currentUid;
      if (uid == null || uid.isEmpty) return;

      final wallet = await WalletService.buscarCarteira(uid);
      if (!mounted) return;
      setState(() {
        _saldoCentavos = wallet.saldoDisponivelCentavos;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saldoCentavos = null;
        _isLoading = false;
      });
    }
  }

  String _formatarSaldo(int centavos) {
    final reais = centavos ~/ 100;
    final centavosParte = centavos % 100;
    final reaisStr = _formatarNumeroComPonto(reais);
    final centavosStr = centavosParte.toString().padLeft(2, '0');
    return 'R\$ $reaisStr,$centavosStr';
  }

  String _formatarNumeroComPonto(int valor) {
    final texto = valor.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < texto.length; i++) {
      final posicaoRestante = texto.length - i;
      buffer.write(texto[i]);

      if (posicaoRestante > 1 && posicaoRestante % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    if (_saldoCentavos == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatarSaldo(_saldoCentavos!),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
