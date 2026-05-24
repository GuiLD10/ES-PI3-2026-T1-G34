// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de recuperar senha e trata ela
import { onRequest } from "firebase-functions/v2/https";
import { ForgotPasswordBody } from "../types/UserAuthInterfaces";
import { enviarJSON } from "../shared/ResponseTools";
import { validarEmail } from "../shared/Validations";
import { midlewareGetUserByEmail } from "../repositories/RecuperarSenha";

export const handleForgotPassword = onRequest(async (req, res) => {
  // aceita apenas POST
  if (req.method !== "POST") {
    return enviarJSON(res, 405, {
      success: false,
      message: "Método não permitido."
    });
  }

  // MUDEI AQUI -> usando req.body ao invés de lerBody
  const { email } = req.body as ForgotPasswordBody;
  // valida email
  if (!email || !validarEmail(email)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "E-mail inválido."
    });
  }

  try {

    await midlewareGetUserByEmail(email, res);

    // Verifica se a Resposta Foi Enviada
    if (res.headersSent) {
      return;
    }
    // sucesso
    return enviarJSON(res, 200, {
      success: true,
      message: "Usuário encontrado."
    });

  } catch (error) {
    console.error(error);
    // evita enviar duas respostas
    if (!res.headersSent) {
      return enviarJSON(res, 500, {
        success: false,
        message: "Erro interno."
      });
    }
  }
});