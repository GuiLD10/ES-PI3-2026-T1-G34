// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: conecta com o banco de dados para criar um usuário

import {HttpsError} from "firebase-functions/https";
import {auth, db, fieldValue} from "../../shared/firebase";
import {RegisterBody} from "../types/authTypes";

export async function createAuthUser(data: RegisterBody) {
  try {
    return await auth.createUser({
      email: data.email.trim(),
      password: data.senha,
      displayName: data.nome.trim(),
    });
  } catch (error: unknown) {
    const firebaseError = error as { code?: string };
    if (firebaseError.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Este e-mail já está em uso.");
    }
    throw new HttpsError("internal", "Erro ao criar usuário no Auth.");
  }
}

export async function saveUserProfile(uid: string, data: RegisterBody) {
  return await db.collection("usuarios").doc(uid).set({
    uid: uid,
    nome: data.nome.trim(),
    email: data.email.trim(),
    cpf: data.cpf.replace(/\D/g, ""),
    telefone: data.telefone.replace(/\D/g, ""),
    saldo_disponivel_centavos: 0,
    saldo_bloqueado_centavos: 0,
    criadoEm: fieldValue.serverTimestamp(),
    atualizado_em: fieldValue.serverTimestamp(),
  });
}
