// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Service de carteira - comunica com Firebase Functions

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/wallet_model.dart';
import '../../../models/transaction_model.dart';

class WalletServiceException implements Exception {
  final String message;
  WalletServiceException(this.message);
}

class WalletService {
  static const String _functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: 'http://localhost:5001/mesclainvest-d3745/us-central1',
  );

  static Future<WalletModel> buscarCarteira(String uid) async {
    final data = await _getJson(
      'wallet-getWallet',
      queryParameters: {'uid': uid},
    );
    final walletJson = data['data'];

    if (walletJson is! Map) {
      throw WalletServiceException('Resposta inválida ao buscar carteira.');
    }

    return WalletModel.fromMap(uid, Map<String, dynamic>.from(walletJson));
  }

  static Future<List<TransactionModel>> buscarTransacoes(String uid) async {
    final data = await _getJson(
      'wallet-getTransacoes',
      queryParameters: {'uid': uid},
    );
    final transacoesJson = data['data'];

    if (transacoesJson is! List) {
      throw WalletServiceException('Resposta inválida ao buscar transações.');
    }

    return transacoesJson
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id'] as String? ?? '';
          return TransactionModel.fromMap(id, map);
        })
        .toList();
  }

  static Future<void> adicionarSaldo(String uid, double valor) async {
    try {
      print('[WalletService] Adicionando saldo: R\$ $valor para uid: $uid');

      final uri = Uri.parse('$_functionsBaseUrl/wallet-adicionarSaldo');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'valor': valor}),
          )
          .timeout(const Duration(seconds: 15));

      print('[WalletService] Status: ${response.statusCode}');
      print('[WalletService] Resposta: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw WalletServiceException('Resposta inválida das Functions.');
      }

      final data = Map<String, dynamic>.from(decoded);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] != true) {
        throw WalletServiceException(
          _extractMessage(data) ?? 'Erro ao adicionar saldo.',
        );
      }
    } on WalletServiceException {
      rethrow;
    } catch (e, stackTrace) {
      print('[WalletService] Erro: $e');
      print('[WalletService] Stack: $stackTrace');
      throw WalletServiceException(
        'Erro de conexão. Verifique se o emulador das Functions está rodando.',
      );
    }
  }

  static Future<Map<String, dynamic>> _getJson(
    String functionName, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      print('[WalletService] Chamando: $_functionsBaseUrl/$functionName?$queryParameters');

      final response = await http
          .get(
            _functionUri(functionName, queryParameters),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      print('[WalletService] Status: ${response.statusCode}');
      print('[WalletService] Resposta: ${response.body}');

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw WalletServiceException('Resposta inválida das Functions.');
      }

      final data = Map<String, dynamic>.from(decoded);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] != true) {
        throw WalletServiceException(
          _extractMessage(data) ?? 'Erro ao buscar dados da carteira.',
        );
      }

      return data;
    } on WalletServiceException {
      rethrow;
    } catch (e, stackTrace) {
      print('[WalletService] Erro: $e');
      print('[WalletService] Stack: $stackTrace');
      throw WalletServiceException(
        'Erro de conexão. Verifique se o emulador das Functions está rodando.',
      );
    }
  }

  static Uri _functionUri(
    String functionName,
    Map<String, String>? queryParameters,
  ) {
    return Uri.parse(
      '$_functionsBaseUrl/$functionName',
    ).replace(queryParameters: queryParameters);
  }

  static String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message == null) return null;

    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }
}