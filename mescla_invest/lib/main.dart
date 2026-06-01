// Autor: Artur Pagno
// RA: 21013037
// Descrição: Ponto de entrada da aplicação

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase initialization error
  }
  runApp(const App());
}
