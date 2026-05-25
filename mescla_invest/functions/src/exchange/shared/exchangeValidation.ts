// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import {
  MAX_PRICE_PERCENT,
  MIN_PRICE_PERCENT,
  ORDER_STATUS,
  ORDER_TYPES,
  OrderStatus,
  OrderType,
  UserAssetBalance,
  WalletBalance,
} from "../types/exchangeTypes";
import {ExchangeError} from "./exchangeErrors";

export function validateOrderType(type: unknown): OrderType {
  if (type === ORDER_TYPES.buy || type === ORDER_TYPES.sell) {
    return type;
  }

  throw new ExchangeError(
    400,
    "Tipo de oferta deve ser compra ou venda.",
    "tipo",
  );
}

export function validateQuantity(quantity: unknown): number {
  const value = typeof quantity === "number" ?
    quantity :
    Number(quantity);

  if (!Number.isInteger(value) || value <= 0) {
    throw new ExchangeError(
      400,
      "Quantidade de tokens deve ser um numero inteiro positivo.",
      "quantidade",
    );
  }

  return value;
}

export function validatePriceRange(
  unitPriceCents: number,
  referencePriceCents: number,
): void {
  const minPrice = Math.max(
    1,
    Math.ceil((referencePriceCents * MIN_PRICE_PERCENT) / 100),
  );
  const maxPrice = Math.floor(
    (referencePriceCents * MAX_PRICE_PERCENT) / 100,
  );

  if (unitPriceCents < minPrice || unitPriceCents > maxPrice) {
    throw new ExchangeError(
      400,
      `Preco deve estar entre ${minPrice} e ${maxPrice} centavos.`,
      "valor_unitario",
    );
  }
}

export function validateAvailableBalance(
  wallet: WalletBalance,
  requiredAmountCents: number,
): void {
  if (wallet.availableBalanceCents < requiredAmountCents) {
    throw new ExchangeError(
      400,
      "Saldo disponivel insuficiente para criar a oferta.",
      "saldo",
    );
  }
}

export function validateAvailableAssets(
  asset: UserAssetBalance,
  requiredQuantity: number,
): void {
  if (asset.availableQuantity < requiredQuantity) {
    throw new ExchangeError(
      400,
      "Quantidade de tokens disponivel insuficiente para criar a oferta.",
      "quantidade",
    );
  }
}

export function readOrderStatus(value: unknown): OrderStatus {
  if (
    value === ORDER_STATUS.open ||
    value === ORDER_STATUS.partial ||
    value === ORDER_STATUS.executed ||
    value === ORDER_STATUS.cancelled
  ) {
    return value;
  }

  throw new ExchangeError(409, "Status de oferta inconsistente.");
}

export function canExecuteOrder(status: OrderStatus, remaining: number) {
  return (
    (status === ORDER_STATUS.open || status === ORDER_STATUS.partial) &&
    remaining > 0
  );
}
