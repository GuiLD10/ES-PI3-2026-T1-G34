// Autor: Rafael Lanza de Queiroz
// RA: 22010825

export const DEFAULT_MARKET_PRICE_CENTS = 100;
export const PRICE_PRECISION_SCALE = 10000;

const MARKET_MAX_IMPACT_BPS = 500;

export const MARKET_IMPACT_DIRECTIONS = {
  buy: "compra",
  sell: "venda",
} as const;

export type MarketImpactDirection =
  (typeof MARKET_IMPACT_DIRECTIONS)[keyof typeof MARKET_IMPACT_DIRECTIONS];

export interface StartupMarketPrices {
  currentPriceCents: number;
  primaryPriceCents: number;
  currentPricePreciseCents: number;
  primaryPricePreciseCents: number;
  totalTokens: number;
}

export function getStartupMarketPrices(
  data: Record<string, unknown>,
): StartupMarketPrices {
  const storedCurrentPrice = readNonNegativeInteger(
    data.preco_atual_centavos,
  );
  const storedPrimaryPrice = readNonNegativeInteger(
    data.preco_primario_centavos,
  );
  const storedCurrentPrecisePrice = readNonNegativeInteger(
    data.preco_atual_preciso_centavos,
  );
  const storedPrimaryPrecisePrice = readNonNegativeInteger(
    data.preco_primario_preciso_centavos,
  );
  const primaryPriceCents = storedPrimaryPrice > 0 ?
    storedPrimaryPrice :
    calculateInitialMarketPriceCents(data);
  const primaryPricePreciseCents = storedPrimaryPrecisePrice > 0 ?
    storedPrimaryPrecisePrice :
    centsToPreciseCents(primaryPriceCents);
  const currentPricePreciseCents = storedCurrentPrecisePrice > 0 ?
    storedCurrentPrecisePrice :
    centsToPreciseCents(
      storedCurrentPrice > 0 ? storedCurrentPrice : primaryPriceCents,
    );
  const currentPriceCents = storedCurrentPrice > 0 ?
    storedCurrentPrice :
    preciseCentsToDisplayCents(currentPricePreciseCents);

  return {
    currentPriceCents,
    primaryPriceCents,
    currentPricePreciseCents,
    primaryPricePreciseCents,
    totalTokens: readNonNegativeInteger(data.tokens_emitidos),
  };
}

export function buildStartupPriceInitializationPatch(
  data: Record<string, unknown>,
  prices: StartupMarketPrices,
): Record<string, number> {
  const patch: Record<string, number> = {};

  if (readNonNegativeInteger(data.preco_primario_centavos) <= 0) {
    patch.preco_primario_centavos = prices.primaryPriceCents;
  }

  if (readNonNegativeInteger(data.preco_primario_preciso_centavos) <= 0) {
    patch.preco_primario_preciso_centavos = prices.primaryPricePreciseCents;
  }

  if (readNonNegativeInteger(data.preco_atual_centavos) <= 0) {
    patch.preco_atual_centavos = prices.currentPriceCents;
  }

  if (readNonNegativeInteger(data.preco_atual_preciso_centavos) <= 0) {
    patch.preco_atual_preciso_centavos = prices.currentPricePreciseCents;
  }

  return patch;
}

export function calculateMarketImpactPriceCents(
  currentPriceCents: number,
  quantity: number,
  totalTokens: number,
  direction: MarketImpactDirection,
): number {
  if (currentPriceCents <= 0) {
    return currentPriceCents;
  }

  return preciseCentsToDisplayCents(
    calculateMarketImpactPricePreciseCents(
      centsToPreciseCents(currentPriceCents),
      quantity,
      totalTokens,
      direction,
    ),
  );
}

export function calculateMarketImpactPricePreciseCents(
  currentPricePreciseCents: number,
  quantity: number,
  totalTokens: number,
  direction: MarketImpactDirection,
): number {
  if (
    currentPricePreciseCents <= 0 ||
    quantity <= 0 ||
    totalTokens <= 0
  ) {
    return currentPricePreciseCents;
  }

  const impactBps = Math.min(
    MARKET_MAX_IMPACT_BPS,
    Math.max(1, Math.ceil((quantity * 10000) / totalTokens)),
  );
  const multiplierBps = direction === MARKET_IMPACT_DIRECTIONS.buy ?
    10000 + impactBps :
    10000 - impactBps;

  return Math.max(
    PRICE_PRECISION_SCALE,
    Math.round((currentPricePreciseCents * multiplierBps) / 10000),
  );
}

export function centsToPreciseCents(priceCents: number): number {
  return Math.max(1, priceCents) * PRICE_PRECISION_SCALE;
}

export function preciseCentsToDisplayCents(pricePreciseCents: number): number {
  return Math.max(1, Math.round(pricePreciseCents / PRICE_PRECISION_SCALE));
}

function calculateInitialMarketPriceCents(
  data: Record<string, unknown>,
): number {
  const capitalReais = readNonNegativeInteger(data.capital_aportado);
  const tokens = readNonNegativeInteger(data.tokens_emitidos);

  if (capitalReais > 0 && tokens > 0) {
    return Math.max(1, Math.round((capitalReais * 100) / tokens));
  }

  return DEFAULT_MARKET_PRICE_CENTS;
}

function readNonNegativeInteger(value: unknown): number {
  const numberValue = Number(value ?? 0);

  if (!Number.isSafeInteger(numberValue) || numberValue < 0) {
    return 0;
  }

  return numberValue;
}
