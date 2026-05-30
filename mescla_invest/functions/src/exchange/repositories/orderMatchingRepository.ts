// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import type {
  DocumentReference,
  DocumentSnapshot,
  QueryDocumentSnapshot,
  Transaction,
} from "firebase-admin/firestore";
import {db, fieldValue} from "../../shared/firebase";
import {
  buildStartupPriceInitializationPatch,
  calculateMarketImpactPricePreciseCents,
  getStartupMarketPrices,
  PRICE_PRECISION_SCALE,
  preciseCentsToDisplayCents,
} from "../../shared/startupPricing";
import type {StartupMarketPrices} from "../../shared/startupPricing";
import {
  EXCHANGE_COLLECTIONS,
  ExchangeOrderDocument,
  ExchangeTransactionDocument,
  MatchingResult,
  ORDER_STATUS,
  ORDER_TYPES,
  OrderStatus,
  OrderType,
  TRANSACTION_MARKETS,
} from "../types/exchangeTypes";
import {ExchangeError} from "../shared/exchangeErrors";
import {timestampToMillis} from "../shared/exchangeMappers";
import {
  readOrderType,
  requireNonNegativeInteger,
  requirePositiveInteger,
} from "../shared/exchangeParsing";
import {canExecuteOrder, readOrderStatus} from "../shared/exchangeValidation";

const MAX_MATCH_CANDIDATES = 100;
const MAX_TRANSACTIONS_PER_MATCH = 20;

export async function executeOrderMatching(
  orderId: string,
): Promise<MatchingResult> {
  return db.runTransaction(async (transaction) => {
    const orderRef = db.collection(EXCHANGE_COLLECTIONS.orders).doc(orderId);
    const orderDoc = await transaction.get(orderRef);

    if (!orderDoc.exists) {
      throw new ExchangeError(404, "Oferta nao encontrada.");
    }

    const primaryOrder = buildMatchingOrder(orderDoc);

    if (!isOrderExecutable(primaryOrder)) {
      return buildMatchingResult(primaryOrder, 0, 0);
    }

    const candidatesSnapshot = await transaction.get(
      db
        .collection(EXCHANGE_COLLECTIONS.orders)
        .where("startup_id", "==", primaryOrder.startupId)
        .limit(MAX_MATCH_CANDIDATES),
    );
    const candidates = candidatesSnapshot.docs
      .map(buildMatchingOrder)
      .filter((order) => order.id !== primaryOrder.id)
      .filter(isOrderExecutable)
      .filter((order) => order.type !== primaryOrder.type)
      .filter((order) => order.userUid !== primaryOrder.userUid)
      .filter((order) => isPriceCompatible(primaryOrder, order))
      .sort((first, second) => comparePriority(
        primaryOrder.type,
        first,
        second,
      ));
    const selectedOrders = selectOrdersForExecution(primaryOrder, candidates);

    if (selectedOrders.length === 0) {
      return buildMatchingResult(primaryOrder, 0, 0);
    }

    const users = await loadUsers(transaction, primaryOrder, selectedOrders);
    const assets = await loadAssets(transaction, primaryOrder, selectedOrders);
    const marketState = await loadStartupMarketState(
      transaction,
      primaryOrder.startupId,
    );
    const orders = new Map<string, MatchingOrder>([
      [primaryOrder.id, {...primaryOrder}],
      ...selectedOrders.map((order) => {
        return [order.id, {...order}] as const;
      }),
    ]);
    const transactions = settleOrders(
      primaryOrder,
      selectedOrders,
      orders,
      users,
      assets,
    );
    const executedQuantity = totalExecutedQuantity(transactions);
    const priceUpdate = buildStartupPriceUpdate(
      marketState,
      primaryOrder.type,
      executedQuantity,
    );

    writeUsers(transaction, users);
    writeAssets(transaction, assets);
    writeOrders(transaction, orders);
    writeTransactions(
      transaction,
      primaryOrder.startupId,
      transactions,
      priceUpdate,
    );
    updateStartupPrice(transaction, marketState, priceUpdate);

    const finalOrder = orders.get(primaryOrder.id) ?? primaryOrder;

    return buildMatchingResult(
      finalOrder,
      primaryOrder.remainingQuantity - finalOrder.remainingQuantity,
      transactions.length,
    );
  });
}

