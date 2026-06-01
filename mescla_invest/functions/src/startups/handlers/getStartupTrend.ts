// Autor: Henrique Soares Cunha
// RA: 23013359
// Descrição: para ver as tendencias de mercado das startups

import {onRequest} from "firebase-functions/v2/https";
import {Timestamp} from "firebase-admin/firestore";

import {db} from "../../shared/firebase";
import {handleCorsPreflight, sendJson} from "../../shared/http";

type TrendType = "uptrend" | "downtrend" | "stable";

interface TransactionData {
  startup_id: string;
  valor_unitario_centavos: number;
  valor_total_centavos: number;
  quantidade: number;
  criado_em: Timestamp;
}

export const getStartupTrend = onRequest(async (req, res) => {
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
    const startupId = String(req.query.startup_id ?? "").trim();

    if (!startupId) {
      return sendJson(res, 400, {
        success: false,
        message: "startup_id é obrigatório.",
      });
    }

    const now = Date.now();

    const sevenDaysAgo = Timestamp.fromMillis(
      now - (7 * 24 * 60 * 60 * 1000),
    );

    const snapshot = await db
      .collection("transacoes")
      .where("startup_id", "==", startupId)
      .where("criado_em", ">=", sevenDaysAgo)
      .orderBy("criado_em", "asc")
      .get();

    if (snapshot.empty) {
      return sendJson(res, 200, {
        success: true,
        message: "Nenhuma transação encontrada.",
        startup_id: startupId,
        tendencia: "stable",
        variacao_percentual: 0,
        preco_inicial_centavos: 0,
        preco_final_centavos: 0,
        volume_total_centavos: 0,
        quantidade_total_tokens: 0,
        total_transacoes: 0,
      });
    }

    const transactions = snapshot.docs.map((doc) => {
      return doc.data() as TransactionData;
    });

    const firstTransaction = transactions[0];

    const lastTransaction =
      transactions[transactions.length - 1];

    const initialPrice =
      firstTransaction.valor_unitario_centavos;

    const finalPrice =
      lastTransaction.valor_unitario_centavos;

    let variationPercent = 0;

    if (initialPrice > 0) {
      variationPercent =
        ((finalPrice - initialPrice) / initialPrice) * 100;
    }

    // Arredonda para 2 casas
    variationPercent =
      Number(variationPercent.toFixed(2));

    let trend: TrendType = "stable";

    if (variationPercent > 1) {
      trend = "uptrend";
    } else if (variationPercent < -1) {
      trend = "downtrend";
    }

    let totalVolume = 0;

    for (const transaction of transactions) {
      totalVolume +=
        transaction.valor_total_centavos;
    }

    let totalTokens = 0;

    for (const transaction of transactions) {
      totalTokens += transaction.quantidade;
    }

    return sendJson(res, 200, {
      success: true,

      message: "Indicadores calculados com sucesso.",

      startup_id: startupId,

      tendencia: trend,

      variacao_percentual: variationPercent,

      preco_inicial_centavos: initialPrice,

      preco_final_centavos: finalPrice,

      volume_total_centavos: totalVolume,

      quantidade_total_tokens: totalTokens,

      total_transacoes: transactions.length,

      periodo: "7_dias",
    });
  } catch (error) {
    console.error(error);

    return sendJson(res, 500, {
      success: false,
      message:
        "Erro interno ao calcular indicadores da startup.",
    });
  }
});
