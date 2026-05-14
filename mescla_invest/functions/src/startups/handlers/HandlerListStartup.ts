// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de listar as startups e trata ela
import { onRequest } from "firebase-functions/v2/https";
import { StartupData } from "../types/StartupInterfaces";
import { enviarJSON } from "../shared/ResponseTools";
import { buscarStartupsNoBanco } from "../repositories/ListStartupsRepositorie";

export const handlerListStartup = onRequest(async (req, res) => {
  // aceita apenas POST
  if (req.method !== "GET") {
    return enviarJSON(res, 405, {
      success: false,
      message: "Método não permitido."
    });
  }

  try {
    const startups: StartupData[] = await buscarStartupsNoBanco();

    return enviarJSON(res, 200, {
      success: true,
      data: startups,
    });  
  } catch (error) {
    console.error('Erro ao listar startups:', error);
    return enviarJSON(res, 500, {
      success: false,
      message: 'Erro interno ao buscar startups. Tente novamente.',
    });
  }
});