function buildMatchingOrder(
  doc: QueryDocumentSnapshot | DocumentSnapshot,
): MatchingOrder {
  const data = doc.data() as Partial<ExchangeOrderDocument> | undefined;

  if (!data) {
    throw new ExchangeError(404, "Oferta nao encontrada.");
  }

  return {
    id: doc.id,
    ref: doc.ref,
    type: readOrderType(data.tipo),
    userUid: String(data.usuario_uid ?? ""),
    startupId: String(data.startup_id ?? ""),
    originalQuantity: requirePositiveInteger(data.quantidade_original),
    remainingQuantity: requireNonNegativeInteger(data.quantidade_restante),
    unitPriceCents: requirePositiveInteger(data.valor_unitario_centavos),
    status: readOrderStatus(data.status),
    createdAtMs: timestampToMillis(data.criado_em),
  };
}

function isOrderExecutable(order: MatchingOrder) {
  return canExecuteOrder(order.status, order.remainingQuantity);
}

function isPriceCompatible(
  primary: MatchingOrder,
  candidate: MatchingOrder,
) {
  if (primary.type === ORDER_TYPES.buy) {
    return candidate.unitPriceCents <= primary.unitPriceCents;
  }

  return candidate.unitPriceCents >= primary.unitPriceCents;
}

function comparePriority(
  primaryType: OrderType,
  first: MatchingOrder,
  second: MatchingOrder,
) {
  const priceDifference = primaryType === ORDER_TYPES.buy ?
    first.unitPriceCents - second.unitPriceCents :
    second.unitPriceCents - first.unitPriceCents;

  if (priceDifference !== 0) {
    return priceDifference;
  }

  return first.createdAtMs - second.createdAtMs;
}

function selectOrdersForExecution(
  primary: MatchingOrder,
  candidates: MatchingOrder[],
) {
  const selected: MatchingOrder[] = [];
  let remainingQuantity = primary.remainingQuantity;

  for (const candidate of candidates) {
    if (remainingQuantity <= 0) break;
    if (selected.length >= MAX_TRANSACTIONS_PER_MATCH) break;

    selected.push(candidate);
    remainingQuantity -= Math.min(
      remainingQuantity,
      candidate.remainingQuantity,
    );
  }

  return selected;
}

async function loadUsers(
  transaction: Transaction,
  primary: MatchingOrder,
  candidates: MatchingOrder[],
) {
  const uids = new Set<string>([
    primary.userUid,
    ...candidates.map((order) => order.userUid),
  ]);
  const users = new Map<string, UserState>();

  for (const uid of uids) {
    const ref = db.collection(EXCHANGE_COLLECTIONS.users).doc(uid);
    const doc = await transaction.get(ref);

    if (!doc.exists) {
      throw new ExchangeError(409, "Usuario da oferta nao encontrado.");
    }

    const data = doc.data() ?? {};
    users.set(uid, {
      ref,
      availableBalanceCents: requireNonNegativeInteger(
        data.saldo_disponivel_centavos,
      ),
      blockedBalanceCents: requireNonNegativeInteger(
        data.saldo_bloqueado_centavos,
      ),
    });
  }

  return users;
}

async function loadAssets(
  transaction: Transaction,
  primary: MatchingOrder,
  candidates: MatchingOrder[],
) {
  const assets = new Map<string, AssetState>();
  const uids = new Set<string>([
    primary.userUid,
    ...candidates.map((order) => order.userUid),
  ]);

  for (const uid of uids) {
    const ref = db
      .collection(EXCHANGE_COLLECTIONS.users)
      .doc(uid)
      .collection("ativos")
      .doc(primary.startupId);
    const doc = await transaction.get(ref);
    const data = doc.exists ? doc.data() ?? {} : {};
    const averagePriceCents = requireNonNegativeInteger(
      data.valor_medio_centavos,
    );
    const averagePricePreciseCents = requireNonNegativeInteger(
      data.valor_medio_preciso_centavos,
    );

    assets.set(buildAssetKey(uid, primary.startupId), {
      ref,
      startupId: primary.startupId,
      availableQuantity: requireNonNegativeInteger(
        data.quantidade_disponivel,
      ),
      blockedQuantity: requireNonNegativeInteger(data.quantidade_bloqueada),
      averagePriceCents,
      averagePricePreciseCents: averagePricePreciseCents > 0 ?
        averagePricePreciseCents :
        averagePriceCents * PRICE_PRECISION_SCALE,
    });
  }

  return assets;
}

