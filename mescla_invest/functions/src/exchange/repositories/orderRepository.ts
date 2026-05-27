// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import type {
  DocumentReference,
  DocumentSnapshot,
  Transaction,
} from "firebase-admin/firestore";
import {db, fieldValue} from "../../shared/firebase";
import {
  buildStartupPriceInitializationPatch,
  calculateMarketImpactPriceCents,
  getStartupMarketPrices,
} from "../../shared/startupPricing";
import type {StartupMarketPrices} from "../../shared/startupPricing";
import {
  AuthenticatedExchangeUser,
  CancelledOrderResponse,
  CreateOrderInput,
  CreatedOrderResponse,
  EXCHANGE_COLLECTIONS,
  ExchangeOrderDocument,
  ExchangeTransactionDocument,
  MarketBuyInput,
  MarketBuyResponse,
  MarketSellInput,
  MarketSellResponse,
  ORDER_STATUS,
  ORDER_TYPES,
  OrderType,
  StartupPriceReference,
  TRANSACTION_MARKETS,
  UserAssetBalance,
  WalletBalance,
} from "../types/exchangeTypes";
import {ExchangeError} from "../shared/exchangeErrors";
import {
  readNonNegativeInteger,
  readOrderType,
  requireNonNegativeInteger,
  requirePositiveInteger,
} from "../shared/exchangeParsing";
import {
  readOrderStatus,
  validateAvailableAssets,
  validateAvailableBalance,
  validatePriceRange,
} from "../shared/exchangeValidation";
import {executeOrderMatching} from "./orderMatchingRepository";

export async function createOrder(
  user: AuthenticatedExchangeUser,
  input: CreateOrderInput,
): Promise<CreatedOrderResponse> {
  if (input.type === ORDER_TYPES.buy) {
    return createBuyOrder(user, input);
  }

  return createSellOrder(user, input);
}

export async function buyAtMarket(
  user: AuthenticatedExchangeUser,
  input: MarketBuyInput,
): Promise<MarketBuyResponse> {
  const transactionRef = db.collection(EXCHANGE_COLLECTIONS.transactions).doc();
  let response: MarketBuyResponse | null = null;

  await db.runTransaction(async (transaction) => {
    const startupRef = db
      .collection(EXCHANGE_COLLECTIONS.startups)
      .doc(input.startupId);
    const startupDoc = await transaction.get(startupRef);
    const startup = loadActiveStartupFromData(input.startupId, startupDoc);
    const totalAmountCents = calculateTotalCents(
      input.quantity,
      startup.referencePriceCents,
    );
    const userRef = db.collection(EXCHANGE_COLLECTIONS.users).doc(user.uid);
    const wallet = await loadWallet(transaction, userRef);
    const assetRef = userAssetRef(user.uid, startup.id);
    const asset = await loadAsset(transaction, assetRef);
    const pricePatch = buildStartupPriceInitializationPatch(
      startup.rawData,
      startup.prices,
    );
    const nextPriceCents = calculateMarketImpactPriceCents(
      startup.referencePriceCents,
      input.quantity,
      startup.prices.totalTokens,
      ORDER_TYPES.buy,
    );

    validateAvailableBalance(wallet, totalAmountCents);
    transaction.update(userRef, {
      saldo_disponivel_centavos:
        wallet.availableBalanceCents - totalAmountCents,
      atualizado_em: fieldValue.serverTimestamp(),
    });
    transaction.set(assetRef, {
      startup_id: startup.id,
      quantidade_disponivel: asset.availableQuantity + input.quantity,
      quantidade_bloqueada: asset.blockedQuantity,
      valor_medio_centavos: calculateAveragePriceCents(
        asset.availableQuantity + asset.blockedQuantity,
        asset.averagePriceCents,
        input.quantity,
        startup.referencePriceCents,
      ),
      atualizado_em: fieldValue.serverTimestamp(),
    }, {merge: true});
    transaction.set(transactionRef, {
      mercado: TRANSACTION_MARKETS.primary,
      comprador_uid: user.uid,
      vendedor_uid: `startup:${startup.id}`,
      startup_id: startup.id,
      oferta_compra_id: "",
      oferta_venda_id: "",
      quantidade: input.quantity,
      valor_unitario_centavos: startup.referencePriceCents,
      valor_total_centavos: totalAmountCents,
      criado_em: fieldValue.serverTimestamp(),
    } satisfies ExchangeTransactionDocument);
    transaction.update(startupRef, {
      ...pricePatch,
      preco_atual_centavos: nextPriceCents,
      atualizado_em: fieldValue.serverTimestamp(),
    });

    response = {
      startup_id: startup.id,
      quantidade: input.quantity,
      valor_unitario_centavos: startup.referencePriceCents,
      valor_total_centavos: totalAmountCents,
      preco_anterior_centavos: startup.referencePriceCents,
      preco_atual_centavos: nextPriceCents,
      transacao_id: transactionRef.id,
    };
  });

  if (!response) {
    throw new ExchangeError(500, "Compra nao foi concluida.");
  }

  return response;
}

