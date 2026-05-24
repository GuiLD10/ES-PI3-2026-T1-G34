// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de logar usuário e trata ela

import { onRequest } from "firebase-functions/v2/https";
import { LoginBody } from "../types/UserAuthInterfaces";
import * as Validacao from "../shared/Validations";
import { buscarCredenciais} from "../repositories/LoginRepositori";
import { enviarJSON } from "../shared/ResponseTools";

export const loginUsuario = onRequest(async (req, res) => {
  // aceita apenas POST
  if (req.method !== "POST") {
    return enviarJSON(res, 405, {
      success: false,
      message: "Método não permitido."
    });
  }

  const { email, senha } = req.body as LoginBody;

  // valida campos obrigatórios
  if (!email || !senha) {
    return enviarJSON(res, 400, {
      success: false,
      message: "E-mail e senha são obrigatórios."
    });
  }

  // valida email
  if (!Validacao.validarEmail(email)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Email inválido"
    });
  }

  try {
    // busca usuário
    const data = await buscarCredenciais(email, senha);

    // resposta de sucesso
    return enviarJSON(res, 200, {
      success: true,
      message: "Login realizado com sucesso!",
      uid: data.localId,
      token: data.idToken,
    });

  } catch (error) {
    console.error(error);

    // resposta de erro
    return enviarJSON(res, 404, {
      success: false,
      message: "Usuário não encontrado."
    });
  }
});