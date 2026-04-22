// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Card reutilizável de exibição de startup no catálogo

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/startup_model.dart';

class StartupCard extends StatelessWidget {
  final StartupModel startup;
  final VoidCallback onVerDetalhes;

  const StartupCard({
    super.key,
    required this.startup,
    required this.onVerDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  startup.nome,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildEstagio(),
            ],
          ),
          if (startup.setor.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              startup.setor,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            startup.descricao,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIndicador(
                  label: 'Capital',
                  value: _formatarMoeda(startup.capitalAportado),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildIndicador(
                  label: 'Tokens',
                  value: _formatarNumero(startup.tokensEmitidos),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onVerDetalhes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Ver detalhes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstagio() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        startup.estagio,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIndicador({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatarMoeda(int valor) {
    return 'R\$ ${_formatarNumero(valor)}';
  }

  String _formatarNumero(int valor) {
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
}
