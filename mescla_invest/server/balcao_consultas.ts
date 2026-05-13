// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Consultas do balcao MesclaInvest

import * as admin from 'firebase-admin';
import type * as http from 'http';

import {
  COLECOES_BALCAO,
  STATUS_OFERTA,
  TIPOS_OFERTA,
  type StatusOferta,
  type TipoOferta,
} from './balcao_schema';
import {
  ErroBalcao,
  autenticarUsuarioBalcao,
} from './balcao_validacoes';

const LIMITE_OFERTAS_BOOK = 25;
const LIMITE_MINHAS_OFERTAS = 80;
const LIMITE_TRANSACOES = 80;

export interface OfertaBookBalcao {
  oferta_id: string;
  tipo: TipoOferta;
  usuario_uid: string;
  startup_id: string;
  quantidade_original: number;
  quantidade_restante: number;
  valor_unitario_centavos: number;
  status: StatusOferta;
  criado_em: string | null;
  atualizado_em: string | null;
}

export interface OrderBookBalcao {
  startup_id: string;
  preco_atual_centavos: number;
  melhor_compra: OfertaBookBalcao | null;
  melhor_venda: OfertaBookBalcao | null;
  compras: OfertaBookBalcao[];
  vendas: OfertaBookBalcao[];
}

export interface TransacaoConsultaBalcao {
  transacao_id: string;
  mercado: string;
  comprador_uid: string;
  vendedor_uid: string;
  startup_id: string;
  oferta_compra_id: string;
  oferta_venda_id: string;
  quantidade: number;
  valor_unitario_centavos: number;
  valor_total_centavos: number;
  criado_em: string | null;
}

export async function consultarOrderBookBalcao(
  req: http.IncomingMessage,
  db: admin.firestore.Firestore,
  auth: admin.auth.Auth,
  startupId: string
): Promise<OrderBookBalcao> {
  await autenticarUsuarioBalcao(req, auth);

  const id = normalizarId(startupId, 'startup_id');
  const startupDoc = await db.collection(COLECOES_BALCAO.startups).doc(id).get();

  if (!startupDoc.exists) {
    throw new ErroBalcao(404, 'Startup nao encontrada.', 'startup_id');
  }

  const startup = startupDoc.data() ?? {};

  if (String(startup.status ?? '') !== 'ativa') {
    throw new ErroBalcao(404, 'Startup nao encontrada.', 'startup_id');
  }

  const ofertasSnapshot = await db
    .collection(COLECOES_BALCAO.ofertas)
    .where('startup_id', '==', id)
    .get();
  const ofertas = ofertasSnapshot.docs
    .map(montarOfertaBook)
    .filter((oferta) => oferta.status === STATUS_OFERTA.aberta ||
      oferta.status === STATUS_OFERTA.parcial)
    .filter((oferta) => oferta.quantidade_restante > 0);
  const compras = ofertas
    .filter((oferta) => oferta.tipo === TIPOS_OFERTA.compra)
    .sort(ordenarCompras)
    .slice(0, LIMITE_OFERTAS_BOOK);
  const vendas = ofertas
    .filter((oferta) => oferta.tipo === TIPOS_OFERTA.venda)
    .sort(ordenarVendas)
    .slice(0, LIMITE_OFERTAS_BOOK);

  return {
    startup_id: id,
    preco_atual_centavos: lerInteiroNaoNegativo(
      startup.preco_atual_centavos
    ),
    melhor_compra: compras[0] ?? null,
    melhor_venda: vendas[0] ?? null,
    compras,
    vendas,
  };
}

export async function consultarMinhasOfertasBalcao(
  req: http.IncomingMessage,
  db: admin.firestore.Firestore,
  auth: admin.auth.Auth
): Promise<OfertaBookBalcao[]> {
  const usuario = await autenticarUsuarioBalcao(req, auth);
  const snapshot = await db
    .collection(COLECOES_BALCAO.ofertas)
    .where('usuario_uid', '==', usuario.uid)
    .get();

  return snapshot.docs
    .map(montarOfertaBook)
    .sort((a, b) => compararDatasDesc(a.criado_em, b.criado_em))
    .slice(0, LIMITE_MINHAS_OFERTAS);
}

