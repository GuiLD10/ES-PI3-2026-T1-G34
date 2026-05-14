// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de criar usuário e trata ela

import {onRequest} from "firebase-functions/v2/https";
import {sendJson} from "../../shared/http";
import {
  validateCpf,
  validateEmail,
  validatePhone,
} from "../../shared/validators";
import {
  createAuthUser,
  saveUserProfile,
} from "../repositories/userRepository";
import {RegisterBody} from "../types/authTypes";

export const registerUser = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const body = req.body as RegisterBody;
  const {nome, email, cpf, telefone, senha, confirmarSenha} = body;

  if (!nome || nome.trim().length < 2) {
    return sendJson(res, 400, {
      success: false,
      message: "Nome inválido",
    });
  }
  if (!email || !validateEmail(email)) {
    return sendJson(res, 400, {
      success: false,
      message: "Email inválido",
    });
  }
  if (!cpf || !validateCpf(cpf)) {
    return sendJson(res, 400, {
      success: false,
      message: "CPF inválido",
    });
  }
  if (!telefone || !validatePhone(telefone)) {
    return sendJson(res, 400, {
      success: false,
      message: "Telefone inválido",
    });
  }
  if (!senha || senha.length < 6) {
    return sendJson(res, 400, {
      success: false,
      message: "Senha inválida",
    });
  }
  if (!confirmarSenha || confirmarSenha !== senha) {
    return sendJson(res, 400, {
      success: false,
      message: "Confirmar senha diferente da senha",
    });
  }

  try {
    const user = await createAuthUser(body);
    await saveUserProfile(user.uid, body);
    return sendJson(res, 201, {
      success: true,
      message: "Usuário criado com sucesso!",
      uid: user.uid,
    });
  } catch (error: unknown) {
    console.error(error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro ao criar usuário.",
    });
  }
});
