// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Repositório de acesso ao Firestore para dados da carteira

import {db, fieldValue} from "../../shared/firebase";
import {convertFirestoreValue} from "../../shared/firestoreConverters";
import {
  mapTransacaoDocument,
  mapWalletDocument,
} from "../shared/walletMapper";
import {TransacaoData, WalletData} from "../types/walletTypes";

export async function findWalletByUid(uid: string): Promise<WalletData | null> {
  const doc = await db.collection("usuarios").doc(uid).get();

  if (!doc.exists) return null;

  const wallet = mapWalletDocument(doc);
  return convertFirestoreValue(wallet) as WalletData;
}

export async function findTransacoesByUid(
  uid: string,
): Promise<TransacaoData[]> {
  const [compras, vendas] = await Promise.all([
    db.collection("transacoes").where("comprador_uid", "==", uid).get(),
    db.collection("transacoes").where("vendedor_uid", "==", uid).get(),
  ]);
  const transacoes = [
    ...compras.docs.map(mapTransacaoDocument),
    ...vendas.docs.map(mapTransacaoDocument),
  ];

  transacoes.sort((first, second) => {
    const firstDate = readDate(first.criado_em);
    const secondDate = readDate(second.criado_em);
    return secondDate.getTime() - firstDate.getTime();
  });

  return convertFirestoreValue(transacoes) as TransacaoData[];
}

export async function adicionarSaldoDisponivel(
  uid: string,
  valorCentavos: number,
): Promise<boolean> {
  const docRef = db.collection("usuarios").doc(uid);
  const doc = await docRef.get();

  if (!doc.exists) {
    return false;
  }

  await docRef.update({
    saldo_disponivel_centavos: fieldValue.increment(valorCentavos),
    atualizado_em: fieldValue.serverTimestamp(),
  });

  return true;
}

function readDate(value: TransacaoData["criado_em"]): Date {
  if (value && typeof value !== "string") {
    return value.toDate();
  }

  if (typeof value === "string") {
    return new Date(value);
  }

  return new Date(0);
}
