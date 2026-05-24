// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de buscar startup pelo id e trata ela
import { onRequest } from "firebase-functions/v2/https";
import { montarStartup } from "../shared/ResponseTools";
import { enviarJSON } from "../shared/ResponseTools";
import { buscarStartupPeloIDNoBanco } from "../repositories/GetStartupByIDRepositori";


export const handlerGetSturupByID =  onRequest(async (req, res) => {
  if (req.method !== "GET") {
    return enviarJSON(res, 405, {
      success: false,
      message: "Método não permitido."
    });
  }

  const startupId = req.query.startupId;

  if (typeof startupId !== "string") {
    return enviarJSON(res, 400, {
      success: false,
      message: "Parâmetro startupId inválido ou ausente."
    });
  }
  if (startupId.trim() === "") {
    return enviarJSON(res, 400, {
      success: false,
      message: "O ID da startup não pode estar vazio."
    });
  }
  
  try {
    const doc = await buscarStartupPeloIDNoBanco(startupId);

    if (!doc.exists) {
      console.log("teste do doc" + doc.data());
      return enviarJSON(res, 404, {
        success: false,
        message: 'Startup não encontrada.',
      });
    }

    const startup = montarStartup(doc);

    if (startup.status !== 'ativa') {
      return enviarJSON(res, 404, {
        success: false,
        message: 'Startup não encontrada.',
      });
    }

    return enviarJSON(res, 200, {
      success: true,
      data: startup,
    });
  } catch (error: unknown) {
    console.error('Erro ao buscar startup:', error);
    return enviarJSON(res, 500, {
      success: false,
      message: 'Erro interno ao buscar startup. Tente novamente.',
    });
  }
});