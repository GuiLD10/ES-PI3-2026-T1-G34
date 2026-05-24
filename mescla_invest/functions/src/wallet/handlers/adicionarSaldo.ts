// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição HTTP para adicionar saldo à carteira do usuário

import { onRequest } from "firebase-functions/v2/https";
import { handleCorsPreflight, sendJson } from "../../shared/http";
import { adicionarSaldoDisponivel } from "../repositories/walletRepository";

interface AdicionarSaldoBody {
  uid: string;
  valor: number;
}

export const adicionarSaldo = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) return;

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  try {
    const { uid, valor } = req.body as AdicionarSaldoBody;

    if (typeof uid !== "string" || uid.trim() === "") {
      return sendJson(res, 400, {
        success: false,
        message: "Parâmetro uid inválido ou ausente.",
      });
    }

    if (typeof valor !== "number" || valor <= 0) {
      return sendJson(res, 400, {
        success: false,
        message: "O valor deve ser um número positivo.",
      });
    }

    await adicionarSaldoDisponivel(uid.trim(), valor);

    return sendJson(res, 200, {
      success: true,
      message: "Saldo adicionado com sucesso.",
    });
  } catch (error) {
    console.error("Erro ao adicionar saldo:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao adicionar saldo. Tente novamente.",
    });
  }
});