function settleOrders(
  primary: MatchingOrder,
  candidates: MatchingOrder[],
  orders: Map<string, MatchingOrder>,
  users: Map<string, UserState>,
  assets: Map<string, AssetState>,
) {
  const pendingTransactions: PendingTransaction[] = [];
  const primaryOrder = getOrder(orders, primary.id);

  for (const originalCandidate of candidates) {
    if (primaryOrder.remainingQuantity <= 0) break;

    const candidate = getOrder(orders, originalCandidate.id);
    const executedQuantity = Math.min(
      primaryOrder.remainingQuantity,
      candidate.remainingQuantity,
    );

    if (executedQuantity <= 0) continue;

    const buyOrder = primaryOrder.type === ORDER_TYPES.buy ?
      primaryOrder :
      candidate;
    const sellOrder = primaryOrder.type === ORDER_TYPES.sell ?
      primaryOrder :
      candidate;
    const unitPriceCents = candidate.unitPriceCents;

    settleTransfer({
      buyOrder,
      sellOrder,
      executedQuantity,
      unitPriceCents,
      users,
      assets,
    });

    primaryOrder.remainingQuantity -= executedQuantity;
    candidate.remainingQuantity -= executedQuantity;
    primaryOrder.status = calculateOrderStatus(primaryOrder);
    candidate.status = calculateOrderStatus(candidate);
    pendingTransactions.push({
      buyerUid: buyOrder.userUid,
      sellerUid: sellOrder.userUid,
      buyOrderId: buyOrder.id,
      sellOrderId: sellOrder.id,
      quantity: executedQuantity,
      unitPriceCents,
      totalAmountCents: executedQuantity * unitPriceCents,
    });
  }

  return pendingTransactions;
}

function settleTransfer(params: TransferParams): void {
  const buyer = getUser(params.users, params.buyOrder.userUid);
  const seller = getUser(params.users, params.sellOrder.userUid);
  const buyerAsset = getAsset(
    params.assets,
    params.buyOrder.userUid,
    params.buyOrder.startupId,
  );
  const sellerAsset = getAsset(
    params.assets,
    params.sellOrder.userUid,
    params.sellOrder.startupId,
  );
  const blockedBuyAmount =
    params.executedQuantity * params.buyOrder.unitPriceCents;
  const executedAmount = params.executedQuantity * params.unitPriceCents;
  const buyDifference = blockedBuyAmount - executedAmount;

  ensureBlockedBalance(buyer, blockedBuyAmount);
  ensureBlockedAssets(sellerAsset, params.executedQuantity);

  buyer.blockedBalanceCents -= blockedBuyAmount;
  buyer.availableBalanceCents += buyDifference;
  seller.availableBalanceCents += executedAmount;
  sellerAsset.blockedQuantity -= params.executedQuantity;
  updateBuyerAsset(
    buyerAsset,
    params.executedQuantity,
    params.unitPriceCents,
  );
}

function updateBuyerAsset(
  asset: AssetState,
  boughtQuantity: number,
  unitPriceCents: number,
): void {
  const currentQuantity = asset.availableQuantity + asset.blockedQuantity;
  const finalQuantity = currentQuantity + boughtQuantity;

  if (finalQuantity <= 0) {
    asset.averagePriceCents = 0;
    asset.averagePricePreciseCents = 0;
  } else {
    asset.averagePricePreciseCents = Math.round(
      (
        (currentQuantity * asset.averagePricePreciseCents) +
        (boughtQuantity * unitPriceCents * PRICE_PRECISION_SCALE)
      ) / finalQuantity,
    );
    asset.averagePriceCents = preciseCentsToDisplayCents(
      asset.averagePricePreciseCents,
    );
  }

  asset.availableQuantity += boughtQuantity;
}

function writeUsers(
  transaction: Transaction,
  users: Map<string, UserState>,
): void {
  users.forEach((user) => {
    transaction.update(user.ref, {
      saldo_disponivel_centavos: user.availableBalanceCents,
      saldo_bloqueado_centavos: user.blockedBalanceCents,
      atualizado_em: fieldValue.serverTimestamp(),
    });
  });
}

