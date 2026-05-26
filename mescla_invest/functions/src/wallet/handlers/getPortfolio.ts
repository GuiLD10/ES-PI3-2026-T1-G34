// Autor: Artur Henrique Pagno
// RA: 21013037
// Descricao: Handler para buscar portfolio do usuario (ativos + historico de precos)

import {onRequest} from "firebase-functions/v2/https";
import {handleCorsPreflight, sendJson} from "../../shared/http";
import {db} from "../../shared/firebase";
import {
  findAtivosByUid,
  findTransacoesByStartupId,
} from "../repositories/walletRepository";
import type {PortfolioAtivoResponse} from "../types/walletTypes";

export const getPortfolio = onRequest(async (req, res) => {
  if (handleCorsPreflight(req, res)) {
    return;
  }

  if (req.method !== "GET") {
    return sendJson(res, 405, {
      success: false,
      message: "Metodo nao permitido.",
    });
  }

  const uid = typeof req.query.uid === "string"
    ? req.query.uid.trim()
    : "";

  if (!uid) {
    return sendJson(res, 400, {
      success: false,
      message: "Parametro uid e obrigatorio.",
    });
  }

  try {
    const ativos = await findAtivosByUid(uid);

    const portfolio: PortfolioAtivoResponse[] = await Promise.all(
      ativos.map(async (ativo) => {
        const [startupDoc, historicoPrecos] = await Promise.all([
          db.collection("startups").doc(ativo.startup_id).get(),
          findTransacoesByStartupId(ativo.startup_id),
        ]);

        const startupData = startupDoc.data() ?? {};

        return {
          startup_id: ativo.startup_id,
          startup_nome: String(startupData.nome ?? ""),
          quantidade_disponivel: ativo.quantidade_disponivel,
          quantidade_bloqueada: ativo.quantidade_bloqueada,
          valor_medio_centavos: ativo.valor_medio_centavos,
          preco_atual_centavos: readNonNegativeInt(
            startupData.preco_atual_centavos,
          ),
          preco_primario_centavos: readNonNegativeInt(
            startupData.preco_primario_centavos,
          ),
          historico_precos: historicoPrecos,
        };
      }),
    );

    return sendJson(res, 200, {
      success: true,
      data: {ativos: portfolio},
    });
  } catch (error: unknown) {
    console.error("Erro ao buscar portfolio:", error);
    return sendJson(res, 500, {
      success: false,
      message: "Erro interno ao buscar portfolio.",
    });
  }
});

function readNonNegativeInt(value: unknown): number {
  const num = Number(value ?? 0);
  return Number.isSafeInteger(num) && num >= 0 ? num : 0;
}
