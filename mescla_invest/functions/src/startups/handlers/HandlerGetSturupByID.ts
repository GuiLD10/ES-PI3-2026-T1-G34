import {onRequest} from "firebase-functions/v2/https";
import {montarStartup, enviarJSON} from "../shared/ResponseTools";
import {
  buscarStartupPeloIDNoBanco,
} from "../repositories/GetStartupByIDRepositori";


export const handlerGetSturupByID = onRequest(async (req, res) => {
  if (req.method !== "GET") {
    return enviarJSON(res, 405, {
      success: false,
      message: "MÃ©todo nÃ£o permitido.",
    });
  }

  const startupId = req.query.startupId;

  if (typeof startupId !== "string") {
    return enviarJSON(res, 400, {
      success: false,
      message: "ParÃ¢metro startupId invÃ¡lido ou ausente.",
    });
  }
  if (startupId.trim() === "") {
    return enviarJSON(res, 400, {
      success: false,
      message: "O ID da startup nÃ£o pode estar vazio.",
    });
  }

  try {
    const doc = await buscarStartupPeloIDNoBanco(startupId);

    if (!doc.exists) {
      console.log("teste do doc" + doc.data());
      return enviarJSON(res, 404, {
        success: false,
        message: "Startup nÃ£o encontrada.",
      });
    }

    const startup = montarStartup(doc);

    if (startup.status !== "ativa") {
      return enviarJSON(res, 404, {
        success: false,
        message: "Startup nÃ£o encontrada.",
      });
    }

    return enviarJSON(res, 200, {
      success: true,
      data: startup,
    });
  } catch (error: unknown) {
    console.error("Erro ao buscar startup:", error);
    return enviarJSON(res, 500, {
      success: false,
      message: "Erro interno ao buscar startup. Tente novamente.",
    });
  }
});
