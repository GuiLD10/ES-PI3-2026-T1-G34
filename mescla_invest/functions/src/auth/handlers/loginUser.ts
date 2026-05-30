// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de logar usuário e trata ela

import {onRequest} from "firebase-functions/v2/https";
import {HttpsError} from "firebase-functions/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {
  getUserInformations,
  signInWithPassword,
} from "../repositories/authRepository";
import {LoginBody} from "../types/authTypes";

export const loginUser = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const {email, senha} = (req.body ?? {}) as LoginBody;

  if (!email || !senha) {
    return sendJson(res, 400, {
      success: false,
      message: "E-mail ou senha incorretos",
    });
  }

  try {
    const data = await signInWithPassword(email, senha);

    if (!data.localId) {
      return sendJson(res, 401, {
        success: false,
        message: "não foi possivel pegar localID",
        uid: data.localId,
        token: data.idToken,
      });
    }

    const user = await getUserInformations(data.localId);

    return sendJson(res, 200, {
      success: true,
      message: "Login realizado com sucesso!",
      uid: data.localId,
      token: data.idToken,
      refreshToken: data.refreshToken,
      name: user.displayName,
      email: user.email,
      telefone: user.phoneNumber,
    });
  } catch (error) {
    console.error(error);

    if (error instanceof HttpsError && error.code === "unauthenticated") {
      return sendJson(res, 401, {
        success: false,
        message: "E-mail ou senha incorretos",
      });
    }

    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao realizar o login. Tente novamente.",
    });
  }
});
