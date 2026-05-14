
import {onRequest} from "firebase-functions/v2/https";
import {LoginBody} from "../types/UserAuthInterfaces";
import * as Validacao from "../shared/Validations";
import {buscarCredenciais} from "../repositories/LoginRepositori";
import {enviarJSON} from "../shared/ResponseTools";

export const loginUsuario = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return enviarJSON(res, 405, {
      success: false,
      message: "MÃ©todo nÃ£o permitido.",
    });
  }

  const {email, senha} = req.body as LoginBody;

  if (!email || !senha) {
    return enviarJSON(res, 400, {
      success: false,
      message: "E-mail e senha sÃ£o obrigatÃ³rios.",
    });
  }

  if (!Validacao.validarEmail(email)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Email invÃ¡lido",
    });
  }

  try {
    const data = await buscarCredenciais(email, senha);

    return enviarJSON(res, 200, {
      success: true,
      message: "Login realizado com sucesso!",
      uid: data.localId,
      token: data.idToken,
    });
  } catch (error) {
    console.error(error);

    return enviarJSON(res, 404, {
      success: false,
      message: "UsuÃ¡rio nÃ£o encontrado.",
    });
  }
});
