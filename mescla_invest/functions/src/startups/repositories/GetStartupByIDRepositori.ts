// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Servidor Node.js

import * as admin from 'firebase-admin';
admin.initializeApp();

export async function buscarStartupPeloIDNoBanco ( startupId : string){
  console.log("entrei no buscar startup pelo ID");
  return await admin.firestore().collection('startups').doc(startupId).get();
}