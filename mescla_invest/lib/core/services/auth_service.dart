// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descricao: Servico de autenticacao que se comunica com Firebase Functions

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'session_manager.dart';

class AuthService {
  static const String _functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: 'http://localhost:5001/mesclainvest-d3745/us-central1',
  );

  static String? _uid;
  static String? _token;
  static Map<String, dynamic>? _pendingMfaSession;
  static bool _pendingMfaPersistir = false;

  static String? get currentUid => _uid ?? SessionManager.uid;
  static bool get isAuthenticated {
    final token = _token ?? SessionManager.token;
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String senha,
    required String confirmarSenha,
  }) async {
    final response = await _postJson('authentication-registerUser', {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
    });

    if (response['success'] == true) {
      await _storeSession(response);
    }

    return response;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
    bool continuarConectado = false,
  }) async {
    final response = await _postJson('authentication-loginUser', {
      'email': email,
      'senha': senha,
    });

    if (response['success'] == true) {
      if (response['requiresMfa'] == true) {
        _pendingMfaSession = Map<String, dynamic>.from(response);
        _pendingMfaPersistir = continuarConectado;
        _clearMemorySession();
        await SessionManager.limparSessaoPersistente();
      } else {
        await _storeSession(response, persistir: continuarConectado);
      }
    }

    return response;
  }

  static Future<bool> restaurarSessao() async {
    final refreshToken = await _carregarRefreshTokenPersistente();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final response = await _postJson('authentication-refreshSession', {
      'refreshToken': refreshToken,
    });

    if (response['success'] != true) {
      await clearSession();
      return false;
    }

    await _storeSession(response, persistir: true);
    return isAuthenticated;
  }

  static Future<Map<String, dynamic>> recuperarSenha({
    required String email,
  }) async {
    return _postJson('authentication-sendPasswordReset', {'email': email});
  }

  static Future<String> iniciarVerificacaoTelefone(String telefone) async {
    final completer = Completer<String>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: telefone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
            AuthServiceException(
              e.message ?? 'Erro ao enviar SMS de verificacao.',
            ),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    return completer.future;
  }

  static Future<bool> confirmarCodigoOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw const AuthServiceException('Codigo de verificacao invalido.');
      }
      if (e.code == 'credential-already-in-use') {
        throw const AuthServiceException(
          'Este telefone ja esta vinculado a outra conta.',
        );
      }
      throw AuthServiceException(e.message ?? 'Erro ao verificar codigo.');
    }
  }

  static Future<bool> verificarCodigoMfaLogin({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final pendingSession = _pendingMfaSession;
      if (pendingSession == null) {
        throw const AuthServiceException(
          'Sessao MFA expirada. Faca login novamente.',
        );
      }

      await _storeSession(pendingSession, persistir: _pendingMfaPersistir);
      _clearPendingMfaSession();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw const AuthServiceException('Codigo de verificacao invalido.');
      }
      throw AuthServiceException(e.message ?? 'Erro ao verificar codigo.');
    }
  }

  static Future<Map<String, dynamic>> toggleMfa({required bool ativar}) async {
    if (!isAuthenticated) {
      return {'success': false, 'message': 'Usuario nao autenticado.'};
    }

    final response = await _postJson(
      'authentication-toggleMfa',
      {'ativar': ativar},
      autenticado: true,
    );

    if (response['success'] == true) {
      SessionManager.setMfaAtivo(ativar);
    }

    return response;
  }

  static bool get isMfaAtivo => SessionManager.mfaAtivo;

  static Map<String, String> headersAutenticados() {
    final token = _token ?? SessionManager.token;

    if (token == null || token.isEmpty) {
      throw const AuthServiceException('Usuario nao autenticado.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<void> clearSession() async {
    _clearPendingMfaSession();
    _clearMemorySession();
    await SessionManager.limparSessaoPersistente();
  }

  static Future<Map<String, dynamic>> _postJson(
    String functionName,
    Map<String, dynamic> body, {
    bool autenticado = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_functionsBaseUrl/$functionName'),
            headers: autenticado
                ? headersAutenticados()
                : {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return {
          'success': false,
          'message': 'Resposta invalida das Functions.',
        };
      }

      return Map<String, dynamic>.from(decoded);
    } on AuthServiceException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (_) {
      return {
        'success': false,
        'message':
            'Erro de conexao. Verifique se o emulador das Functions esta rodando.',
      };
    }
  }

  static Future<void> _storeSession(
    Map<String, dynamic> response, {
    bool persistir = false,
  }) async {
    final uid = response['uid']?.toString().trim();
    final token = response['token']?.toString().trim();
    final refreshToken = response['refreshToken']?.toString().trim();
    final name = response['name']?.toString().trim();
    final telefone = response['telefone']?.toString().trim();
    final mfaAtivo = response['requiresMfa'] == true;

    if (uid == null ||
        uid.isEmpty ||
        token == null ||
        token.isEmpty ||
        name == null ||
        name.isEmpty) {
      return;
    }

    _uid = uid;
    _token = token;
    await SessionManager.salvarSessao(
      uid: uid,
      token: token,
      name: name,
      telefone: telefone ?? '',
      refreshToken: refreshToken,
      mfaAtivo: mfaAtivo,
      persistir: persistir,
    );
  }

  static Future<String?> _carregarRefreshTokenPersistente() async {
    try {
      return await SessionManager.carregarRefreshTokenPersistente();
    } catch (_) {
      return null;
    }
  }

  static void _clearMemorySession() {
    _uid = null;
    _token = null;
    SessionManager.limparSessao();
  }

  static void _clearPendingMfaSession() {
    _pendingMfaSession = null;
    _pendingMfaPersistir = false;
  }

  static String? getTelefoneUsuario() {
    final telefone = SessionManager.telefone;

    if (telefone == null || telefone.trim().isEmpty) {
      return null;
    }

    return telefone;
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
