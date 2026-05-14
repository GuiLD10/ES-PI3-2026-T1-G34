import * as admin from "firebase-admin";
import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/https";
import {RegisterBody} from "../types/UserAuthInterfaces";
admin.initializeApp();

export async function criarUsuario(data: RegisterBody) {
  console.log("entrei em criar usuÃ¡rio");
  try {
    return await admin.auth().createUser({
      email: data.email.trim(),
      password: data.senha,
      displayName: data.nome.trim(),
    });
  } catch (error: unknown) {
    const firebaseError = error as { code?: string };
    if (firebaseError.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Este e-mail jÃ¡ estÃ¡ em uso.");
    }
    throw new HttpsError("internal", "Erro ao criar usuÃ¡rio no Auth.");
  }
}


export async function salvarDadosUsuarios(uid: string, data: RegisterBody) {
  console.log("entrei em salvar dados de usuÃ¡rio");
  const db = admin.firestore();
  return await db.collection("usuarios").doc(uid).set({
    uid: uid,
    nome: data.nome.trim(),
    email: data.email.trim(),
    cpf: data.cpf.replace(/\D/g, ""),
    telefone: data.telefone.replace(/\D/g, ""),
    criadoEm: FieldValue.serverTimestamp(),
  });
}
