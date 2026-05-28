// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de buscar startup pelo id e trata ela

import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {findStartupById} from "../repositories/startupRepository";
import {mapStartupDocument} from "../shared/startupMapper";

export const getStartupById = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "GET") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const startupId = req.query.startupId;

  const uid = typeof req.query.uid === "string" ? req.query.uid.trim() : "";

  if (typeof startupId !== "string") {
    return sendJson(res, 400, {
      success: false,
      message: "Parâmetro startupId inválido ou ausente.",
    });
  }
  if (startupId.trim() === "") {
    return sendJson(res, 400, {
      success: false,
      message: "O ID da startup não pode estar vazio.",
    });
  }

  try {
    const doc = await findStartupById(startupId);

    if (!doc.exists) {
      return sendJson(res, 404, {
        success: false,
        message: "Startup não encontrada.",
      });
    }

    const startup = mapStartupDocument(doc);

    startup.perguntas_respostas = startup.perguntas_respostas.filter((pergunta: any) => {

      // publica -> todos podem ver
      if (pergunta.questionType === "public") {
        return true;
      }

      // privada -> apenas dono pode ver
      return pergunta.uid === uid;
    });

    if (startup.status !== "ativa") {
      return sendJson(res, 404, {
        success: false,
        message: "Startup não encontrada.",
      });
    }

    return sendJson(res, 200, {
      success: true,
      data: startup,
    });
  } catch (error: unknown) {
    console.error("Erro ao buscar startup:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao buscar startup. Tente novamente.",
    });
  }
});
