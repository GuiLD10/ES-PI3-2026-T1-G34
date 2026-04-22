// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Servico de startups que se comunica com o servidor Node.js

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/startup_model.dart';

class StartupService {
  // Emulador Android - http://10.0.2.2:3000.
  // Em dispositivo fisico - IP da maquina na rede local.
  static const String _baseUrl = 'http://localhost:3000';

  static Future<List<StartupModel>> listarStartups() async {
    final data = await _getJson('/startups');
    final startupsJson = data['data'];

    if (startupsJson is! List) {
      throw const StartupServiceException(
        'Resposta invalida ao buscar startups.',
      );
    }

    return startupsJson
        .whereType<Map>()
        .map((item) => StartupModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<StartupModel> buscarStartupPorId(String id) async {
    final startupId = id.trim();

    if (startupId.isEmpty) {
      throw const StartupServiceException('ID da startup e obrigatorio.');
    }

    final data = await _getJson('/startups/${Uri.encodeComponent(startupId)}');
    final startupJson = data['data'];

    if (startupJson is! Map) {
      throw const StartupServiceException(
        'Resposta invalida ao buscar startup.',
      );
    }

    return StartupModel.fromJson(Map<String, dynamic>.from(startupJson));
  }

  static Future<Map<String, dynamic>> _getJson(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const StartupServiceException('Resposta invalida do servidor.');
      }

      final data = Map<String, dynamic>.from(decoded);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] != true) {
        throw StartupServiceException(
          _extrairMensagem(data) ?? 'Erro ao buscar dados de startups.',
        );
      }

      return data;
    } on StartupServiceException {
      rethrow;
    } catch (_) {
      throw const StartupServiceException(
        'Erro de conexao. Verifique se o servidor esta rodando.',
      );
    }
  }

  static String? _extrairMensagem(Map<String, dynamic> data) {
    final message = data['message'];
    if (message == null) return null;

    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class StartupServiceException implements Exception {
  final String message;

  const StartupServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