function writeAssets(
  transaction: Transaction,
  assets: Map<string, AssetState>,
): void {
  assets.forEach((asset) => {
    transaction.set(asset.ref, {
      startup_id: asset.startupId,
      quantidade_disponivel: asset.availableQuantity,
      quantidade_bloqueada: asset.blockedQuantity,
      valor_medio_centavos: asset.averagePriceCents,
      valor_medio_preciso_centavos: asset.averagePricePreciseCents,
      atualizado_em: fieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

function writeOrders(
  transaction: Transaction,
  orders: Map<string, MatchingOrder>,
): void {
  orders.forEach((order) => {
    transaction.update(order.ref, {
      quantidade_restante: order.remainingQuantity,
      status: order.status,
      atualizado_em: fieldValue.serverTimestamp(),
    });
  });
}

function writeTransactions(
  transaction: Transaction,
  startupId: string,
  transactions: PendingTransaction[],
  priceUpdate: StartupPriceUpdate | null,
): void {
  transactions.forEach((pendingTransaction) => {
    const transactionRef = db
      .collection(EXCHANGE_COLLECTIONS.transactions)
      .doc();
    const record: ExchangeTransactionDocument = {
      mercado: TRANSACTION_MARKETS.secondary,
      comprador_uid: pendingTransaction.buyerUid,
      vendedor_uid: pendingTransaction.sellerUid,
      startup_id: startupId,
      oferta_compra_id: pendingTransaction.buyOrderId,
      oferta_venda_id: pendingTransaction.sellOrderId,
      quantidade: pendingTransaction.quantity,
      valor_unitario_centavos: pendingTransaction.unitPriceCents,
      valor_total_centavos: pendingTransaction.totalAmountCents,
      valor_unitario_preciso_centavos:
        pendingTransaction.unitPriceCents * PRICE_PRECISION_SCALE,
      valor_total_preciso_centavos:
        pendingTransaction.totalAmountCents * PRICE_PRECISION_SCALE,
      ...(priceUpdate ? {
        preco_mercado_anterior_centavos: priceUpdate.previousPriceCents,
        preco_mercado_atual_centavos: priceUpdate.nextPriceCents,
        preco_mercado_anterior_preciso_centavos:
          priceUpdate.previousPricePreciseCents,
        preco_mercado_atual_preciso_centavos:
          priceUpdate.nextPricePreciseCents,
      } : {}),
      criado_em: fieldValue.serverTimestamp(),
    };

    transaction.set(transactionRef, record);
  });
}

async function loadStartupMarketState(
  transaction: Transaction,
  startupId: string,
): Promise<StartupMarketState> {
  const ref = db.collection(EXCHANGE_COLLECTIONS.startups).doc(startupId);
  const doc = await transaction.get(ref);

  if (!doc.exists) {
    throw new ExchangeError(404, "Startup nao encontrada.");
  }

  const hasTransactions = await hasStartupTransactions(transaction, startupId);
  const rawData = doc.data() ?? {};

  return {
    ref,
    rawData,
    prices: getStartupMarketPrices(rawData, {hasTransactions}),
    hasTransactions,
  };
}

async function hasStartupTransactions(
  transaction: Transaction,
  startupId: string,
) {
  const snapshot = await transaction.get(
    db
      .collection(EXCHANGE_COLLECTIONS.transactions)
      .where("startup_id", "==", startupId)
      .limit(1),
  );

  return !snapshot.empty;
}

function buildStartupPriceUpdate(
  marketState: StartupMarketState,
  aggressorType: OrderType,
  executedQuantity: number,
): StartupPriceUpdate | null {
  if (executedQuantity <= 0) return null;

  const nextPricePreciseCents = calculateMarketImpactPricePreciseCents(
    marketState.prices.currentPricePreciseCents,
    executedQuantity,
    marketState.prices.totalTokens,
    aggressorType,
  );
  const nextPriceCents = preciseCentsToDisplayCents(nextPricePreciseCents);

  return {
    previousPriceCents: marketState.prices.currentPriceCents,
    previousPricePreciseCents: marketState.prices.currentPricePreciseCents,
    nextPriceCents,
    nextPricePreciseCents,
  };
}

function updateStartupPrice(
  transaction: Transaction,
  marketState: StartupMarketState,
  priceUpdate: StartupPriceUpdate | null,
): void {
  if (!priceUpdate) return;

  const pricePatch = buildStartupPriceInitializationPatch(
    marketState.rawData,
    marketState.prices,
    {hasTransactions: marketState.hasTransactions},
  );

  transaction.update(marketState.ref, {
    ...pricePatch,
    preco_atual_centavos: priceUpdate.nextPriceCents,
    preco_atual_preciso_centavos: priceUpdate.nextPricePreciseCents,
    atualizado_em: fieldValue.serverTimestamp(),
  });
}

function totalExecutedQuantity(transactions: PendingTransaction[]) {
  return transactions.reduce((total, item) => {
    return total + item.quantity;
  }, 0);
}

function calculateOrderStatus(order: MatchingOrder): OrderStatus {
  if (order.remainingQuantity <= 0) {
    return ORDER_STATUS.executed;
  }

  if (order.remainingQuantity < order.originalQuantity) {
    return ORDER_STATUS.partial;
  }

  return ORDER_STATUS.open;
}

function buildMatchingResult(
  order: MatchingOrder,
  executedQuantity: number,
  totalTransactions: number,
): MatchingResult {
  return {
    status: order.status,
    quantidade_restante: order.remainingQuantity,
    quantidade_executada: executedQuantity,
    transacoes_executadas: totalTransactions,
  };
}

function getOrder(
  orders: Map<string, MatchingOrder>,
  orderId: string,
): MatchingOrder {
  const order = orders.get(orderId);

  if (!order) {
    throw new ExchangeError(409, "Oferta inconsistente durante a liquidacao.");
  }

  return order;
}

function getUser(
  users: Map<string, UserState>,
  uid: string,
): UserState {
  const user = users.get(uid);

  if (!user) {
    throw new ExchangeError(409, "Usuario inconsistente durante a liquidacao.");
  }

  return user;
}

function getAsset(
  assets: Map<string, AssetState>,
  uid: string,
  startupId: string,
): AssetState {
  const asset = assets.get(buildAssetKey(uid, startupId));

  if (!asset) {
    throw new ExchangeError(409, "Ativo inconsistente durante a liquidacao.");
  }

  return asset;
}

function ensureBlockedBalance(
  user: UserState,
  requiredAmountCents: number,
): void {
  if (user.blockedBalanceCents < requiredAmountCents) {
    throw new ExchangeError(
      409,
      "Saldo bloqueado inconsistente para liquidar a oferta.",
    );
  }
}

function ensureBlockedAssets(
  asset: AssetState,
  requiredQuantity: number,
): void {
  if (asset.blockedQuantity < requiredQuantity) {
    throw new ExchangeError(
      409,
      "Tokens bloqueados inconsistentes para liquidar a oferta.",
    );
  }
}

function buildAssetKey(uid: string, startupId: string): string {
  return `${uid}:${startupId}`;
}

interface MatchingOrder {
  id: string;
  ref: DocumentReference;
  type: OrderType;
  userUid: string;
  startupId: string;
  originalQuantity: number;
  remainingQuantity: number;
  unitPriceCents: number;
  status: OrderStatus;
  createdAtMs: number;
}

interface UserState {
  ref: DocumentReference;
  availableBalanceCents: number;
  blockedBalanceCents: number;
}

interface AssetState {
  ref: DocumentReference;
  startupId: string;
  availableQuantity: number;
  blockedQuantity: number;
  averagePriceCents: number;
  averagePricePreciseCents: number;
}

interface PendingTransaction {
  buyerUid: string;
  sellerUid: string;
  buyOrderId: string;
  sellOrderId: string;
  quantity: number;
  unitPriceCents: number;
  totalAmountCents: number;
}

interface TransferParams {
  buyOrder: MatchingOrder;
  sellOrder: MatchingOrder;
  executedQuantity: number;
  unitPriceCents: number;
  users: Map<string, UserState>;
  assets: Map<string, AssetState>;
}

interface StartupMarketState {
  ref: DocumentReference;
  rawData: Record<string, unknown>;
  prices: StartupMarketPrices;
  hasTransactions: boolean;
}

interface StartupPriceUpdate {
  previousPriceCents: number;
  previousPricePreciseCents: number;
  nextPriceCents: number;
  nextPricePreciseCents: number;
}
