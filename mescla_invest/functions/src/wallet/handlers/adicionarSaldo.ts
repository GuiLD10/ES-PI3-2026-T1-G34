// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descricao: Recebe a requisicao HTTP para adicionar saldo a carteira

import {onRequest} from "firebase-functions/v2/https";
import {authenticateRequest, AuthRequestError} from "../../shared/auth";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {
  adicionarSaldoDisponivel,
} from "../repositories/walletRepository";

export const adicionarSaldo = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Metodo nao permitido.",
    });
  }

  try {
    const user = await authenticateRequest(req);
    const valorCentavos = parseValorCentavos(req.body?.valor);
    const updated = await adicionarSaldoDisponivel(user.uid, valorCentavos);

    if (!updated) {
      return sendJson(res, 404, {
        success: false,
        message: "Carteira nao encontrada.",
      });
    }

    return sendJson(res, 200, {
      success: true,
      message: "Saldo adicionado com sucesso.",
    });
  } catch (error) {
    if (
      error instanceof WalletRequestError ||
      error instanceof AuthRequestError
    ) {
      return sendJson(res, error.statusCode, {
        success: false,
        message: error.message,
      });
    }

    console.error("Erro ao adicionar saldo:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao adicionar saldo. Tente novamente.",
    });
  }
});

function parseValorCentavos(value: unknown): number {
  const valor = typeof value === "string" ?
    Number(value.replace(",", ".")) :
    Number(value);

  if (!Number.isFinite(valor) || valor <= 0) {
    throw new WalletRequestError(
      400,
      "O valor deve ser um numero positivo.",
    );
  }

  const centavos = Math.round(valor * 100);

  if (!Number.isSafeInteger(centavos) || centavos <= 0) {
    throw new WalletRequestError(
      400,
      "O valor deve ser um numero positivo.",
    );
  }

  return centavos;
}

class WalletRequestError extends Error {
  readonly statusCode: number;

  constructor(statusCode: number, message: string) {
    super(message);
    this.name = "WalletRequestError";
    this.statusCode = statusCode;
  }
}