export async function sellAtMarket(
  user: AuthenticatedExchangeUser,
  input: MarketSellInput,
): Promise<MarketSellResponse> {
  const transactionRef = db.collection(EXCHANGE_COLLECTIONS.transactions).doc();
  let response: MarketSellResponse | null = null;

  await db.runTransaction(async (transaction) => {
    const startupRef = db
      .collection(EXCHANGE_COLLECTIONS.startups)
      .doc(input.startupId);
    const startupDoc = await transaction.get(startupRef);
    const startup = loadActiveStartupFromData(input.startupId, startupDoc);
    const totalAmountCents = calculateTotalCents(
      input.quantity,
      startup.referencePriceCents,
    );
    const userRef = db.collection(EXCHANGE_COLLECTIONS.users).doc(user.uid);
    const wallet = await loadWallet(transaction, userRef);
    const assetRef = userAssetRef(user.uid, startup.id);
    const asset = await loadAsset(transaction, assetRef);
    const pricePatch = buildStartupPriceInitializationPatch(
      startup.rawData,
      startup.prices,
    );
    const nextPriceCents = calculateMarketImpactPriceCents(
      startup.referencePriceCents,
      input.quantity,
      startup.prices.totalTokens,
      ORDER_TYPES.sell,
    );

    validateAvailableAssets(asset, input.quantity);
    transaction.update(userRef, {
      saldo_disponivel_centavos:
        wallet.availableBalanceCents + totalAmountCents,
      atualizado_em: fieldValue.serverTimestamp(),
    });
    transaction.set(assetRef, {
      startup_id: startup.id,
      quantidade_disponivel: asset.availableQuantity - input.quantity,
      quantidade_bloqueada: asset.blockedQuantity,
      valor_medio_centavos: calculateAveragePriceAfterSell(
        asset.availableQuantity + asset.blockedQuantity,
        asset.averagePriceCents,
        input.quantity,
      ),
      atualizado_em: fieldValue.serverTimestamp(),
    }, {merge: true});
    transaction.set(transactionRef, {
      mercado: TRANSACTION_MARKETS.primary,
      comprador_uid: `startup:${startup.id}`,
      vendedor_uid: user.uid,
      startup_id: startup.id,
      oferta_compra_id: "",
      oferta_venda_id: "",
      quantidade: input.quantity,
      valor_unitario_centavos: startup.referencePriceCents,
      valor_total_centavos: totalAmountCents,
      criado_em: fieldValue.serverTimestamp(),
    } satisfies ExchangeTransactionDocument);
    transaction.update(startupRef, {
      ...pricePatch,
      preco_atual_centavos: nextPriceCents,
      atualizado_em: fieldValue.serverTimestamp(),
    });

    response = {
      startup_id: startup.id,
      quantidade: input.quantity,
      valor_unitario_centavos: startup.referencePriceCents,
      valor_total_centavos: totalAmountCents,
      preco_anterior_centavos: startup.referencePriceCents,
      preco_atual_centavos: nextPriceCents,
      transacao_id: transactionRef.id,
    };
  });

  if (!response) {
    throw new ExchangeError(500, "Venda nao foi concluida.");
  }

  return response;
}

