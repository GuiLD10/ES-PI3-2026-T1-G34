// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: conecta com o banco de dados para logar um usuário

import {UserRecord} from "firebase-admin/auth";
import {HttpsError} from "firebase-functions/https";
import {auth} from "../../shared/firebase";
import * as admin from "firebase-admin";
import {
  FirebaseLoginResponse,
  FirebaseRefreshTokenResponse,
} from "../../shared/types";

function getFirebaseWebApiKey(): string {
  const apiKey = process.env.WEB_API_KEY;

  if (!apiKey) {
    throw new HttpsError("internal", "Firebase Web API key não configurada.");
  }

  return apiKey;
}

export async function signInWithPassword(email: string, senha: string) {
  const apiKey = getFirebaseWebApiKey();

  const url =
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword" +
    `?key=${apiKey}`;

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

  if (!response.ok || data.error) {
    throw new HttpsError("unauthenticated", "E-mail ou senha incorretos.");
  }

  return data;
}

export async function refreshIdToken(refreshToken: string) {
  const apiKey = getFirebaseWebApiKey();
  const response = await fetch(
    "https://securetoken.googleapis.com/v1/token" + `?key=${apiKey}`,
    {
      method: "POST",
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: new URLSearchParams({
        grant_type: "refresh_token",
        refresh_token: refreshToken,
      }).toString(),
    },
  );

  const data = (await response.json()) as FirebaseRefreshTokenResponse;

  if (!response.ok || data.error) {
    throw new HttpsError("unauthenticated", "Sessao expirada ou invalida.");
  }

  return data;
}

export async function getUserInformations(localID: string) {
  return await admin.auth().getUser(localID);
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
