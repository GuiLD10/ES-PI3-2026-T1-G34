//Autor:Henrique Soares Cunha
//RA:23013359
//Descrição:conecta com o banco e busca as perguntas da startups

import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import { FieldValue } from "firebase-admin/firestore";
import { findStartupById , findStartupRef} from "../repositories/startupRepository";

export const createStartupQuestion = onRequest(async (req, res) => {

  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const { startupId, authorName, questionType, question } = req.body;

  // Validações
  if (typeof startupId !== "string" || startupId.trim() === "") {
    return sendJson(res, 400, {
      success: false,
      message: "startupId inválido.",
    });
  }

  if (typeof authorName !== "string" || authorName.trim() === "") {
    return sendJson(res, 400, {
      success: false,
      message: "Nome do autor inválido.",
    });
  }

  if (typeof question !== "string" || question.trim() === "") {
    return sendJson(res, 400, {
      success: false,
      message: "Pergunta inválida.",
    });
  }

  if (
    questionType !== "publica" &&
    questionType !== "privada"
  ) {
    return sendJson(res, 400, {
      success: false,
      message: "Tipo da pergunta inválido.",
    });
  }

  try {

    const startupRef = await findStartupRef(startupId);

    const startupDoc = await startupRef.get();

    if (!startupDoc.exists) {
      return sendJson(res, 404, {
        success: false,
        message: "Startup não encontrada.",
      });
    }

    // Estrutura da pergunta
    const newQuestion = {
      id: crypto.randomUUID(),

      nome_autor: authorName.trim(),

      pergunta: question.trim(),

      questionType,

      createdAt: new Date().toISOString(),

      // seção de respostas
      resposta: [{resposta:"resposta padrão para teste" , nome_autor: "Henrique" , id: crypto.randomUUID()}],
    };

    // adiciona no array "questions"
    await startupRef.update({
      perguntas_respostas: FieldValue.arrayUnion(newQuestion),
    });

    return sendJson(res, 201, {
      success: true,
      message: "Pergunta criada com sucesso.",
      data: newQuestion,
    });
  } catch (error: unknown) {
    console.error("Erro ao criar pergunta:", error);

    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao criar pergunta.",
    });
  }
});