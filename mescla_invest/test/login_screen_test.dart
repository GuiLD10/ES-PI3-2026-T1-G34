// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Testes basicos da tela de login.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mescla_invest/screens/auth/login_screen.dart';

void main() {
  testWidgets('exibe os controles principais de login', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Continuar conectado'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Cadastre-se'),
      ),
      findsOneWidget,
    );
  });
}
