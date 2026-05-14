// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: configura Firebase Admin compartilhado

import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const firebaseAdmin = admin;
export const auth = admin.auth();
export const db = admin.firestore();
export const fieldValue = admin.firestore.FieldValue;
