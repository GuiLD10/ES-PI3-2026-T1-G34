// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: conecta com o banco de dados para logar um usuário

import {UserRecord} from "firebase-admin/auth";
import {HttpsError} from "firebase-functions/https";
import {auth} from "../../shared/firebase";
import {FirebaseLoginResponse} from "../../shared/types";

export async function signInWithPassword(email: string, senha: string) {
  const API_KEY = process.env.WEB_API_KEY;

  const url =
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword" +
    `?key=${API_KEY}`;

  const response = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      email: email.trim(),
      password: senha,
      returnSecureToken: true,
    }),
  });

  const data = (await response.json()) as FirebaseLoginResponse;

  if (!response.ok) {
    throw new HttpsError("unauthenticated", "E-mail ou senha incorretos.");
  }

  return data;
}

export async function getUserToken(data: UserRecord) {
  try {
    return await auth.createCustomToken(data.uid);
  } catch (error) {
    throw new HttpsError(
      "internal",
      "Erro ao buscar token de usuário.",
      error,
    );
  }
}
