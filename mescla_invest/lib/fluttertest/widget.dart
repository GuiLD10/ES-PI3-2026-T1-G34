/*
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Se você estiver usando o Firebase em um projeto real, 
// você também precisará do arquivo de configuração gerado pelo CLI
import 'your_project/firebase_options.dart';

test('registrarUsuario cria novo perfil com sucesso', () async {
  final functions = FirebaseFunctions.instance; // Se usar emulador: .useFunctionsEmulator('localhost', 5001)

  final registroData = {
    'nome': 'Usuário de Teste',
    'email': 'teste_flutter@exemplo.com',
    'cpf': '123.456.789-00',
    'telefone': '11999999999',
    'senha': 'senhaForte123',
    'confirmarSenha': 'senhaForte123',
  };

  try {
    final result = await functions
        .httpsCallable('registrarUsuario')
        .call(registroData);

    final data = result.data as Map<String, dynamic>;

    expect(data['success'], isTrue);
    expect(data['uid'], isNotNull);
    expect(data['message'], contains('sucesso'));
  } on FirebaseFunctionsException catch (e) {
    fail('A função falhou com código: ${e.code} e mensagem: ${e.message}');
  }
});

test('loginUsuario autentica e retorna custom token', () async {
  final functions = FirebaseFunctions.instance;

  final loginData = {
    'email': 'teste_flutter@exemplo.com', // Use um e-mail que você sabe que existe ou criou no teste anterior
    'senha': 'senhaForte123',
  };

  final result = await functions
      .httpsCallable('loginUsuario')
      .call(loginData);

  final data = result.data as Map<String, dynamic>;

  expect(data['success'], isTrue);
  expect(data['token'], isNotNull); // Este é o Custom Token gerado pela Function
  expect(data['uid'], isNotNull);
});

test('registrarUsuario deve falhar se as senhas forem diferentes', () async {
  final functions = FirebaseFunctions.instance;

  final dadosErrados = {
    'nome': 'Erro Teste',
    'email': 'erro@teste.com',
    'senha': 'senha1',
    'confirmarSenha': 'senhaDiferente', // Senhas não batem
  };

  try {
    await functions.httpsCallable('registrarUsuario').call(dadosErrados);
    fail('Deveria ter lançado uma exceção');
  } on FirebaseFunctionsException catch (e) {
    // Verificamos se o erro é o 'invalid-argument' que definimos no Node
    expect(e.code, equals('invalid-argument'));
    expect(e.message, contains('não conferem'));
  }
});
*/