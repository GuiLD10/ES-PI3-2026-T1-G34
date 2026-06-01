// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/balcao_model.dart';
import 'auth_service.dart';

class BalcaoService {
  static const String _functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: 'http://localhost:5001/mesclainvest-d3745/us-central1',
  );

  static Future<OrderBookBalcaoModel> buscarOrderBook(String startupId) async {
    final data = await _getJson(
      'exchange-getOrderBook',
      queryParameters: {'startupId': startupId},
    );
    final payload = data['data'];

    if (payload is! Map) {
      throw const BalcaoServiceException('Resposta inválida do order book.');
    }

    return OrderBookBalcaoModel.fromJson(Map<String, dynamic>.from(payload));
  }

  static Future<List<OfertaBalcaoModel>> listarMinhasOfertas() async {
    final data = await _getJson('exchange-listMyOrders');
    final payload = data['data'];

    if (payload is! List) {
      throw const BalcaoServiceException('Resposta inválida das ofertas.');
    }

    return payload
        .whereType<Map>()
        .map(
          (item) => OfertaBalcaoModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<List<TransacaoBalcaoModel>> listarTransacoes(
    String startupId,
  ) async {
    final data = await _getJson(
      'exchange-listStartupTransactions',
      queryParameters: {'startupId': startupId},
    );
    final payload = data['data'];

    if (payload is! List) {
      throw const BalcaoServiceException('Resposta inválida das transações.');
    }

    return payload
        .whereType<Map>()
        .map(
          (item) =>
              TransacaoBalcaoModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<ResultadoOfertaBalcaoModel> criarOferta({
    required String startupId,
    required String tipo,
    required int quantidade,
    required double valorUnitario,
  }) async {
    final data = await _postJson('exchange-createOrder', {
      'startup_id': startupId,
      'tipo': tipo,
      'quantidade': quantidade,
      'valor_unitario': valorUnitario,
    });
    final payload = data['data'];

    if (payload is! Map) {
      throw const BalcaoServiceException('Resposta inválida ao criar oferta.');
    }

    return ResultadoOfertaBalcaoModel.fromJson(
      Map<String, dynamic>.from(payload),
    );
  }

  static Future<ResultadoOperacaoMercadoModel> comprarAoPrecoMercado({
    required String startupId,
    required int quantidade,
  }) async {
    final data = await _postJson('exchange-buyAtMarket', {
      'startup_id': startupId,
      'quantidade': quantidade,
    });
    final payload = data['data'];

    if (payload is! Map) {
      throw const BalcaoServiceException(
        'Resposta inválida ao comprar tokens.',
      );
    }

    return ResultadoOperacaoMercadoModel.fromJson(
      Map<String, dynamic>.from(payload),
    );
  }

  static Future<ResultadoOperacaoMercadoModel> venderAoPrecoMercado({
    required String startupId,
    required int quantidade,
  }) async {
    final data = await _postJson('exchange-sellAtMarket', {
      'startup_id': startupId,
      'quantidade': quantidade,
    });
    final payload = data['data'];

    if (payload is! Map) {
      throw const BalcaoServiceException('Resposta inválida ao vender tokens.');
    }

    return ResultadoOperacaoMercadoModel.fromJson(
      Map<String, dynamic>.from(payload),
    );
  }

  static Future<void> cancelarOferta(String ofertaId) async {
    await _postJson('exchange-cancelOrder', {'oferta_id': ofertaId});
  }

  static Future<Map<String, dynamic>> _getJson(
    String functionName, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await http
          .get(
            _functionUri(functionName, queryParameters),
            headers: AuthService.headersAutenticados(),
          )
          .timeout(const Duration(seconds: 15));

      return _validateResponse(response);
    } on BalcaoServiceException {
      rethrow;
    } on AuthServiceException catch (e) {
      throw BalcaoServiceException(e.message);
    } catch (_) {
      throw const BalcaoServiceException(
        'Erro de conexão. Verifique se o emulador das Functions está rodando.',
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

      return _validateResponse(response);
    } on BalcaoServiceException {
      rethrow;
    } on AuthServiceException catch (e) {
      throw BalcaoServiceException(e.message);
    } catch (_) {
      throw const BalcaoServiceException(
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

  static Map<String, dynamic> _validateResponse(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const BalcaoServiceException('Resposta inválida das Functions.');
    }

    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw BalcaoServiceException(
        _extractMessage(data) ?? 'Erro ao processar operação do balcão.',
      );
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

class BalcaoServiceException implements Exception {
  final String message;

  const BalcaoServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
