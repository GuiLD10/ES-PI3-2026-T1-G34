// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Model de dados da Startup

class StartupModel {
  final String id;
  final String nome;
  final String descricao;
  final String estagio;

  StartupModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.estagio,
  });

  // TODO: integrar com Firebase — converter documento Firestore para StartupModel
  factory StartupModel.fromMap(String id, Map<String, dynamic> map) {
    return StartupModel(
      id: id,
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      estagio: map['estagio'] ?? '',
    );
  }
}