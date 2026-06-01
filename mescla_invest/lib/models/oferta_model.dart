// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Model de dados de oferta do balcao

import 'package:cloud_firestore/cloud_firestore.dart';

class OfertaModel {
  final String id;
  final String usuarioUid;
  final String startupId;
  final String tipo;
  final String status;
  final int quantidadeOriginal;
  final int quantidadeRestante;
  final int valorUnitarioCentavos;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  OfertaModel({
    required this.id,
    required this.usuarioUid,
    required this.startupId,
    required this.tipo,
    required this.status,
    required this.quantidadeOriginal,
    required this.quantidadeRestante,
    required this.valorUnitarioCentavos,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  // Valor unitário em reais
  double get valorUnitario => valorUnitarioCentavos / 100.0;

  factory OfertaModel.fromMap(String id, Map<String, dynamic> map) {
    return OfertaModel(
      id: id,
      usuarioUid: map['usuario_uid'] ?? '',
      startupId: map['startup_id'] ?? '',
      tipo: map['tipo'] ?? '',
      status: map['status'] ?? '',
      quantidadeOriginal: (map['quantidade_original'] ?? 0).toInt(),
      quantidadeRestante: (map['quantidade_restante'] ?? 0).toInt(),
      valorUnitarioCentavos: (map['valor_unitario_centavos'] ?? 0).toInt(),
      criadoEm: map['criado_em'] is Timestamp
          ? (map['criado_em'] as Timestamp).toDate()
          : DateTime.now(),
      atualizadoEm: map['atualizado_em'] is Timestamp
          ? (map['atualizado_em'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}