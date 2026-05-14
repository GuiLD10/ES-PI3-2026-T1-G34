import {onRequest} from "firebase-functions/v2/https";
import {
  criarUsuario,
  salvarDadosUsuarios,
} from "../repositories/CadastroRepositore";
import {enviarJSON} from "../shared/ResponseTools";
import * as Validacao from "../shared/Validations";
import {RegisterBody} from "../types/UserAuthInterfaces";

export const criarUsuarioAuth = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return enviarJSON(res, 405, {
      success: false,
      message: "MÃ©todo nÃ£o permitido.",
    });
  }

  const body = req.body as RegisterBody;

  const {nome, email, cpf, telefone, senha, confirmarSenha} = body;

  if (!nome || nome.trim().length < 2) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Nome invÃ¡lido",
    });
  }
  if (!email || !Validacao.validarEmail(email)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Email invÃ¡lido",
    });
  }
  if (!cpf || !Validacao.validarCpf(cpf)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "CPF invÃ¡lido",
    });
  }
  if (!telefone || !Validacao.validarTelefone(telefone)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Telefone invÃ¡lido",
    });
  }
  if (!senha || senha.length < 6) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Senha invÃ¡lida",
    });
  }
  if (!confirmarSenha || confirmarSenha !== senha) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Confirmar senha diferente da senha",
    });
  }

  try {
    const body = req.body as RegisterBody;
    const user = await criarUsuario(body);
    await salvarDadosUsuarios(user.uid, body);
    return enviarJSON(res, 201, {
      success: true,
      message: "UsuÃ¡rio criado com sucesso!",
      uid: user.uid,
    });
  } catch (error: unknown) {
    console.error(error);
    return enviarJSON(res, 500, {
      success: false,
      message: "Erro ao criar usuÃ¡rio.",
    });
  }
});
