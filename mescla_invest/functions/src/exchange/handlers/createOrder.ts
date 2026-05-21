import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {
  createOrder as createExchangeOrder,
} from "../repositories/orderRepository";
import {authenticateExchangeUser} from "../shared/exchangeAuth";
import {buildExchangeErrorResponse} from "../shared/exchangeErrors";
import {parseCreateOrderInput} from "../shared/exchangeParsing";

export const createOrder = onRequest(async (req, res) => {
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
    const input = parseCreateOrderInput(req.body ?? {});
    const data = await createExchangeOrder(user, input);

    return sendJson(res, 201, {
      success: true,
      data,
    });
  } catch (error: unknown) {
    console.error("Erro ao criar oferta:", error);
    const response = buildExchangeErrorResponse(
      error,
      "Erro interno ao criar oferta. Tente novamente.",
    );

    return sendJson(res, response.statusCode, response.body);
  }
});
