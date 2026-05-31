// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Recebe a requisição http para ativar/desativar MFA do usuário

import {onRequest} from "firebase-functions/v2/https";
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

  const {uid, ativar} = (req.body ?? {}) as ToggleMfaBody;

  if (!uid) {
    return sendJson(res, 400, {
      success: false,
      message: "UID do usuário é obrigatório.",
    });
  }

  try {
    await db.collection("usuarios").doc(uid).update({
      mfaAtivo: ativar === true,
    });

    return sendJson(res, 200, {
      success: true,
      message: ativar ?
        "Autenticação 2FA ativada com sucesso!" :
        "Autenticação 2FA desativada com sucesso.",
      mfaAtivo: ativar === true,
    });
  } catch (error) {
    console.error(error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro ao atualizar status do MFA.",
    });
  }
});