export async function cancelOrder(
  user: AuthenticatedExchangeUser,
  orderId: string,
): Promise<CancelledOrderResponse> {
  await db.runTransaction(async (transaction) => {
    const orderRef = db.collection(EXCHANGE_COLLECTIONS.orders).doc(orderId);
    const orderDoc = await transaction.get(orderRef);

    if (!orderDoc.exists) {
      throw new ExchangeError(404, "Oferta nao encontrada.", "oferta_id");
    }

    const order = buildCancellationOrder(orderDoc.data() ?? {});

    if (order.userUid !== user.uid) {
      throw new ExchangeError(403, "Oferta pertence a outro usuario.");
    }

    if (
      order.status !== ORDER_STATUS.open &&
      order.status !== ORDER_STATUS.partial
    ) {
      throw new ExchangeError(
        400,
        "Apenas ofertas abertas ou parciais podem ser canceladas.",
      );
    }

    if (order.remainingQuantity <= 0) {
      throw new ExchangeError(
        400,
        "Oferta sem quantidade restante para cancelar.",
      );
    }

    if (order.type === ORDER_TYPES.buy) {
      await releaseBuyOrderBalance(transaction, order);
    } else {
      await releaseSellOrderAssets(transaction, order);
    }

    transaction.update(orderRef, {
      status: ORDER_STATUS.cancelled,
      atualizado_em: fieldValue.serverTimestamp(),
    });
  });

  return {
    oferta_id: orderId,
    status: ORDER_STATUS.cancelled,
    quantidade_restante: 0,
  };
}

async function createBuyOrder(
  user: AuthenticatedExchangeUser,
  input: CreateOrderInput,
): Promise<CreatedOrderResponse> {
  const totalAmountCents = calculateTotalCents(
    input.quantity,
    input.unitPriceCents,
  );
  const orderRef = db.collection(EXCHANGE_COLLECTIONS.orders).doc();

  await db.runTransaction(async (transaction) => {
    const startup = await loadActiveStartup(transaction, input.startupId);
    validatePriceRange(input.unitPriceCents, startup.referencePriceCents);

    const userRef = db.collection(EXCHANGE_COLLECTIONS.users).doc(user.uid);
    const wallet = await loadWallet(transaction, userRef);
    validateAvailableBalance(wallet, totalAmountCents);

    transaction.update(userRef, {
      saldo_disponivel_centavos:
        wallet.availableBalanceCents - totalAmountCents,
      saldo_bloqueado_centavos:
        wallet.blockedBalanceCents + totalAmountCents,
      atualizado_em: fieldValue.serverTimestamp(),
    });
    transaction.set(orderRef, buildOrderDocument(user, input, startup.id));
  });

  const match = await executeOrderMatching(orderRef.id);

  return {
    oferta_id: orderRef.id,
    tipo: ORDER_TYPES.buy,
    startup_id: input.startupId,
    quantidade_original: input.quantity,
    quantidade_restante: match.quantidade_restante,
    valor_unitario_centavos: input.unitPriceCents,
    status: match.status,
    quantidade_executada: match.quantidade_executada,
    transacoes_executadas: match.transacoes_executadas,
  };
}

