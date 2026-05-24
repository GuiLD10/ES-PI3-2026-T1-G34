// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: conecta com o banco de dados para criar um usuário
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/https";
admin.initializeApp();

export async function CriarUsuário(data : any) {
  console.log("entrei em criar usuário");
  try {
      return await admin.auth().createUser({
        email: data.email.trim(),
        password: data.senha,
        displayName: data.nome.trim(),
      });
    } catch (error: any) {
      if (error.code === 'auth/email-already-exists') {
        throw new HttpsError('already-exists', 'Este e-mail já está em uso.');
      }
      throw new HttpsError('internal', 'Erro ao criar usuário no Auth.');
    }
}


export async function salvarDadosUsuarios(uid: string, data: any) {
  console.log('entrei em salvar dados de usuário');
  const db = admin.firestore();
  return await db.collection('usuarios').doc(uid).set({
    uid: uid,
    nome: data.nome.trim(),
    email: data.email.trim(),
    cpf: data.cpf.replace(/\D/g, ''),
    telefone: data.telefone.replace(/\D/g, ''),
    criadoEm: FieldValue.serverTimestamp(),
  });
}