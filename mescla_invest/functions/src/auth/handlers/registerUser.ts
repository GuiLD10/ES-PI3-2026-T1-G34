// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http de criar usuário e trata ela

import {onRequest} from "firebase-functions/v2/https";
import {HttpsError} from "firebase-functions/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
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
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  const body = (req.body ?? {}) as RegisterBody;
  const {nome, email, cpf, telefone, senha, confirmarSenha} = body;

  if (!nome || nome.trim().length < 2) {
    return sendJson(res, 400, {
      success: false,
      field: "Nome",
      message: "Nome está incorreto",
    });
  }
  if (!email || !validateEmail(email)) {
    return sendJson(res, 400, {
      success: false,
      field: "E-mail",
      message: "E-mail está incorreto",
    });
  }
  if (!cpf || !validateCpf(cpf)) {
    return sendJson(res, 400, {
      success: false,
      field: "CPF",
      message: "CPF está incorreto",
    });
  }
  if (!telefone || !validatePhone(telefone)) {
    return sendJson(res, 400, {
      success: false,
      field: "Telefone",
      message: "Telefone está incorreto",
    });
  }
  if (!senha || senha.length < 6) {
    return sendJson(res, 400, {
      success: false,
      field: "Senha",
      message: "Senha está incorreta",
    });
  }
  if (!confirmarSenha || confirmarSenha !== senha) {
    return sendJson(res, 400, {
      success: false,
      field: "Confirmar Senha",
      message: "Confirmar Senha está incorreto",
    });
  }

  try {
    const user = await createAuthUser(body);
    await saveUserProfile(user.uid, body);
    return sendJson(res, 201, {
      success: true,
      message: "Cadastro realizado com sucesso!",
      uid: user.uid,
      nome: user.displayName,
      email: user.email,
    });
  } catch (error: unknown) {
    console.error(error);

    if (error instanceof HttpsError && error.code === "already-exists") {
      return sendJson(res, 409, {
        success: false,
        field: "E-mail",
        message: "E-mail já está cadastrado",
      });
    }

    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao realizar o cadastro. Tente novamente.",
    });
  }
});
