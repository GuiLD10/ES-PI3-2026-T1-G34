// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de criar usuário e trata ela
import { onRequest } from "firebase-functions/v2/https";
import { CriarUsuário, salvarDadosUsuarios } from "../repositories/CadastroRepositore";
import { enviarJSON } from "../shared/ResponseTools";
import * as Validacao from "../shared/Validations";
import { RegisterBody } from "../types/UserAuthInterfaces";

export const criarUsuarioAuth = onRequest(async (req, res) => {
  // aceita apenas POST
  if (req.method !== "POST") {
    return enviarJSON(res, 405, {
      success: false,
      message: "Método não permitido."
    });
  }

  const body = req.body as RegisterBody;

  const { nome, email, cpf, telefone, senha, confirmarSenha } = body;

  // valida nome
  if (!nome || nome.trim().length < 2) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Nome inválido"
    });
  }
  // valida email
  if (!email || !Validacao.validarEmail(email)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Email inválido"
    });
  }
  // valida cpf
  if (!cpf || !Validacao.validarCpf(cpf)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "CPF inválido"
    });
  }
  // valida telefone
  if (!telefone || !Validacao.validarTelefone(telefone)) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Telefone inválido"
    });
  }
  // valida senha
  if (!senha || senha.length < 6) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Senha inválida"
    });
  }
  // confirma senha
  if (!confirmarSenha || confirmarSenha !== senha) {
    return enviarJSON(res, 400, {
      success: false,
      message: "Confirmar senha diferente da senha"
    });
  }

  try {
    const body = req.body as RegisterBody;
    // cria usuário
    const user = await CriarUsuário(body);
    // salva dados adicionais
    await salvarDadosUsuarios(user.uid, body);
    // resposta
    return enviarJSON(res, 201, {
      success: true,
      message: "Usuário criado com sucesso!",
      uid: user.uid
    });

  } catch (error: any) {
    console.error(error);
    //resposta erro
    return enviarJSON(res, 500, {
      success: false,
      message: "Erro ao criar usuário."
    });
  }
});