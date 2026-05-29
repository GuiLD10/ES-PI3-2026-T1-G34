// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Repositório de acesso ao Firestore para dados da carteira

import {db, fieldValue} from "../../shared/firebase";
import {convertFirestoreValue} from "../../shared/firestoreConverters";
import {PRICE_PRECISION_SCALE} from "../../shared/startupPricing";
import {
  mapTransacaoDocument,
  mapWalletDocument,
} from "../shared/walletMapper";
import {AtivoData, TransacaoData, WalletData} from "../types/walletTypes";

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
  const startupNames = await findStartupNames(
    [...new Set(transacoes.map((item) => item.startup_id))],
  );

  transacoes.sort((first, second) => {
    const firstDate = readDate(first.criado_em);
    const secondDate = readDate(second.criado_em);
    return secondDate.getTime() - firstDate.getTime();
  });

  return convertFirestoreValue(
    transacoes.map((item) => {
      return {
        ...item,
        startup_nome: startupNames.get(item.startup_id) ?? item.startup_id,
      };
    }),
  ) as TransacaoData[];
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

export async function findAtivosByUid(
  uid: string,
): Promise<AtivoData[]> {
  const snapshot = await db
    .collection("usuarios")
    .doc(uid)
    .collection("ativos")
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    const averagePriceCents = readInteger(data.valor_medio_centavos);
    const averagePricePreciseCents = readInteger(
      data.valor_medio_preciso_centavos,
    );

    return {
      startup_id: doc.id,
      quantidade_disponivel: readInteger(data.quantidade_disponivel),
      quantidade_bloqueada: readInteger(data.quantidade_bloqueada),
      valor_medio_centavos: averagePriceCents,
      valor_medio_preciso_centavos: averagePricePreciseCents > 0 ?
        averagePricePreciseCents :
        averagePriceCents * PRICE_PRECISION_SCALE,
    };
  });
}

export async function findTransacoesByStartupId(
  startupId: string,
): Promise<{
  preco_centavos: number;
  preco_preciso_centavos: number;
  data: string;
}[]> {
  const snapshot = await db
    .collection("transacoes")
    .where("startup_id", "==", startupId)
    .get();

  const historico = snapshot.docs.map((doc) => {
    const data = doc.data();
    const marketPriceCents = readInteger(data.preco_mercado_atual_centavos);
    const unitPriceCents = readInteger(data.valor_unitario_centavos);
    const preciseMarketPrice = readInteger(
      data.preco_mercado_atual_preciso_centavos,
    );
    const fallbackPriceCents = marketPriceCents > 0 ?
      marketPriceCents :
      unitPriceCents;

    return {
      preco_centavos: fallbackPriceCents,
      preco_preciso_centavos: preciseMarketPrice > 0 ?
        preciseMarketPrice :
        fallbackPriceCents * PRICE_PRECISION_SCALE,
      data: timestampToIso(data.criado_em),
    };
  });

  historico.sort((first, second) => {
    return new Date(first.data).getTime() - new Date(second.data).getTime();
  });

  return historico;
}

async function findStartupNames(startupIds: string[]) {
  const names = new Map<string, string>();
  const validIds = startupIds.filter((id) => id.trim() !== "");

  await Promise.all(validIds.map(async (startupId) => {
    const doc = await db.collection("startups").doc(startupId).get();
    const nome = String(doc.data()?.nome ?? "").trim();
    names.set(startupId, nome === "" ? startupId : nome);
  }));

  return names;
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

function readInteger(value: unknown): number {
  const num = Number(value ?? 0);
  return Number.isSafeInteger(num) ? num : 0;
}

function timestampToIso(value: unknown): string {
  if (value && typeof value === "object" && "toDate" in value) {
    return (value as {toDate: () => Date}).toDate().toISOString();
  }
  if (typeof value === "string") return value;
  return new Date(0).toISOString();
}
