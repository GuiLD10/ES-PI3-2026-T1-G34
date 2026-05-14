
import * as admin from "firebase-admin";
import {UserRecord} from "firebase-admin/auth";
import {HttpsError} from "firebase-functions/https";
import {FirebaseLoginResponse} from "../shared/ResponsesInterfaces";

admin.initializeApp();


export async function buscarCredenciais(email: string, senha: string) {
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
    return await admin.auth().createCustomToken(data.uid);
  } catch (error) {
    throw new HttpsError(
      "internal",
      "Erro ao buscar token de usuÃ¡rio.",
      error,
    );
  }
}
