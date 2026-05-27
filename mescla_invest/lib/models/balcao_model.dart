// Autor: Rafael Lanza de Queiroz
// RA: 22010825

class OfertaBalcaoModel {
  final String id;
  final String tipo;
  final String usuarioUid;
  final String startupId;
  final int quantidadeOriginal;
  final int quantidadeRestante;
  final int valorUnitarioCentavos;
  final String status;
  final String? criadoEm;
  final String? atualizadoEm;

  const OfertaBalcaoModel({
    required this.id,
    required this.tipo,
    required this.usuarioUid,
    required this.startupId,
    required this.quantidadeOriginal,
    required this.quantidadeRestante,
    required this.valorUnitarioCentavos,
    required this.status,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory OfertaBalcaoModel.fromJson(Map<String, dynamic> json) {
    return OfertaBalcaoModel(
      id: _asString(json['oferta_id']),
      tipo: _asString(json['tipo']),
      usuarioUid: _asString(json['usuario_uid']),
      startupId: _asString(json['startup_id']),
      quantidadeOriginal: _asInt(json['quantidade_original']),
      quantidadeRestante: _asInt(json['quantidade_restante']),
      valorUnitarioCentavos: _asInt(json['valor_unitario_centavos']),
      status: _asString(json['status']),
      criadoEm: _asNullableString(json['criado_em']),
      atualizadoEm: _asNullableString(json['atualizado_em']),
    );
  }
}

class OrderBookBalcaoModel {
  final String startupId;
  final int precoAtualCentavos;
  final OfertaBalcaoModel? melhorCompra;
  final OfertaBalcaoModel? melhorVenda;
  final List<OfertaBalcaoModel> compras;
  final List<OfertaBalcaoModel> vendas;

  const OrderBookBalcaoModel({
    required this.startupId,
    required this.precoAtualCentavos,
    required this.melhorCompra,
    required this.melhorVenda,
    required this.compras,
    required this.vendas,
  });

  factory OrderBookBalcaoModel.fromJson(Map<String, dynamic> json) {
    final melhorCompraJson = json['melhor_compra'];
    final melhorVendaJson = json['melhor_venda'];

    return OrderBookBalcaoModel(
      startupId: _asString(json['startup_id']),
      precoAtualCentavos: _asInt(json['preco_atual_centavos']),
      melhorCompra: melhorCompraJson is Map
          ? OfertaBalcaoModel.fromJson(
              Map<String, dynamic>.from(melhorCompraJson),
            )
          : null,
      melhorVenda: melhorVendaJson is Map
          ? OfertaBalcaoModel.fromJson(
              Map<String, dynamic>.from(melhorVendaJson),
            )
          : null,
      compras: _asMapList(
        json['compras'],
      ).map(OfertaBalcaoModel.fromJson).toList(),
      vendas: _asMapList(
        json['vendas'],
      ).map(OfertaBalcaoModel.fromJson).toList(),
    );
  }
}

class TransacaoBalcaoModel {
  final String id;
  final String mercado;
  final String compradorUid;
  final String vendedorUid;
  final String startupId;
  final int quantidade;
  final int valorUnitarioCentavos;
  final int valorTotalCentavos;
  final String? criadoEm;

  const TransacaoBalcaoModel({
    required this.id,
    required this.mercado,
    required this.compradorUid,
    required this.vendedorUid,
    required this.startupId,
    required this.quantidade,
    required this.valorUnitarioCentavos,
    required this.valorTotalCentavos,
    this.criadoEm,
  });

  factory TransacaoBalcaoModel.fromJson(Map<String, dynamic> json) {
    return TransacaoBalcaoModel(
      id: _asString(json['transacao_id']),
      mercado: _asString(json['mercado']),
      compradorUid: _asString(json['comprador_uid']),
      vendedorUid: _asString(json['vendedor_uid']),
      startupId: _asString(json['startup_id']),
      quantidade: _asInt(json['quantidade']),
      valorUnitarioCentavos: _asInt(json['valor_unitario_centavos']),
      valorTotalCentavos: _asInt(json['valor_total_centavos']),
      criadoEm: _asNullableString(json['criado_em']),
    );
  }
}

class ResultadoOfertaBalcaoModel {
  final String id;
  final String tipo;
  final String startupId;
  final int quantidadeOriginal;
  final int quantidadeRestante;
  final int valorUnitarioCentavos;
  final String status;
  final int quantidadeExecutada;
  final int transacoesExecutadas;

  const ResultadoOfertaBalcaoModel({
    required this.id,
    required this.tipo,
    required this.startupId,
    required this.quantidadeOriginal,
    required this.quantidadeRestante,
    required this.valorUnitarioCentavos,
    required this.status,
    required this.quantidadeExecutada,
    required this.transacoesExecutadas,
  });

  factory ResultadoOfertaBalcaoModel.fromJson(Map<String, dynamic> json) {
    return ResultadoOfertaBalcaoModel(
      id: _asString(json['oferta_id']),
      tipo: _asString(json['tipo']),
      startupId: _asString(json['startup_id']),
      quantidadeOriginal: _asInt(json['quantidade_original']),
      quantidadeRestante: _asInt(json['quantidade_restante']),
      valorUnitarioCentavos: _asInt(json['valor_unitario_centavos']),
      status: _asString(json['status']),
      quantidadeExecutada: _asInt(json['quantidade_executada']),
      transacoesExecutadas: _asInt(json['transacoes_executadas']),
    );
  }
}

class ResultadoOperacaoMercadoModel {
  final String startupId;
  final int quantidade;
  final int valorUnitarioCentavos;
  final int valorTotalCentavos;
  final int precoAnteriorCentavos;
  final int precoAtualCentavos;
  final String transacaoId;

  const ResultadoOperacaoMercadoModel({
    required this.startupId,
    required this.quantidade,
    required this.valorUnitarioCentavos,
    required this.valorTotalCentavos,
    required this.precoAnteriorCentavos,
    required this.precoAtualCentavos,
    required this.transacaoId,
  });

  factory ResultadoOperacaoMercadoModel.fromJson(Map<String, dynamic> json) {
    return ResultadoOperacaoMercadoModel(
      startupId: _asString(json['startup_id']),
      quantidade: _asInt(json['quantidade']),
      valorUnitarioCentavos: _asInt(json['valor_unitario_centavos']),
      valorTotalCentavos: _asInt(json['valor_total_centavos']),
      precoAnteriorCentavos: _asInt(json['preco_anterior_centavos']),
      precoAtualCentavos: _asInt(json['preco_atual_centavos']),
      transacaoId: _asString(json['transacao_id']),
    );
  }
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
