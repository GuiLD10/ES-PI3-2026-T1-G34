// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Repositório de acesso ao Firestore para dados da carteira

import { db, fieldValue } from "../../shared/firebase";
import { mapWalletDocument, mapTransacaoDocument } from "../shared/walletMapper";
import { convertFirestoreValue } from "../../shared/firestoreConverters";
import { WalletData, TransacaoData } from "../types/walletTypes";

export async function findWalletByUid(uid: string): Promise<WalletData | null> {
  const doc = await db.collection("usuarios").doc(uid).get();

  if (!doc.exists) return null;

  const wallet = mapWalletDocument(doc);
  return convertFirestoreValue(wallet) as WalletData;
}

export async function findTransacoesByUid(
  uid: string
): Promise<TransacaoData[]> {
  const [compras, vendas] = await Promise.all([
    db.collection("transacoes").where("comprador_uid", "==", uid).get(),
    db.collection("transacoes").where("vendedor_uid", "==", uid).get(),
  ]);

  const todas = [
    ...compras.docs.map(mapTransacaoDocument),
    ...vendas.docs.map(mapTransacaoDocument),
  ];

  // Ordena por data decrescente
  todas.sort((a, b) => {
    const dateA = a.criado_em?.toDate?.() ?? new Date(0);
    const dateB = b.criado_em?.toDate?.() ?? new Date(0);
    return dateB.getTime() - dateA.getTime();
  });

  return convertFirestoreValue(todas) as TransacaoData[];
}

export async function adicionarSaldoDisponivel(
  uid: string,
  valor: number
): Promise<void> {
  const docRef = db.collection("usuarios").doc(uid);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new Error("Usuário não encontrado.");
  }

  await docRef.update({
    saldo_disponivel: fieldValue.increment(valor),
  });
}