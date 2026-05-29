// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Model de dados do ativo do usuario e historico de precos

class PricePoint {
  final int precoCentavos;
  final int precoPrecisoCentavos;
  final DateTime data;

  PricePoint({
    required this.precoCentavos,
    required this.precoPrecisoCentavos,
    required this.data,
  });

  double get precoReais => precoCentavos / 100;

  factory PricePoint.fromMap(Map<String, dynamic> map) {
    final precoCentavos = _asInt(map['preco_centavos']);
    final precoPrecisoCentavos = _asInt(map['preco_preciso_centavos']);

    return PricePoint(
      precoCentavos: precoCentavos,
      precoPrecisoCentavos: precoPrecisoCentavos > 0
          ? precoPrecisoCentavos
          : precoCentavos * pricePrecisionScale,
      data: _readDateTime(map['data']),
    );
  }
}

class AtivoModel {
  final String startupId;
  final String startupNome;
  final int quantidadeDisponivel;
  final int quantidadeBloqueada;
  final int valorMedioCentavos;
  final int valorMedioPrecisoCentavos;
  final int precoAtualCentavos;
  final int precoPrimarioCentavos;
  final int precoAtualPrecisoCentavos;
  final int precoPrimarioPrecisoCentavos;
  final List<PricePoint> historicoPrecos;

  AtivoModel({
    required this.startupId,
    required this.startupNome,
    required this.quantidadeDisponivel,
    required this.quantidadeBloqueada,
    required this.valorMedioCentavos,
    required this.valorMedioPrecisoCentavos,
    required this.precoAtualCentavos,
    required this.precoPrimarioCentavos,
    required this.precoAtualPrecisoCentavos,
    required this.precoPrimarioPrecisoCentavos,
    required this.historicoPrecos,
  });

  double get precoAtualReais => precoAtualCentavos / 100;
  double get precoPrimarioReais => precoPrimarioCentavos / 100;
  double get valorMedioReais => valorMedioCentavos / 100;
  int get quantidadeTotal => quantidadeDisponivel + quantidadeBloqueada;

  factory AtivoModel.fromMap(Map<String, dynamic> map) {
    final historico = (map['historico_precos'] as List?) ?? [];
    final precoAtualCentavos = _asInt(map['preco_atual_centavos']);
    final precoPrimarioCentavos = _asInt(map['preco_primario_centavos']);
    final valorMedioCentavos = _asInt(map['valor_medio_centavos']);
    final valorMedioPrecisoCentavos = _asInt(
      map['valor_medio_preciso_centavos'],
    );
    final precoAtualPrecisoCentavos = _asInt(
      map['preco_atual_preciso_centavos'],
    );
    final precoPrimarioPrecisoCentavos = _asInt(
      map['preco_primario_preciso_centavos'],
    );

    return AtivoModel(
      startupId: _asString(map['startup_id']),
      startupNome: _asString(map['startup_nome']),
      quantidadeDisponivel: _asInt(map['quantidade_disponivel']),
      quantidadeBloqueada: _asInt(map['quantidade_bloqueada']),
      valorMedioCentavos: valorMedioCentavos,
      valorMedioPrecisoCentavos: valorMedioPrecisoCentavos > 0
          ? valorMedioPrecisoCentavos
          : valorMedioCentavos * pricePrecisionScale,
      precoAtualCentavos: precoAtualCentavos,
      precoPrimarioCentavos: precoPrimarioCentavos,
      precoAtualPrecisoCentavos: precoAtualPrecisoCentavos > 0
          ? precoAtualPrecisoCentavos
          : precoAtualCentavos * pricePrecisionScale,
      precoPrimarioPrecisoCentavos: precoPrimarioPrecisoCentavos > 0
          ? precoPrimarioPrecisoCentavos
          : precoPrimarioCentavos * pricePrecisionScale,
      historicoPrecos: historico
          .whereType<Map>()
          .map((item) => PricePoint.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

const int pricePrecisionScale = 10000;

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

DateTime _readDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
