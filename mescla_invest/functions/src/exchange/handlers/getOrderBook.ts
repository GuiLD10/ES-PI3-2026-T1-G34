import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {authenticateExchangeUser} from "../shared/exchangeAuth";
import {buildExchangeErrorResponse} from "../shared/exchangeErrors";
import {parseQueryStartupId} from "../shared/exchangeParsing";
import {
  getOrderBook as getOrderBookData,
} from "../repositories/orderQueryRepository";

export const getOrderBook = onRequest(async (req, res) => {
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
    await authenticateExchangeUser(req);
    const startupId = parseQueryStartupId(req.query.startupId);
    const data = await getOrderBookData(startupId);

    return sendJson(res, 200, {
      success: true,
      data,
    });
  } catch (error: unknown) {
    console.error("Erro ao buscar order book:", error);
    const response = buildExchangeErrorResponse(
      error,
      "Erro interno ao buscar order book. Tente novamente.",
    );

    return sendJson(res, response.statusCode, response.body);
  }
});
