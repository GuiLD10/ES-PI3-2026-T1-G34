// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Model de dados da Startup

class StartupModel {
  final String id;
  final String nome;
  final String descricao;
  final String setor;
  final String estagio;
  final String status;
  final int capitalAportado;
  final int tokensEmitidos;
  final int precoAtualCentavos;
  final int precoPrimarioCentavos;
  final int precoAtualPrecisoCentavos;
  final int precoPrimarioPrecisoCentavos;
  final String videoDemo;
  final String sumarioExecutivo;
  final String planoDeNegocios;
  final List<SocioModel> socios;
  final List<MentorConselhoModel> mentoresConselho;
  final List<PerguntaRespostaModel> perguntasRespostas;
  final String? criadoEm;
  final String? atualizadoEm;

  StartupModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.setor,
    required this.estagio,
    required this.status,
    required this.capitalAportado,
    required this.tokensEmitidos,
    required this.precoAtualCentavos,
    required this.precoPrimarioCentavos,
    required this.precoAtualPrecisoCentavos,
    required this.precoPrimarioPrecisoCentavos,
    required this.videoDemo,
    required this.sumarioExecutivo,
    required this.planoDeNegocios,
    required this.socios,
    required this.mentoresConselho,
    required this.perguntasRespostas,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory StartupModel.fromJson(Map<String, dynamic> json) {
    return StartupModel(
      id: _asString(json['id']),
      nome: _asString(json['nome']),
      descricao: _asString(json['descricao']),
      setor: _asString(json['setor']),
      estagio: _asString(json['estagio']),
      status: _asString(json['status']),
      capitalAportado: _asInt(json['capital_aportado']),
      tokensEmitidos: _asInt(json['tokens_emitidos']),
      precoAtualCentavos: _asInt(json['preco_atual_centavos']),
      precoPrimarioCentavos: _asInt(json['preco_primario_centavos']),
      precoAtualPrecisoCentavos: _readPreciseCents(
        json['preco_atual_preciso_centavos'],
      ),
      precoPrimarioPrecisoCentavos: _readPreciseCents(
        json['preco_primario_preciso_centavos'],
      ),
      videoDemo: _asString(json['video_demo']),
      sumarioExecutivo: _asString(json['sumario_executivo']),
      planoDeNegocios: _asString(json['plano_de_negocios']),
      socios: _asList(json['socios']).map(SocioModel.fromJson).toList(),
      mentoresConselho: _asList(
        json['mentores_conselho'],
      ).map(MentorConselhoModel.fromJson).toList(),
      perguntasRespostas: _asList(
        json['perguntas_respostas'],
      ).map(PerguntaRespostaModel.fromJson).toList(),
      criadoEm: _asNullableString(json['criado_em']),
      atualizadoEm: _asNullableString(json['atualizado_em']),
    );
  }

  factory StartupModel.fromMap(String id, Map<String, dynamic> map) {
    return StartupModel(
      id: id,
      nome: _asString(map['nome']),
      descricao: _asString(map['descricao']),
      setor: _asString(map['setor']),
      estagio: _asString(map['estagio']),
      status: _asString(map['status']),
      capitalAportado: _asInt(map['capital_aportado']),
      tokensEmitidos: _asInt(map['tokens_emitidos']),
      precoAtualCentavos: _asInt(map['preco_atual_centavos']),
      precoPrimarioCentavos: _asInt(map['preco_primario_centavos']),
      precoAtualPrecisoCentavos: _readPreciseCents(
        map['preco_atual_preciso_centavos'],
      ),
      precoPrimarioPrecisoCentavos: _readPreciseCents(
        map['preco_primario_preciso_centavos'],
      ),
      videoDemo: _asString(map['video_demo']),
      sumarioExecutivo: _asString(map['sumario executivo']),
      planoDeNegocios: _asString(map['plano_de_negocios']),
      socios: _asList(map['socios']).map(SocioModel.fromJson).toList(),
      mentoresConselho: _asList(
        map['mentores_conselho'],
      ).map(MentorConselhoModel.fromJson).toList(),
      perguntasRespostas: _asList(
        map['perguntas_respostas'],
      ).map(PerguntaRespostaModel.fromJson).toList(),
      criadoEm: _asNullableString(map['criado_em']),
      atualizadoEm: _asNullableString(map['atualizado_em']),
    );
  }
}

class SocioModel {
  final String nome;
  final int participacao;

  SocioModel({required this.nome, required this.participacao});

  factory SocioModel.fromJson(Map<String, dynamic> json) {
    return SocioModel(
      nome: _asString(json['nome']),
      participacao: _asInt(json['participacao']),
    );
  }
}

class MentorConselhoModel {
  final String nome;
  final String papel;

  MentorConselhoModel({required this.nome, required this.papel});

  factory MentorConselhoModel.fromJson(Map<String, dynamic> json) {
    return MentorConselhoModel(
      nome: _asString(json['nome']),
      papel: _asString(json['papel']),
    );
  }
}

class PerguntaRespostaModel {
  final String pergunta;
  final List<RespostaModel> respostas;
  final String autor;
  final String? criadoEm;

  PerguntaRespostaModel({
    required this.pergunta,
    required this.respostas,
    required this.autor,
    this.criadoEm,
  });
  factory PerguntaRespostaModel.fromJson(Map<String, dynamic> json) {
    final rawRespostas = json['resposta'];

    List<RespostaModel> respostasConvertidas = [];

    if (rawRespostas is List) {
      respostasConvertidas = rawRespostas
          .whereType<Map>()
          .map((item) => RespostaModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return PerguntaRespostaModel(
      pergunta: _asString(json['pergunta']),

      respostas: respostasConvertidas,

      autor: _asString(json['autor']),
      criadoEm: _asNullableString(json['criado_em']),
    );
  }
}

class RespostaModel {
  final String nome;
  final String resposta;

  RespostaModel({required this.nome, required this.resposta});

  factory RespostaModel.fromMap(Map<String, dynamic> map) {
    return RespostaModel(
      nome: map['nome_autor'] ?? '',
      resposta: map['resposta'] ?? '',
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

int _readPreciseCents(dynamic value) {
  return _asInt(value);
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
