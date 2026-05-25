// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import {db} from "../../shared/firebase";
import {
  EXCHANGE_COLLECTIONS,
  ORDER_STATUS,
  ORDER_TYPES,
  ExchangeOrderResponse,
  ExchangeTransactionResponse,
  OrderBookResponse,
} from "../types/exchangeTypes";
import {ExchangeError} from "../shared/exchangeErrors";
import {
  mapOrderDocument,
  mapTransactionDocument,
} from "../shared/exchangeMappers";
import {readNonNegativeInteger} from "../shared/exchangeParsing";

const ORDER_BOOK_LIMIT = 25;
const MY_ORDERS_LIMIT = 80;
const TRANSACTIONS_LIMIT = 80;

export async function getOrderBook(
  startupId: string,
): Promise<OrderBookResponse> {
  const startup = await loadActiveStartup(startupId);
  const snapshot = await db
    .collection(EXCHANGE_COLLECTIONS.orders)
    .where("startup_id", "==", startupId)
    .get();
  const orders = snapshot.docs
    .map(mapOrderDocument)
    .filter((order) => {
      return (
        order.status === ORDER_STATUS.open ||
        order.status === ORDER_STATUS.partial
      );
    })
    .filter((order) => order.quantidade_restante > 0);
  const buys = orders
    .filter((order) => order.tipo === ORDER_TYPES.buy)
    .sort(sortBuyOrders)
    .slice(0, ORDER_BOOK_LIMIT);
  const sells = orders
    .filter((order) => order.tipo === ORDER_TYPES.sell)
    .sort(sortSellOrders)
    .slice(0, ORDER_BOOK_LIMIT);

  return {
    startup_id: startupId,
    preco_atual_centavos: readNonNegativeInteger(
      startup.preco_atual_centavos,
    ),
    melhor_compra: buys[0] ?? null,
    melhor_venda: sells[0] ?? null,
    compras: buys,
    vendas: sells,
  };
}

export async function listUserOrders(
  uid: string,
): Promise<ExchangeOrderResponse[]> {
  const snapshot = await db
    .collection(EXCHANGE_COLLECTIONS.orders)
    .where("usuario_uid", "==", uid)
    .get();

  return snapshot.docs
    .map(mapOrderDocument)
    .sort((first, second) => compareDatesDesc(
      first.criado_em,
      second.criado_em,
    ))
    .slice(0, MY_ORDERS_LIMIT);
}

export async function listStartupTransactions(
  startupId: string,
): Promise<ExchangeTransactionResponse[]> {
  const snapshot = await db
    .collection(EXCHANGE_COLLECTIONS.transactions)
    .where("startup_id", "==", startupId)
    .get();

  return snapshot.docs
    .map(mapTransactionDocument)
    .sort((first, second) => compareDatesDesc(
      first.criado_em,
      second.criado_em,
    ))
    .slice(0, TRANSACTIONS_LIMIT);
}

async function loadActiveStartup(startupId: string) {
  const doc = await db
    .collection(EXCHANGE_COLLECTIONS.startups)
    .doc(startupId)
    .get();

  if (!doc.exists) {
    throw new ExchangeError(404, "Startup nao encontrada.", "startup_id");
  }

  const startup = doc.data() ?? {};

  if (String(startup.status ?? "") !== "ativa") {
    throw new ExchangeError(404, "Startup nao encontrada.", "startup_id");
  }

  return startup;
}

function sortBuyOrders(
  first: ExchangeOrderResponse,
  second: ExchangeOrderResponse,
) {
  const price = second.valor_unitario_centavos -
    first.valor_unitario_centavos;

  if (price !== 0) return price;
  return compareDatesAsc(first.criado_em, second.criado_em);
}

function sortSellOrders(
  first: ExchangeOrderResponse,
  second: ExchangeOrderResponse,
) {
  const price = first.valor_unitario_centavos -
    second.valor_unitario_centavos;

  if (price !== 0) return price;
  return compareDatesAsc(first.criado_em, second.criado_em);
}

function compareDatesAsc(first: string | null, second: string | null) {
  return Date.parse(first ?? "") - Date.parse(second ?? "");
}

function compareDatesDesc(first: string | null, second: string | null) {
  return Date.parse(second ?? "") - Date.parse(first ?? "");
}
