// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Model de dados do ativo do usuario e historico de precos

class PricePoint {
  final int precoCentavos;
  final DateTime data;

  PricePoint({required this.precoCentavos, required this.data});

  double get precoReais => precoCentavos / 100;

  factory PricePoint.fromMap(Map<String, dynamic> map) {
    return PricePoint(
      precoCentavos: _asInt(map['preco_centavos']),
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
  final int precoAtualCentavos;
  final int precoPrimarioCentavos;
  final List<PricePoint> historicoPrecos;

  AtivoModel({
    required this.startupId,
    required this.startupNome,
    required this.quantidadeDisponivel,
    required this.quantidadeBloqueada,
    required this.valorMedioCentavos,
    required this.precoAtualCentavos,
    required this.precoPrimarioCentavos,
    required this.historicoPrecos,
  });

  double get precoAtualReais => precoAtualCentavos / 100;
  double get precoPrimarioReais => precoPrimarioCentavos / 100;
  double get valorMedioReais => valorMedioCentavos / 100;
  int get quantidadeTotal => quantidadeDisponivel + quantidadeBloqueada;

  factory AtivoModel.fromMap(Map<String, dynamic> map) {
    final historico = (map['historico_precos'] as List?) ?? [];
    return AtivoModel(
      startupId: _asString(map['startup_id']),
      startupNome: _asString(map['startup_nome']),
      quantidadeDisponivel: _asInt(map['quantidade_disponivel']),
      quantidadeBloqueada: _asInt(map['quantidade_bloqueada']),
      valorMedioCentavos: _asInt(map['valor_medio_centavos']),
      precoAtualCentavos: _asInt(map['preco_atual_centavos']),
      precoPrimarioCentavos: _asInt(map['preco_primario_centavos']),
      historicoPrecos: historico
          .whereType<Map>()
          .map((item) => PricePoint.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
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

DateTime _readDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
