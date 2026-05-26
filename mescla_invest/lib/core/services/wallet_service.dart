// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Service de carteira - comunica com Firebase Functions

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/transaction_model.dart';
import '../../../models/wallet_model.dart';
import 'auth_service.dart';

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
      throw WalletServiceException('Resposta invalida ao buscar carteira.');
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
      throw WalletServiceException('Resposta invalida ao buscar transacoes.');
    }

    return transacoesJson.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      final id = map['id'] as String? ?? '';
      return TransactionModel.fromMap(id, map);
    }).toList();
  }

  static Future<void> adicionarSaldo(double valor) async {
    await _postJson('wallet-adicionarSaldo', {'valor': valor});
  }

  static Future<Map<String, dynamic>> _getJson(
    String functionName, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await http
          .get(
            _functionUri(functionName, queryParameters),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      return _validateResponse(response, 'Erro ao buscar dados da carteira.');
    } on WalletServiceException {
      rethrow;
    } catch (_) {
      throw WalletServiceException(
        'Erro de conexao. Verifique se o emulador das Functions esta rodando.',
      );
    }
  }

  static Future<Map<String, dynamic>> _postJson(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            _functionUri(functionName, null),
            headers: AuthService.headersAutenticados(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _validateResponse(response, 'Erro ao adicionar saldo.');
    } on WalletServiceException {
      rethrow;
    } on AuthServiceException catch (e) {
      throw WalletServiceException(e.message);
    } catch (_) {
      throw WalletServiceException(
        'Erro de conexao. Verifique se o emulador das Functions esta rodando.',
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

  static Map<String, dynamic> _validateResponse(
    http.Response response,
    String fallbackMessage,
  ) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw WalletServiceException('Resposta invalida das Functions.');
    }

    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw WalletServiceException(_extractMessage(data) ?? fallbackMessage);
    }

    return data;
  }

  static String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message == null) return null;

    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }
}
