// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {
  sellAtMarket as sellAtMarketRepository,
} from "../repositories/orderRepository";
import {authenticateExchangeUser} from "../shared/exchangeAuth";
import {buildExchangeErrorResponse} from "../shared/exchangeErrors";
import {parseMarketSellInput} from "../shared/exchangeParsing";

export const sellAtMarket = onRequest(async (req, res) => {
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
    const input = parseMarketSellInput(req.body ?? {});
    const data = await sellAtMarketRepository(user, input);

    return sendJson(res, 201, {
      success: true,
      data,
    });
  } catch (error: unknown) {
    console.error("Erro ao vender no mercado:", error);
    const response = buildExchangeErrorResponse(
      error,
      "Erro interno ao vender tokens. Tente novamente.",
    );

    return sendJson(res, response.statusCode, response.body);
  }
});
