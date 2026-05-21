// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Model de dados de transacao

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
      id: id.isNotEmpty ? id : _asString(map['id']),
      startupId: _asString(map['startup_id']),
      compradorUid: _asString(map['comprador_uid']),
      vendedorUid: _asString(map['vendedor_uid']),
      ofertaCompraId: _asString(map['oferta_compra_id']),
      ofertaVendaId: _asString(map['oferta_venda_id']),
      mercado: _asString(map['mercado']),
      quantidade: _asInt(map['quantidade']),
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
      criadoEm: _readDateTime(map['criado_em']),
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

DateTime _readDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();

  if (value is Map) {
    final seconds = value['_seconds'] ?? value['seconds'];
    if (seconds is int) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
  }

  return DateTime.now();
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(dynamic value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
