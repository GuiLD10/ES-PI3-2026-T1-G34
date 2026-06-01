// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http para ativar/desativar MFA do usuário

import {onRequest} from "firebase-functions/v2/https";
import {authenticateRequest, AuthRequestError} from "../../shared/auth";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {db} from "../../shared/firebase";
import {ToggleMfaBody} from "../types/authTypes";

export const toggleMfa = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Método não permitido.",
    });
  }

  try {
    const user = await authenticateRequest(req);
    const {ativar} = (req.body ?? {}) as Partial<ToggleMfaBody>;

    if (typeof ativar !== "boolean") {
      return sendJson(res, 400, {
        success: false,
        message: "Status do MFA deve ser informado.",
      });
    }

    const userRef = db.collection("usuarios").doc(user.uid);
    const userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      return sendJson(res, 404, {
        success: false,
        message: "Usuario nao encontrado.",
      });
    }

    await userRef.update({
      mfaAtivo: ativar,
    });

    return sendJson(res, 200, {
      success: true,
      message: ativar ?
        "Autenticação 2FA ativada com sucesso!" :
        "Autenticação 2FA desativada com sucesso.",
      mfaAtivo: ativar,
    });
  } catch (error) {
    if (error instanceof AuthRequestError) {
      return sendJson(res, error.statusCode, {
        success: false,
        message: error.message,
      });
    }

    console.error("Erro ao atualizar status do MFA:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro ao atualizar status do MFA.",
    });
  }
});
