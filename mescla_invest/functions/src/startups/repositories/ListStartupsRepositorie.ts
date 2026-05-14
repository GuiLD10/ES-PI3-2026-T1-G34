import {StartupData} from "../types/StartupInterfaces";
import * as admin from "firebase-admin";
import {montarStartup} from "../shared/ResponseTools";
admin.initializeApp();

export async function buscarStartupsNoBanco(): Promise<StartupData[]> {
  const db = admin.firestore();
  console.log("entrei no buscar startup pelo ID");
  try {
    const snapshot = await db
      .collection("startups")
      .where("status", "==", "ativa")
      .get();
    const startups: StartupData[] = snapshot.docs.map(montarStartup);

    return startups;
  } catch (error : unknown) {
    throw new Error(" erro de conexÃ£o com o banco");
  }
}
