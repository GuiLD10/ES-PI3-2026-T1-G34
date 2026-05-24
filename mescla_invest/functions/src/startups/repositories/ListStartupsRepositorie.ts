// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Servidor Node.js
import { StartupData } from "../types/StartupInterfaces";
import * as admin from 'firebase-admin';
import { montarStartup } from "../shared/ResponseTools";
admin.initializeApp();

export async function buscarStartupsNoBanco(): Promise<StartupData[]> {
  const db = admin.firestore();
  console.log("entrei no buscar startup pelo ID");
  try{
    // Pede os dados 
    const snapshot = await db.collection('startups').where('status', '==', 'ativa').get();
    // Cria a lista de Startups
    const startups: StartupData[] = snapshot.docs.map(montarStartup);

    // Retorna a lista
    return startups;
  } catch (error : unknown){
    throw new Error(" erro de conexão com o banco");
  }
}