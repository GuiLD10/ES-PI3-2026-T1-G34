// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {listUserOrders} from "../repositories/orderQueryRepository";
import {authenticateExchangeUser} from "../shared/exchangeAuth";
import {buildExchangeErrorResponse} from "../shared/exchangeErrors";

export const listMyOrders = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "GET") {
    return sendJson(res, 405, {
      success: false,
      message: "Metodo nao permitido.",
    });
  }

  try {
    const user = await authenticateExchangeUser(req);
    const data = await listUserOrders(user.uid);

    return sendJson(res, 200, {
      success: true,
      data,
    });
  } catch (error: unknown) {
    console.error("Erro ao listar ofertas do usuario:", error);
    const response = buildExchangeErrorResponse(
      error,
      "Erro interno ao listar ofertas. Tente novamente.",
    );

    return sendJson(res, response.statusCode, response.body);
  }
});
