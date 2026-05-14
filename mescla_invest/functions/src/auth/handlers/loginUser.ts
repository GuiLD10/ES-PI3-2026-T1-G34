// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de logar usuário e trata ela

import {onRequest} from "firebase-functions/v2/https";
import {sendJson} from "../../shared/http";
import {validateEmail} from "../../shared/validators";
import {signInWithPassword} from "../repositories/authRepository";
import {LoginBody} from "../types/authTypes";

export const loginUser = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const {email, senha} = req.body as LoginBody;

  if (!email || !senha) {
    return sendJson(res, 400, {
      success: false,
      message: "E-mail e senha são obrigatórios.",
    });
  }

  if (!validateEmail(email)) {
    return sendJson(res, 400, {
      success: false,
      message: "Email inválido",
    });
  }

  try {
    const data = await signInWithPassword(email, senha);

    return sendJson(res, 200, {
      success: true,
      message: "Login realizado com sucesso!",
      uid: data.localId,
      token: data.idToken,
    });
  } catch (error) {
    console.error(error);

    return sendJson(res, 404, {
      success: false,
      message: "Usuário não encontrado.",
    });
  }
});
