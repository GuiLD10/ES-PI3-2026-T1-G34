import * as admin from "firebase-admin";
import {enviarJSON} from "../shared/ResponseTools";
import * as http from "http";
admin.initializeApp();

export async function midlewareGetUserByEmail(
  email: string,
  res: http.ServerResponse,
) {
  const auth = admin.auth();

  try {
    await auth.getUserByEmail(email.trim());
  } catch (error: unknown) {
    const firebaseError = error as { code?: string };
    if (firebaseError.code === "auth/user-not-found") {
      return enviarJSON(res, 404, {
        success: false,
        message: "E-mail nÃ£o encontrado no sistema.",
      });
    }
    console.error("Erro ao buscar usuÃ¡rio:", error);
    return enviarJSON(res, 500, {
      success: false,
      message: "Erro interno. Tente novamente.",
    });
  }
}
