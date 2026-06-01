// Autor: Henrique Soares Cunha
// RA: 23013359
// Descrição: conecta com o banco e salva perguntas das startups

import {onRequest} from "firebase-functions/v2/https";
import {authenticateRequest, AuthRequestError} from "../../shared/auth";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {FieldValue} from "firebase-admin/firestore";
import {findStartupRef} from "../repositories/startupRepository";
import {db} from "../../shared/firebase";

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

  const {startupId, authorName, questionType, question} = req.body;

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
    const user = await authenticateRequest(req);
    const startupRef = await findStartupRef(startupId);

    const startupDoc = await startupRef.get();

    if (!startupDoc.exists) {
      return sendJson(res, 404, {
        success: false,
        message: "Startup não encontrada.",
      });
    }

    // Validação de investidor para perguntas privadas
    if (questionType === "privada") {
      const ativoDoc = await db
        .collection("usuarios")
        .doc(user.uid)
        .collection("ativos")
        .doc(startupId)
        .get();

      const quantidade = Number(ativoDoc.data()?.quantidade_disponivel ?? 0);

      if (!ativoDoc.exists || quantidade <= 0) {
        return sendJson(res, 403, {
          success: false,
          message:
            "Apenas investidores com posição ativa podem fazer perguntas privadas.",
        });
      }
    }

    // Estrutura da pergunta
    const newQuestion = {
      id: crypto.randomUUID(),

      nome_autor: authorName.trim(),

      pergunta: question.trim(),

      questionType,

      createdAt: new Date().toISOString(),

      uid: user.uid,

      resposta: [],
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
    if (error instanceof AuthRequestError) {
      return sendJson(res, error.statusCode, {
        success: false,
        message: error.message,
      });
    }

    console.error("Erro ao criar pergunta:", error);

    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao criar pergunta.",
    });
  }
});
