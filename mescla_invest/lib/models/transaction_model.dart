// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Model de dados de transacao

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String startupId;
  final String compradorUid;
  final String vendedorUid;
  final String ofertaCompraId;
  final String ofertaVendaId;
  final String mercado;
  final int quantidade;
  final double valorUnitario;
  final double valorTotal;
  final DateTime criadoEm;

  TransactionModel({
    required this.id,
    required this.startupId,
    required this.compradorUid,
    required this.vendedorUid,
    required this.ofertaCompraId,
    required this.ofertaVendaId,
    required this.mercado,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.criadoEm,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      startupId: map['startup_id'] ?? '',
      compradorUid: map['comprador_uid'] ?? '',
      vendedorUid: map['vendedor_uid'] ?? '',
      ofertaCompraId: map['oferta_compra_id'] ?? '',
      ofertaVendaId: map['oferta_venda_id'] ?? '',
      mercado: map['mercado'] ?? '',
      quantidade: (map['quantidade'] ?? 0).toInt(),
      valorUnitario: _readMoney(
        map,
        centavosField: 'valor_unitario_centavos',
        legacyField: 'valor_unitario',
      ),
      valorTotal: _readMoney(
        map,
        centavosField: 'valor_total_centavos',
        legacyField: 'valor_total',
      ),
      criadoEm: map['criado_em'] is Timestamp
          ? (map['criado_em'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

double _readMoney(
  Map<String, dynamic> map, {
  required String centavosField,
  required String legacyField,
}) {
  if (map.containsKey(centavosField)) {
    return _asDouble(map[centavosField]) / 100;
  }

  return _asDouble(map[legacyField]);
}

double _asDouble(dynamic value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
