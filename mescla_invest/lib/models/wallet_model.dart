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
  final saldoDisponivel = (map['saldo_disponivel'] ?? 0).toDouble();
  final saldoBloqueado = (map['saldo_bloqueado'] ?? 0).toDouble();

  return WalletModel(
    uid: uid,
    saldoDisponivel: saldoDisponivel,
    saldoDisponivelCentavos: map['saldo_disponivel_centavos'] != null
        ? (map['saldo_disponivel_centavos']).toInt()
        : (saldoDisponivel * 100).toInt(),
    saldoBloqueado: saldoBloqueado,
    saldoBloqueadoCentavos: map['saldo_bloqueado_centavos'] != null
        ? (map['saldo_bloqueado_centavos']).toInt()
        : (saldoBloqueado * 100).toInt(),
  );
}

  // Patrimônio total = saldo disponível + saldo bloqueado
  double get patrimonioTotal => saldoDisponivel + saldoBloqueado;
}