async function createSellOrder(
  user: AuthenticatedExchangeUser,
  input: CreateOrderInput,
): Promise<CreatedOrderResponse> {
  const orderRef = db.collection(EXCHANGE_COLLECTIONS.orders).doc();

  await db.runTransaction(async (transaction) => {
    const startup = await loadActiveStartup(transaction, input.startupId);
    validatePriceRange(input.unitPriceCents, startup.referencePriceCents);

    const assetRef = userAssetRef(user.uid, startup.id);
    const asset = await loadAsset(transaction, assetRef);
    validateAvailableAssets(asset, input.quantity);

    transaction.set(assetRef, {
      startup_id: startup.id,
      quantidade_disponivel: asset.availableQuantity - input.quantity,
      quantidade_bloqueada: asset.blockedQuantity + input.quantity,
      valor_medio_centavos: asset.averagePriceCents,
      atualizado_em: fieldValue.serverTimestamp(),
    }, {merge: true});
    transaction.set(orderRef, buildOrderDocument(user, input, startup.id));
  });

  const match = await executeOrderMatching(orderRef.id);

  return {
    oferta_id: orderRef.id,
    tipo: ORDER_TYPES.sell,
    startup_id: input.startupId,
    quantidade_original: input.quantity,
    quantidade_restante: match.quantidade_restante,
    valor_unitario_centavos: input.unitPriceCents,
    status: match.status,
    quantidade_executada: match.quantidade_executada,
    transacoes_executadas: match.transacoes_executadas,
  };
}

async function loadActiveStartup(
  transaction: Transaction,
  startupId: string,
): Promise<StartupPriceReference> {
  const startupRef = db
    .collection(EXCHANGE_COLLECTIONS.startups)
    .doc(startupId);
  const doc = await transaction.get(startupRef);
  const startup = loadActiveStartupFromData(startupId, doc);
  const pricePatch = buildStartupPriceInitializationPatch(
    startup.rawData,
    startup.prices,
  );

  if (Object.keys(pricePatch).length > 0) {
    transaction.update(startupRef, {
      ...pricePatch,
      atualizado_em: fieldValue.serverTimestamp(),
    });
  }

  return startup;
}

function loadActiveStartupFromData(
  startupId: string,
  doc: DocumentSnapshot,
): LoadedStartupPriceReference {
  if (!doc.exists) {
    throw new ExchangeError(404, "Startup nao encontrada.", "startup_id");
  }

  const rawData = doc.data() ?? {};

  if (String(rawData.status ?? "") !== "ativa") {
    throw new ExchangeError(404, "Startup nao encontrada.", "startup_id");
  }

  const prices = getStartupMarketPrices(rawData);

  return {
    id: startupId,
    referencePriceCents: prices.currentPriceCents,
    prices,
    rawData,
  };
}

async function loadWallet(
  transaction: Transaction,
  userRef: DocumentReference,
): Promise<WalletBalance> {
  const doc = await transaction.get(userRef);

  if (!doc.exists) {
    throw new ExchangeError(404, "Usuario nao encontrado.");
  }

  const data = doc.data() ?? {};

  return {
    availableBalanceCents: readNonNegativeInteger(
      data.saldo_disponivel_centavos,
    ),
    blockedBalanceCents: readNonNegativeInteger(
      data.saldo_bloqueado_centavos,
    ),
  };
}

async function loadAsset(
  transaction: Transaction,
  assetRef: DocumentReference,
): Promise<UserAssetBalance> {
  const doc = await transaction.get(assetRef);
  const data = doc.exists ? doc.data() ?? {} : {};

  return {
    availableQuantity: readNonNegativeInteger(data.quantidade_disponivel),
    blockedQuantity: readNonNegativeInteger(data.quantidade_bloqueada),
    averagePriceCents: readNonNegativeInteger(data.valor_medio_centavos),
  };
}

async function releaseBuyOrderBalance(
  transaction: Transaction,
  order: CancellationOrder,
): Promise<void> {
  const userRef = db.collection(EXCHANGE_COLLECTIONS.users).doc(order.userUid);
  const userDoc = await transaction.get(userRef);

  if (!userDoc.exists) {
    throw new ExchangeError(409, "Usuario da oferta nao encontrado.");
  }

  const wallet = {
    availableBalanceCents: readNonNegativeInteger(
      userDoc.data()?.saldo_disponivel_centavos,
    ),
    blockedBalanceCents: readNonNegativeInteger(
      userDoc.data()?.saldo_bloqueado_centavos,
    ),
  };
  const releasedAmount = order.remainingQuantity * order.unitPriceCents;

  if (wallet.blockedBalanceCents < releasedAmount) {
    throw new ExchangeError(
      409,
      "Saldo bloqueado inconsistente para cancelar a oferta.",
    );
  }

  transaction.update(userRef, {
    saldo_disponivel_centavos:
      wallet.availableBalanceCents + releasedAmount,
    saldo_bloqueado_centavos:
      wallet.blockedBalanceCents - releasedAmount,
    atualizado_em: fieldValue.serverTimestamp(),
  });
}

