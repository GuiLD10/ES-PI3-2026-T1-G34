// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descricao: Recebe a requisicao HTTP para adicionar saldo a carteira

import {onRequest} from "firebase-functions/v2/https";
import {auth} from "../../shared/firebase";
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
    const uid = await authenticateUser(req.headers.authorization);
    const valorCentavos = parseValorCentavos(req.body?.valor);
    const updated = await adicionarSaldoDisponivel(uid, valorCentavos);

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
    if (error instanceof WalletRequestError) {
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

async function authenticateUser(
  authorizationHeader: string | string[] | undefined,
): Promise<string> {
  const header = Array.isArray(authorizationHeader) ?
    authorizationHeader[0] :
    authorizationHeader;

  if (!header) {
    throw new WalletRequestError(401, "Token de autenticacao nao informado.");
  }

  const [type, token] = header.trim().split(/\s+/);

  if (type !== "Bearer" || !token) {
    throw new WalletRequestError(401, "Token de autenticacao invalido.");
  }

  try {
    const decodedToken = await auth.verifyIdToken(token);
    return decodedToken.uid;
  } catch {
    throw new WalletRequestError(
      401,
      "Token de autenticacao expirado ou invalido.",
    );
  }
}

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
