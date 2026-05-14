import {onRequest} from "firebase-functions/v2/https";
import {ForgotPasswordBody} from "../types/UserAuthInterfaces";
import {enviarJSON} from "../shared/ResponseTools";
import {validarEmail} from "../shared/Validations";
import {midlewareGetUserByEmail} from "../repositories/RecuperarSenha";

export const handleForgotPassword = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return enviarJSON(res, 405, {
      success: false,
      message: "MÃ©todo nÃ£o permitido.",
    });
  }

  const {email} = req.body as ForgotPasswordBody;
  if (!email || !validarEmail(email)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "E-mail invÃ¡lido.",
    });
  }

  try {
    await midlewareGetUserByEmail(email, res);

    if (res.headersSent) {
      return;
    }
    return enviarJSON(res, 200, {
      success: true,
      message: "UsuÃ¡rio encontrado.",
    });
  } catch (error) {
    console.error(error);
    if (!res.headersSent) {
      return enviarJSON(res, 500, {
        success: false,
        message: "Erro interno.",
      });
    }
  }
});
