// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Recebe a requisição HTTP de buscar carteira do usuário

import { onRequest } from "firebase-functions/v2/https";
import { handleCorsPreflight, sendJson } from "../../shared/http";
import { findWalletByUid } from "../repositories/walletRepository";

export const getWallet = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) return;

  if (req.method !== "GET") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const uid = req.query.uid;

  if (typeof uid !== "string" || uid.trim() === "") {
    return sendJson(res, 400, {
      success: false,
      message: "Parâmetro uid inválido ou ausente.",
    });
  }

  try {
    const wallet = await findWalletByUid(uid.trim());

    if (!wallet) {
      return sendJson(res, 404, {
        success: false,
        message: "Carteira não encontrada.",
      });
    }

    return sendJson(res, 200, {
      success: true,
      data: wallet,
    });
  } catch (error) {
    console.error("Erro ao buscar carteira:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao buscar carteira. Tente novamente.",
    });
  }
});