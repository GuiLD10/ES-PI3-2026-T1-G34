// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de listar as startups e trata ela

import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {listActiveStartups} from "../repositories/startupRepository";
import {StartupData} from "../types/startupTypes";

export const listStartups = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "GET") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  try {
    const startups: StartupData[] = await listActiveStartups();

    return sendJson(res, 200, {
      success: true,
      data: startups,
    });
  } catch (error) {
    console.error("Erro ao listar startups:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao buscar startups. Tente novamente.",
    });
  }
});
