// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {
  cancelOrder as cancelExchangeOrder,
} from "../repositories/orderRepository";
import {authenticateExchangeUser} from "../shared/exchangeAuth";
import {buildExchangeErrorResponse} from "../shared/exchangeErrors";
import {parseCancelOrderInput} from "../shared/exchangeParsing";

export const cancelOrder = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "POST") {
    return sendJson(res, 405, {
      success: false,
      message: "Metodo nao permitido.",
    });
  }

  try {
    const user = await authenticateExchangeUser(req);
    const orderId = parseCancelOrderInput(req.body ?? {});
    const data = await cancelExchangeOrder(user, orderId);

    return sendJson(res, 200, {
      success: true,
      data,
    });
  } catch (error: unknown) {
    console.error("Erro ao cancelar oferta:", error);
    const response = buildExchangeErrorResponse(
      error,
      "Erro interno ao cancelar oferta. Tente novamente.",
    );

    return sendJson(res, response.statusCode, response.body);
  }
});
