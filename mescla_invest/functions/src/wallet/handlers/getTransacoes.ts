// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Recebe a requisição HTTP de buscar transações do usuário

import {onRequest} from "firebase-functions/v2/https";
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

  const uid = req.query.uid;

  if (typeof uid !== "string" || uid.trim() === "") {
    return sendJson(res, 400, {
      success: false,
      message: "Parametro uid invalido ou ausente.",
    });
  }

  try {
    const transacoes = await findTransacoesByUid(uid.trim());

    return sendJson(res, 200, {
      success: true,
      data: transacoes,
    });
  } catch (error) {
    console.error("Erro ao buscar transacoes:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao buscar transacoes. Tente novamente.",
    });
  }
});
