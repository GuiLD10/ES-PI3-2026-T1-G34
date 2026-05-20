// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Service de carteira - busca dados do usuario e transacoes no Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/wallet_model.dart';
import '../../../models/transaction_model.dart';

class WalletServiceException implements Exception {
  final String message;
  WalletServiceException(this.message);
}

class WalletService {
  static final _db = FirebaseFirestore.instance;

  // Busca saldo e dados da carteira do usuário
  static Future<WalletModel> buscarCarteira(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        throw WalletServiceException('Carteira não encontrada.');
      }

      return WalletModel.fromMap(uid, doc.data()!);
    } on WalletServiceException {
      rethrow;
    } catch (e) {
      throw WalletServiceException('Erro ao buscar carteira: $e');
    }
  }

  // Busca transações do usuário (como comprador ou vendedor)
  static Future<List<TransactionModel>> buscarTransacoes(String uid) async {
  try {
    final compras = await _db
        .collection('transacoes')
        .where('comprador_uid', isEqualTo: uid)
        .get(); // removido orderBy

    final vendas = await _db
        .collection('transacoes')
        .where('vendedor_uid', isEqualTo: uid)
        .get(); // removido orderBy

    final todasTransacoes = [
      ...compras.docs.map((d) => TransactionModel.fromMap(d.id, d.data())),
      ...vendas.docs.map((d) => TransactionModel.fromMap(d.id, d.data())),
    ];

    todasTransacoes.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    return todasTransacoes;
  } catch (e) {
    print('ERRO TRANSACOES: $e');
    throw WalletServiceException('Erro ao buscar transações: $e');
  }
}

  // Busca ofertas abertas ou parciais do usuário
  static Future<List<Map<String, dynamic>>> buscarOfertasAtivas(
      String uid) async {
    try {
      final snapshot = await _db
          .collection('ofertas')
          .where('usuario_uid', isEqualTo: uid)
          .where('status', whereIn: ['aberta', 'parcial'])
          .orderBy('criado_em', descending: true)
          .get();

      return snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
    } catch (e) {
      throw WalletServiceException('Erro ao buscar ofertas: $e');
    }
  }
}