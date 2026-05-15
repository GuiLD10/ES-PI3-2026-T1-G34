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

  return snapshot.docs
    .map(mapStartupDocument)
    .sort((first, second) => first.nome.localeCompare(second.nome, "pt-BR"));
}

export async function findStartupById(startupId: string) {
  return await db.collection("startups").doc(startupId).get();
}
