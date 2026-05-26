// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Mapper dos documentos da carteira do Firestore

import type {DocumentSnapshot} from "firebase-admin/firestore";
import {TransacaoData, WalletData} from "../types/walletTypes";

export function mapWalletDocument(doc: DocumentSnapshot): WalletData {
  const data = doc.data() as Record<string, unknown>;
  const availableBalanceCents = readCents(
    data,
    "saldo_disponivel_centavos",
    "saldo_disponivel",
  );
  const blockedBalanceCents = readCents(
    data,
    "saldo_bloqueado_centavos",
    "saldo_bloqueado",
  );

  return {
    uid: doc.id,
    nome: String(data.nome ?? ""),
    email: String(data.email ?? ""),
    saldo_disponivel: readLegacyMoney(
      data,
      "saldo_disponivel",
      availableBalanceCents,
    ),
    saldo_bloqueado: readLegacyMoney(
      data,
      "saldo_bloqueado",
      blockedBalanceCents,
    ),
    saldo_disponivel_centavos: availableBalanceCents,
    saldo_bloqueado_centavos: blockedBalanceCents,
  };
}

export function mapTransacaoDocument(doc: DocumentSnapshot): TransacaoData {
  const data = doc.data() as Record<string, unknown>;
  const unitPriceCents = readCents(
    data,
    "valor_unitario_centavos",
    "valor_unitario",
  );
  const totalAmountCents = readCents(
    data,
    "valor_total_centavos",
    "valor_total",
  );

  return {
    id: doc.id,
    startup_id: String(data.startup_id ?? ""),
    comprador_uid: String(data.comprador_uid ?? ""),
    vendedor_uid: String(data.vendedor_uid ?? ""),
    oferta_compra_id: String(data.oferta_compra_id ?? ""),
    oferta_venda_id: String(data.oferta_venda_id ?? ""),
    mercado: String(data.mercado ?? ""),
    quantidade: readInteger(data.quantidade),
    valor_unitario: readLegacyMoney(data, "valor_unitario", unitPriceCents),
    valor_total: readLegacyMoney(data, "valor_total", totalAmountCents),
    valor_unitario_centavos: unitPriceCents,
    valor_total_centavos: totalAmountCents,
    criado_em: data.criado_em as TransacaoData["criado_em"],
  };
}

function readCents(
  data: Record<string, unknown>,
  centsField: string,
  legacyField: string,
): number {
  if (data[centsField] !== undefined && data[centsField] !== null) {
    return readInteger(data[centsField]);
  }

  return Math.round(readNumber(data[legacyField]) * 100);
}

function readLegacyMoney(
  data: Record<string, unknown>,
  legacyField: string,
  cents: number,
): number {
  if (data[legacyField] !== undefined && data[legacyField] !== null) {
    return readNumber(data[legacyField]);
  }

  return cents / 100;
}

function readInteger(value: unknown): number {
  const numberValue = Number(value ?? 0);

  if (!Number.isSafeInteger(numberValue)) {
    return 0;
  }

  return numberValue;
}

function readNumber(value: unknown): number {
  const numberValue = Number(value ?? 0);

  if (!Number.isFinite(numberValue)) {
    return 0;
  }

  return numberValue;
}
