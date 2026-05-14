// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de recuperar senha e trata ela

import {onRequest} from "firebase-functions/v2/https";
import {sendJson} from "../../shared/http";
import {validateEmail} from "../../shared/validators";
import {getUserByEmail} from "../repositories/passwordResetRepository";
import {ForgotPasswordBody} from "../types/authTypes";

export const sendPasswordReset = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const {email} = req.body as ForgotPasswordBody;
  if (!email || !validateEmail(email)) {
    return sendJson(res, 400, {
      success: false,
      message: "E-mail inválido.",
    });
  }

  try {
    await getUserByEmail(email);
    return sendJson(res, 200, {
      success: true,
      message: "Usuário encontrado.",
    });
  } catch (error: unknown) {
    console.error(error);
    const firebaseError = error as { code?: string };

    if (firebaseError.code === "auth/user-not-found") {
      return sendJson(res, 404, {
        success: false,
        message: "E-mail não encontrado no sistema.",
      });
    }

    return sendJson(res, 500, {
      success: false,
      message: "Erro interno.",
    });
  }
});
