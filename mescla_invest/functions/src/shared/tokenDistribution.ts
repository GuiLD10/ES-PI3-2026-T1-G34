// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Regras de distribuicao dos tokens emitidos por startup.

export const TOKEN_DISTRIBUTION_PERCENTAGES = {
  partners: 30,
  mescla: 10,
  primarySale: 60,
} as const;

export interface StartupTokenDistribution {
  partnerTokensTotal: number;
  mesclaTokensTotal: number;
  primarySaleTokensTotal: number;
  primarySaleTokensAvailable: number;
}

export function calculateStartupTokenDistribution(
  data: Record<string, unknown>,
): StartupTokenDistribution {
  const totalTokens = readNonNegativeInteger(data.tokens_emitidos);
  const partnerTokensTotal = Math.floor(
    (totalTokens * TOKEN_DISTRIBUTION_PERCENTAGES.partners) / 100,
  );
  const primarySaleTokensTotal = Math.floor(
    (totalTokens * TOKEN_DISTRIBUTION_PERCENTAGES.primarySale) / 100,
  );
  const mesclaTokensTotal =
    totalTokens - partnerTokensTotal - primarySaleTokensTotal;
  const storedAvailable = readOptionalNonNegativeInteger(
    data.tokens_venda_disponiveis,
  );

  return {
    partnerTokensTotal,
    mesclaTokensTotal,
    primarySaleTokensTotal,
    primarySaleTokensAvailable: Math.min(
      storedAvailable ?? primarySaleTokensTotal,
      primarySaleTokensTotal,
    ),
  };
}

export function buildStartupTokenDistributionPatch(
  data: Record<string, unknown>,
  distribution = calculateStartupTokenDistribution(data),
): Record<string, number> {
  const patch: Record<string, number> = {};

  assignIfDifferent(
    patch,
    data,
    "tokens_socios_total",
    distribution.partnerTokensTotal,
  );
  assignIfDifferent(
    patch,
    data,
    "tokens_mescla_total",
    distribution.mesclaTokensTotal,
  );
  assignIfDifferent(
    patch,
    data,
    "tokens_venda_total",
    distribution.primarySaleTokensTotal,
  );

  if (
    readOptionalNonNegativeInteger(data.tokens_venda_disponiveis) === null ||
    readNonNegativeInteger(data.tokens_venda_disponiveis) >
      distribution.primarySaleTokensTotal
  ) {
    patch.tokens_venda_disponiveis =
      distribution.primarySaleTokensAvailable;
  }

  return patch;
}

function assignIfDifferent(
  patch: Record<string, number>,
  data: Record<string, unknown>,
  field: string,
  value: number,
) {
  if (readNonNegativeInteger(data[field]) !== value) {
    patch[field] = value;
  }
}

function readNonNegativeInteger(value: unknown): number {
  const numberValue = Number(value ?? 0);

  if (!Number.isSafeInteger(numberValue) || numberValue < 0) {
    return 0;
  }

  return numberValue;
}

function readOptionalNonNegativeInteger(value: unknown): number | null {
  if (value === null || value === undefined) {
    return null;
  }

  const numberValue = Number(value);

  if (!Number.isSafeInteger(numberValue) || numberValue < 0) {
    return null;
  }

  return numberValue;
}
