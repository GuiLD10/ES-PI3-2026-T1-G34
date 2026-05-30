// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Recebe a requisição HTTP de buscar transações do usuário

import {onRequest} from "firebase-functions/v2/https";
import {authenticateRequest, AuthRequestError} from "../../shared/auth";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {findTransacoesByUid} from "../repositories/walletRepository";

export const getTransacoes = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "GET") {
    return sendJson(res, 405, {
      success: false,
      message: "Metodo nao permitido.",
    });
  }

  try {
    const user = await authenticateRequest(req);
    const transacoes = await findTransacoesByUid(user.uid);

    return sendJson(res, 200, {
      success: true,
      data: transacoes,
    });
  } catch (error) {
    if (error instanceof AuthRequestError) {
      return sendJson(res, error.statusCode, {
        success: false,
        message: error.message,
      });
    }

    console.error("Erro ao buscar transacoes:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao buscar transacoes. Tente novamente.",
    });
  }
});
