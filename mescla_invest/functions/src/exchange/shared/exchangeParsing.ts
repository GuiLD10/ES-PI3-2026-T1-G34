// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import {
  CreateOrderInput,
  MarketBuyInput,
  MarketSellInput,
  ORDER_TYPES,
  OrderType,
} from "../types/exchangeTypes";
import {ExchangeError} from "./exchangeErrors";
import {validateOrderType, validateQuantity} from "./exchangeValidation";

export function normalizeId(
  value: unknown,
  field: string,
  message = "Identificador obrigatorio.",
): string {
  const id = typeof value === "string" ? value.trim() : "";

  if (!id) {
    throw new ExchangeError(400, message, field);
  }

  return id;
}

export function parseCreateOrderInput(body: unknown): CreateOrderInput {
  const data = isRecord(body) ? body : {};

  return {
    type: validateOrderType(data.tipo),
    startupId: normalizeId(data.startup_id, "startup_id"),
    quantity: validateQuantity(data.quantidade),
    unitPriceCents: parseMoneyToCents(data.valor_unitario),
  };
}

export function parseCancelOrderInput(body: unknown): string {
  const data = isRecord(body) ? body : {};
  return normalizeId(data.oferta_id, "oferta_id");
}

export function parseMarketBuyInput(body: unknown): MarketBuyInput {
  return parseMarketTradeInput(body);
}

export function parseMarketSellInput(body: unknown): MarketSellInput {
  return parseMarketTradeInput(body);
}

function parseMarketTradeInput(body: unknown) {
  const data = isRecord(body) ? body : {};

  return {
    startupId: normalizeId(data.startup_id, "startup_id"),
    quantity: validateQuantity(data.quantidade),
  };
}

export function parseQueryStartupId(value: unknown): string {
  return normalizeId(
    value,
    "startup_id",
    "Parametro startupId invalido ou ausente.",
  );
}

export function parseMoneyToCents(
  value: unknown,
  field = "valor_unitario",
): number {
  const numberValue = typeof value === "string" ?
    Number(value.replace(",", ".")) :
    Number(value);

  if (!Number.isFinite(numberValue)) {
    throw new ExchangeError(400, "Valor monetario invalido.", field);
  }

  const cents = Math.round(numberValue * 100);

  if (!Number.isSafeInteger(cents) || cents <= 0) {
    throw new ExchangeError(
      400,
      "Valor monetario deve ser maior que zero.",
      field,
    );
  }

  return cents;
}

export function readNonNegativeInteger(value: unknown): number {
  const numberValue = Number(value ?? 0);

  if (!Number.isSafeInteger(numberValue) || numberValue < 0) {
    return 0;
  }

  return numberValue;
}

export function requirePositiveInteger(
  value: unknown,
  message = "Numero positivo esperado na oferta.",
): number {
  const numberValue = Number(value);

  if (!Number.isSafeInteger(numberValue) || numberValue <= 0) {
    throw new ExchangeError(409, message);
  }

  return numberValue;
}

export function requireNonNegativeInteger(
  value: unknown,
  message = "Numero nao negativo esperado na oferta.",
): number {
  const numberValue = Number(value ?? 0);

  if (!Number.isSafeInteger(numberValue) || numberValue < 0) {
    throw new ExchangeError(409, message);
  }

  return numberValue;
}

export function readOrderType(value: unknown): OrderType {
  if (value === ORDER_TYPES.buy || value === ORDER_TYPES.sell) {
    return value;
  }

  throw new ExchangeError(409, "Tipo de oferta inconsistente.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object";
}
