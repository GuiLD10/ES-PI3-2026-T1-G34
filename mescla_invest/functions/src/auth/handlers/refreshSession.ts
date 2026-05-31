// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Renova a sessao do usuario usando refresh token do Firebase

import {onRequest} from "firebase-functions/v2/https";
import {HttpsError} from "firebase-functions/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {
  getUserInformations,
  refreshIdToken,
} from "../repositories/authRepository";
import {db} from "../../shared/firebase";
import {RefreshSessionBody} from "../types/authTypes";

export const refreshSession = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Metodo nao permitido.",
    });
  }

  const {refreshToken} = (req.body ?? {}) as RefreshSessionBody;

  if (!refreshToken || refreshToken.trim() === "") {
    return sendJson(res, 400, {
      success: false,
      message: "Refresh token nao informado.",
    });
  }

  try {
    const data = await refreshIdToken(refreshToken.trim());

    if (!data.user_id || !data.id_token || !data.refresh_token) {
      return sendJson(res, 401, {
        success: false,
        message: "Sessao expirada ou invalida.",
      });
    }

    const [user, userDoc] = await Promise.all([
      getUserInformations(data.user_id),
      db.collection("usuarios").doc(data.user_id).get(),
    ]);
    const userData = userDoc.data();
    const mfaAtivo = userData?.mfaAtivo === true;

    return sendJson(res, 200, {
      success: true,
      message: "Sessao renovada com sucesso.",
      uid: data.user_id,
      token: data.id_token,
      refreshToken: data.refresh_token,
      name: user.displayName,
      email: user.email,
      telefone: userData?.telefone ?? user.phoneNumber ?? "",
      requiresMfa: mfaAtivo,
    });
  } catch (error) {
    console.error("Erro ao renovar sessao:", error);

    if (error instanceof HttpsError && error.code === "unauthenticated") {
      return sendJson(res, 401, {
        success: false,
        message: "Sessao expirada ou invalida.",
      });
    }

    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao renovar sessao. Tente novamente.",
    });
  }
});
