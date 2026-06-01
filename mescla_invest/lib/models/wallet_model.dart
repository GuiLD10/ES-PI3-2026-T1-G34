// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Model de dados da carteira do usuario

class WalletModel {
  final String uid;
  final double saldoDisponivel;
  final int saldoDisponivelCentavos;
  final double saldoBloqueado;
  final int saldoBloqueadoCentavos;

  WalletModel({
    required this.uid,
    required this.saldoDisponivel,
    required this.saldoDisponivelCentavos,
    required this.saldoBloqueado,
    required this.saldoBloqueadoCentavos,
  });

  factory WalletModel.fromMap(String uid, Map<String, dynamic> map) {
    final saldoDisponivelCentavos = _readCentavos(
      map,
      centavosField: 'saldo_disponivel_centavos',
      legacyField: 'saldo_disponivel',
    );
    final saldoBloqueadoCentavos = _readCentavos(
      map,
      centavosField: 'saldo_bloqueado_centavos',
      legacyField: 'saldo_bloqueado',
    );

    return WalletModel(
      uid: uid,
      saldoDisponivel: saldoDisponivelCentavos / 100,
      saldoDisponivelCentavos: saldoDisponivelCentavos,
      saldoBloqueado: saldoBloqueadoCentavos / 100,
      saldoBloqueadoCentavos: saldoBloqueadoCentavos,
    );
  }

  double get patrimonioTotal => saldoDisponivel + saldoBloqueado;
}

int _readCentavos(
  Map<String, dynamic> map, {
  required String centavosField,
  required String legacyField,
}) {
  if (map.containsKey(centavosField)) {
    return _asInt(map[centavosField]);
  }

  return (_asDouble(map[legacyField]) * 100).round();
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
