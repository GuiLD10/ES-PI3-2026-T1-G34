// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Servidor Node.js

import {db} from "../../shared/firebase";
import {mapStartupDocument} from "../shared/startupMapper";
import {StartupData} from "../types/startupTypes";

export async function listActiveStartups(): Promise<StartupData[]> {
  const snapshot = await db
    .collection("startups")
    .where("status", "==", "ativa")
    .get();
  const startups = await Promise.all(
    snapshot.docs.map(async (doc) => {
      return mapStartupDocument(doc, {
        hasTransactions: await hasStartupTransactions(doc.id),
      });
    }),
  );

  return startups.sort((first, second) => {
    return first.nome.localeCompare(second.nome, "pt-BR");
  });
}

export async function findStartupById(startupId: string) {
  return await db.collection("startups").doc(startupId).get();
}

export async function findStartupRef( startupid : string) {
  return await db.collection("startups").doc(startupid);
}

export async function hasStartupTransactions(startupId: string) {
  const snapshot = await db
    .collection("transacoes")
    .where("startup_id", "==", startupId)
    .limit(1)
    .get();

  return !snapshot.empty;
}
