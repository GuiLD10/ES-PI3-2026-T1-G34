// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: monta dados de startup para resposta

import {DocumentSnapshot} from "firebase-admin/firestore";
import {convertFirestoreValue} from "../../shared/firestoreConverters";
import {getStartupMarketPrices} from "../../shared/startupPricing";
import {StartupData} from "../types/startupTypes";

export function mapStartupDocument(doc: DocumentSnapshot): StartupData {
  const data = convertFirestoreValue(doc.data()) as Record<string, unknown>;
  const prices = getStartupMarketPrices(data);

  return {
    id: doc.id,
    nome: (data.nome as string) || "",
    descricao: (data.descricao as string) || "",
    setor: (data.setor as string) || "",
    estagio: (data.estagio as string) || "",
    status: (data.status as string) || "",
    capital_aportado: Number(data.capital_aportado) || 0,
    tokens_emitidos: Number(data.tokens_emitidos) || 0,
    preco_atual_centavos: prices.currentPriceCents,
    preco_primario_centavos: prices.primaryPriceCents,
    video_demo: (data.video_demo as string) || "",
    socios: Array.isArray(data.socios) ? data.socios : [],
    mentores_conselho: Array.isArray(data.mentores_conselho) ?
      data.mentores_conselho :
      [],
    perguntas_respostas: Array.isArray(data.perguntas_respostas) ?
      data.perguntas_respostas :
      [],
    criado_em: (data.criado_em as string) || null,
    atualizado_em: (data.atualizado_em as string) || null,
  };
}