export async function consultarTransacoesStartupBalcao(
  req: http.IncomingMessage,
  db: admin.firestore.Firestore,
  auth: admin.auth.Auth,
  startupId: string
): Promise<TransacaoConsultaBalcao[]> {
  await autenticarUsuarioBalcao(req, auth);

  const id = normalizarId(startupId, 'startup_id');
  const snapshot = await db
    .collection(COLECOES_BALCAO.transacoes)
    .where('startup_id', '==', id)
    .get();

  return snapshot.docs
    .map(montarTransacao)
    .sort((a, b) => compararDatasDesc(a.criado_em, b.criado_em))
    .slice(0, LIMITE_TRANSACOES);
}

function montarOfertaBook(
  doc: admin.firestore.QueryDocumentSnapshot
): OfertaBookBalcao {
  const dados = doc.data();

  return {
    oferta_id: doc.id,
    tipo: lerTipoOferta(dados.tipo),
    usuario_uid: String(dados.usuario_uid ?? ''),
    startup_id: String(dados.startup_id ?? ''),
    quantidade_original: lerInteiroNaoNegativo(dados.quantidade_original),
    quantidade_restante: lerInteiroNaoNegativo(dados.quantidade_restante),
    valor_unitario_centavos: lerInteiroNaoNegativo(
      dados.valor_unitario_centavos
    ),
    status: lerStatusOferta(dados.status),
    criado_em: converterTimestamp(dados.criado_em),
    atualizado_em: converterTimestamp(dados.atualizado_em),
  };
}

function montarTransacao(
  doc: admin.firestore.QueryDocumentSnapshot
): TransacaoConsultaBalcao {
  const dados = doc.data();

  return {
    transacao_id: doc.id,
    mercado: String(dados.mercado ?? ''),
    comprador_uid: String(dados.comprador_uid ?? ''),
    vendedor_uid: String(dados.vendedor_uid ?? ''),
    startup_id: String(dados.startup_id ?? ''),
    oferta_compra_id: String(dados.oferta_compra_id ?? ''),
    oferta_venda_id: String(dados.oferta_venda_id ?? ''),
    quantidade: lerInteiroNaoNegativo(dados.quantidade),
    valor_unitario_centavos: lerInteiroNaoNegativo(
      dados.valor_unitario_centavos
    ),
    valor_total_centavos: lerInteiroNaoNegativo(dados.valor_total_centavos),
    criado_em: converterTimestamp(dados.criado_em),
  };
}

function ordenarCompras(a: OfertaBookBalcao, b: OfertaBookBalcao): number {
  const preco = b.valor_unitario_centavos - a.valor_unitario_centavos;
  if (preco !== 0) return preco;
  return compararDatasAsc(a.criado_em, b.criado_em);
}

function ordenarVendas(a: OfertaBookBalcao, b: OfertaBookBalcao): number {
  const preco = a.valor_unitario_centavos - b.valor_unitario_centavos;
  if (preco !== 0) return preco;
  return compararDatasAsc(a.criado_em, b.criado_em);
}

function compararDatasAsc(a: string | null, b: string | null): number {
  return Date.parse(a ?? '') - Date.parse(b ?? '');
}

function compararDatasDesc(a: string | null, b: string | null): number {
  return Date.parse(b ?? '') - Date.parse(a ?? '');
}

function converterTimestamp(valor: unknown): string | null {
  if (
    valor &&
    typeof (valor as admin.firestore.Timestamp).toDate === 'function'
  ) {
    return (valor as admin.firestore.Timestamp).toDate().toISOString();
  }

  return null;
}

function normalizarId(valor: unknown, field: string): string {
  const id = typeof valor === 'string' ? valor.trim() : '';

  if (!id) {
    throw new ErroBalcao(400, 'Identificador obrigatorio.', field);
  }

  return id;
}

function lerTipoOferta(valor: unknown): TipoOferta {
  if (valor === TIPOS_OFERTA.compra || valor === TIPOS_OFERTA.venda) {
    return valor;
  }

  throw new ErroBalcao(409, 'Tipo de oferta inconsistente.');
}

function lerStatusOferta(valor: unknown): StatusOferta {
  if (
    valor === STATUS_OFERTA.aberta ||
    valor === STATUS_OFERTA.parcial ||
    valor === STATUS_OFERTA.executada ||
    valor === STATUS_OFERTA.cancelada
  ) {
    return valor;
  }

  throw new ErroBalcao(409, 'Status de oferta inconsistente.');
}

function lerInteiroNaoNegativo(valor: unknown): number {
  const numero = Number(valor ?? 0);

  if (!Number.isSafeInteger(numero) || numero < 0) {
    return 0;
  }

  return numero;
}