async function releaseSellOrderAssets(
  transaction: Transaction,
  order: CancellationOrder,
): Promise<void> {
  const assetRef = userAssetRef(order.userUid, order.startupId);
  const asset = await loadAsset(transaction, assetRef);

  if (asset.blockedQuantity < order.remainingQuantity) {
    throw new ExchangeError(
      409,
      "Tokens bloqueados inconsistentes para cancelar a oferta.",
    );
  }

  transaction.set(assetRef, {
    startup_id: order.startupId,
    quantidade_disponivel: asset.availableQuantity + order.remainingQuantity,
    quantidade_bloqueada: asset.blockedQuantity - order.remainingQuantity,
    valor_medio_centavos: asset.averagePriceCents,
    atualizado_em: fieldValue.serverTimestamp(),
  }, {merge: true});
}

function buildOrderDocument(
  user: AuthenticatedExchangeUser,
  input: CreateOrderInput,
  startupId: string,
): ExchangeOrderDocument {
  const timestamp = fieldValue.serverTimestamp();

  return {
    tipo: input.type,
    usuario_uid: user.uid,
    startup_id: startupId,
    quantidade_original: input.quantity,
    quantidade_restante: input.quantity,
    valor_unitario_centavos: input.unitPriceCents,
    status: ORDER_STATUS.open,
    criado_em: timestamp,
    atualizado_em: timestamp,
  };
}

function buildCancellationOrder(data: Record<string, unknown>) {
  return {
    type: readOrderType(data.tipo),
    userUid: String(data.usuario_uid ?? ""),
    startupId: String(data.startup_id ?? ""),
    remainingQuantity: requireNonNegativeInteger(data.quantidade_restante),
    unitPriceCents: requirePositiveInteger(data.valor_unitario_centavos),
    status: readOrderStatus(data.status),
  };
}

function userAssetRef(uid: string, startupId: string) {
  return db
    .collection(EXCHANGE_COLLECTIONS.users)
    .doc(uid)
    .collection("ativos")
    .doc(startupId);
}

function calculateTotalCents(quantity: number, unitPriceCents: number) {
  const totalAmountCents = quantity * unitPriceCents;

  if (!Number.isSafeInteger(totalAmountCents)) {
    throw new ExchangeError(
      400,
      "Valor total da oferta ultrapassa o limite permitido.",
    );
  }

  return totalAmountCents;
}

function calculateAveragePriceCents(
  currentQuantity: number,
  currentAveragePriceCents: number,
  boughtQuantity: number,
  unitPriceCents: number,
): number {
  const finalQuantity = currentQuantity + boughtQuantity;

  if (finalQuantity <= 0) {
    return 0;
  }

  return Math.round(
    (
      (currentQuantity * currentAveragePriceCents) +
      (boughtQuantity * unitPriceCents)
    ) / finalQuantity,
  );
}

function calculateAveragePriceAfterSell(
  currentQuantity: number,
  currentAveragePriceCents: number,
  soldQuantity: number,
): number {
  return currentQuantity - soldQuantity <= 0 ? 0 : currentAveragePriceCents;
}

interface CancellationOrder {
  type: OrderType;
  userUid: string;
  startupId: string;
  remainingQuantity: number;
  unitPriceCents: number;
  status: string;
}

interface LoadedStartupPriceReference extends StartupPriceReference {
  prices: StartupMarketPrices;
  rawData: Record<string, unknown>;
}
