import type {
  DocumentSnapshot,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import {
  ExchangeOrderResponse,
  ExchangeTransactionResponse,
} from "../types/exchangeTypes";
import {
  readNonNegativeInteger,
  readOrderType,
} from "./exchangeParsing";
import {readOrderStatus} from "./exchangeValidation";

type TimestampLike = {
  toDate: () => Date;
  toMillis: () => number;
};

export function mapOrderDocument(
  doc: QueryDocumentSnapshot | DocumentSnapshot,
): ExchangeOrderResponse {
  const data = doc.data() ?? {};

  return {
    oferta_id: doc.id,
    tipo: readOrderType(data.tipo),
    usuario_uid: String(data.usuario_uid ?? ""),
    startup_id: String(data.startup_id ?? ""),
    quantidade_original: readNonNegativeInteger(data.quantidade_original),
    quantidade_restante: readNonNegativeInteger(data.quantidade_restante),
    valor_unitario_centavos: readNonNegativeInteger(
      data.valor_unitario_centavos,
    ),
    status: readOrderStatus(data.status),
    criado_em: timestampToIso(data.criado_em),
    atualizado_em: timestampToIso(data.atualizado_em),
  };
}

export function mapTransactionDocument(
  doc: QueryDocumentSnapshot | DocumentSnapshot,
): ExchangeTransactionResponse {
  const data = doc.data() ?? {};

  return {
    transacao_id: doc.id,
    mercado: String(data.mercado ?? ""),
    comprador_uid: String(data.comprador_uid ?? ""),
    vendedor_uid: String(data.vendedor_uid ?? ""),
    startup_id: String(data.startup_id ?? ""),
    oferta_compra_id: String(data.oferta_compra_id ?? ""),
    oferta_venda_id: String(data.oferta_venda_id ?? ""),
    quantidade: readNonNegativeInteger(data.quantidade),
    valor_unitario_centavos: readNonNegativeInteger(
      data.valor_unitario_centavos,
    ),
    valor_total_centavos: readNonNegativeInteger(data.valor_total_centavos),
    criado_em: timestampToIso(data.criado_em),
  };
}

export function timestampToIso(value: unknown): string | null {
  if (isTimestampLike(value)) {
    return value.toDate().toISOString();
  }

  return null;
}

export function timestampToMillis(value: unknown): number {
  if (isTimestampLike(value)) {
    return value.toMillis();
  }

  return 0;
}

function isTimestampLike(value: unknown): value is TimestampLike {
  const timestamp = value as Partial<TimestampLike>;
  return (
    value !== null &&
    typeof value === "object" &&
    typeof timestamp.toDate === "function" &&
    typeof timestamp.toMillis === "function"
  );
}
