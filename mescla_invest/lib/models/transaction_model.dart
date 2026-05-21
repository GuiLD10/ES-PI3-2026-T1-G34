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
    DateTime parsedDate = DateTime.now();
    final raw = map['criado_em'];

    print('🔍 [TransactionModel] criado_em: $raw (tipo: ${raw.runtimeType})');

    if (raw is String) {
      parsedDate = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is Map) {
      try {
        final seconds = raw['_seconds'] as int?;
        if (seconds != null) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        print('❌ [TransactionModel] Erro ao parse criado_em: $e');
      }
    }

    return TransactionModel(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      startupId: map['startup_id'] ?? '',
      compradorUid: map['comprador_uid'] ?? '',
      vendedorUid: map['vendedor_uid'] ?? '',
      ofertaCompraId: map['oferta_compra_id'] ?? '',
      ofertaVendaId: map['oferta_venda_id'] ?? '',
      mercado: map['mercado'] ?? '',
      quantidade: (map['quantidade'] ?? 0).toInt(),
      valorUnitario: (map['valor_unitario'] ?? 0).toDouble(),
      valorTotal: (map['valor_total'] ?? 0).toDouble(),
      criadoEm: parsedDate,
    );
  }
}