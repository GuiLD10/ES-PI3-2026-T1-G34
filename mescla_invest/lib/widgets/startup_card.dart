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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome da startup
          Text(
            startup.nome,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Descrição
          Text(
            'Descrição: ${startup.descricao}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),

          // Estágio
          Text(
            'Estágio: ${startup.estagio}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          // Botão Ver Detalhes
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              child: const Text(
                'Ver Detalhes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}