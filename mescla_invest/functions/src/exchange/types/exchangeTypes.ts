// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import type {FieldValue, Timestamp} from "firebase-admin/firestore";

export const EXCHANGE_COLLECTIONS = {
  orders: "ofertas",
  transactions: "transacoes",
  users: "usuarios",
  startups: "startups",
} as const;

export const ORDER_TYPES = {
  buy: "compra",
  sell: "venda",
} as const;

export const ORDER_STATUS = {
  open: "aberta",
  partial: "parcial",
  executed: "executada",
  cancelled: "cancelada",
} as const;

export const TRANSACTION_MARKETS = {
  primary: "primario",
  secondary: "secundario",
} as const;

export const MIN_PRICE_PERCENT = 50;
export const MAX_PRICE_PERCENT = 200;

export type OrderType = (typeof ORDER_TYPES)[keyof typeof ORDER_TYPES];
export type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS];
export type TransactionMarket =
  (typeof TRANSACTION_MARKETS)[keyof typeof TRANSACTION_MARKETS];
export type FirestoreTimestampField = Timestamp | FieldValue;

export interface AuthenticatedExchangeUser {
  uid: string;
  email?: string;
}

export interface CreateOrderInput {
  type: OrderType;
  startupId: string;
  quantity: number;
  unitPriceCents: number;
}

export interface MarketTradeInput {
  startupId: string;
  quantity: number;
}

export type MarketBuyInput = MarketTradeInput;

export type MarketSellInput = MarketTradeInput;

export interface ExchangeOrderDocument {
  tipo: OrderType;
  usuario_uid: string;
  startup_id: string;
  quantidade_original: number;
  quantidade_restante: number;
  valor_unitario_centavos: number;
  status: OrderStatus;
  criado_em: FirestoreTimestampField;
  atualizado_em: FirestoreTimestampField;
}

export interface ExchangeTransactionDocument {
  mercado: TransactionMarket;
  comprador_uid: string;
  vendedor_uid: string;
  startup_id: string;
  oferta_compra_id: string;
  oferta_venda_id: string;
  quantidade: number;
  valor_unitario_centavos: number;
  valor_total_centavos: number;
  valor_unitario_preciso_centavos?: number;
  valor_total_preciso_centavos?: number;
  preco_mercado_anterior_centavos?: number;
  preco_mercado_atual_centavos?: number;
  preco_mercado_anterior_preciso_centavos?: number;
  preco_mercado_atual_preciso_centavos?: number;
  criado_em: FirestoreTimestampField;
}

export interface ExchangeOrderResponse {
  oferta_id: string;
  tipo: OrderType;
  usuario_uid: string;
  startup_id: string;
  quantidade_original: number;
  quantidade_restante: number;
  valor_unitario_centavos: number;
  status: OrderStatus;
  criado_em: string | null;
  atualizado_em: string | null;
}

export interface OrderBookResponse {
  startup_id: string;
  preco_atual_centavos: number;
  melhor_compra: ExchangeOrderResponse | null;
  melhor_venda: ExchangeOrderResponse | null;
  compras: ExchangeOrderResponse[];
  vendas: ExchangeOrderResponse[];
}

export interface ExchangeTransactionResponse {
  transacao_id: string;
  mercado: string;
  comprador_uid: string;
  vendedor_uid: string;
  startup_id: string;
  oferta_compra_id: string;
  oferta_venda_id: string;
  quantidade: number;
  valor_unitario_centavos: number;
  valor_total_centavos: number;
  valor_unitario_preciso_centavos: number;
  valor_total_preciso_centavos: number;
  criado_em: string | null;
}

export interface CreatedOrderResponse {
  oferta_id: string;
  tipo: OrderType;
  startup_id: string;
  quantidade_original: number;
  quantidade_restante: number;
  valor_unitario_centavos: number;
  status: OrderStatus;
  quantidade_executada: number;
  transacoes_executadas: number;
}

export interface CancelledOrderResponse {
  oferta_id: string;
  status: typeof ORDER_STATUS.cancelled;
  quantidade_restante: number;
}

export interface MarketTradeResponse {
  startup_id: string;
  quantidade: number;
  valor_unitario_centavos: number;
  valor_total_centavos: number;
  valor_unitario_preciso_centavos: number;
  valor_total_preciso_centavos: number;
  preco_anterior_centavos: number;
  preco_atual_centavos: number;
  preco_anterior_preciso_centavos: number;
  preco_atual_preciso_centavos: number;
  transacao_id: string;
}

export type MarketBuyResponse = MarketTradeResponse;

export type MarketSellResponse = MarketTradeResponse;

export interface StartupPriceReference {
  id: string;
  referencePriceCents: number;
}

export interface WalletBalance {
  availableBalanceCents: number;
  blockedBalanceCents: number;
}

export interface UserAssetBalance {
  availableQuantity: number;
  blockedQuantity: number;
  averagePriceCents: number;
  averagePricePreciseCents: number;
}

export interface MatchingResult {
  status: OrderStatus;
  quantidade_restante: number;
  quantidade_executada: number;
  transacoes_executadas: number;
}
