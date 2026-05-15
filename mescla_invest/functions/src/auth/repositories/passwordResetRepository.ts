// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: conecta com o banco de dados para recuperar senha

import {auth} from "../../shared/firebase";
import {FirebaseLoginResponse} from "../../shared/types";

function getFirebaseWebApiKey(): string {
  const apiKey = process.env.FIREBASE_WEB_API_KEY ?? process.env.WEB_API_KEY;

  if (!apiKey) {
    throw new Error("Firebase Web API key não configurada.");
  }

  return apiKey;
}

export async function getUserByEmail(email: string) {
  return await auth.getUserByEmail(email.trim());
}

export async function sendPasswordResetEmail(email: string) {
  const apiKey = getFirebaseWebApiKey();

  const response = await fetch(
    "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode" +
      `?key=${apiKey}`,
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        requestType: "PASSWORD_RESET",
        email: email.trim(),
      }),
    },
  );

  const data = (await response.json()) as FirebaseLoginResponse;

  if (!response.ok || data.error) {
    throw new Error("Erro ao enviar e-mail de recuperação.");
  }

  return data;
}
