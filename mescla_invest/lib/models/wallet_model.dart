// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Model de dados da carteira do usuario

class WalletModel {
  final String uid;
  final double saldoDisponivel;
  final double saldoBloqueado;

  WalletModel({
    required this.uid,
    required this.saldoDisponivel,
    required this.saldoBloqueado,
  });

 factory WalletModel.fromMap(String uid, Map<String, dynamic> map) {
  final saldoDisponivel = (map['saldo_disponivel'] ?? 0).toDouble();
  final saldoBloqueado = (map['saldo_bloqueado'] ?? 0).toDouble();

  return WalletModel(
    uid: uid,
    saldoDisponivel: saldoDisponivel,
    saldoBloqueado: saldoBloqueado,
  );
}

  // Patrimônio total = saldo disponível + saldo bloqueado
  double get patrimonioTotal => saldoDisponivel + saldoBloqueado;
}