// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Criacao de ofertas do balcao MesclaInvest

import * as admin from 'firebase-admin';
import type * as http from 'http';

import {
  COLECOES_BALCAO,
  STATUS_OFERTA,
  TIPOS_OFERTA,
  type OfertaFirestore,
} from './balcao_schema';
import {
  ErroBalcao,
  autenticarUsuarioBalcao,
  converterReaisParaCentavos,
  validarPrecoDentroDaFaixa,
  validarQuantidadeTokens,
  validarSaldoDisponivel,
  validarTokensDisponiveis,
  validarTipoOferta,
} from './balcao_validacoes';

interface CriarOfertaBalcaoBody {
  tipo?: unknown;
  startup_id?: unknown;
  quantidade?: unknown;
  valor_unitario?: unknown;
}

export interface OfertaCriadaBalcao {
  oferta_id: string;
  tipo: string;
  startup_id: string;
  quantidade_original: number;
  quantidade_restante: number;
  valor_unitario_centavos: number;
  status: string;
}

interface StartupBalcaoTransacao {
  id: string;
  precoReferenciaCentavos: number;
}

interface CarteiraBalcaoTransacao {
  saldoDisponivelCentavos: number;
  saldoBloqueadoCentavos: number;
}

interface AtivoBalcaoTransacao {
  quantidadeDisponivel: number;
  quantidadeBloqueada: number;
  valorMedioCentavos: number;
}

export async function criarOfertaBalcao(
  req: http.IncomingMessage,
  db: admin.firestore.Firestore,
  auth: admin.auth.Auth,
  body: CriarOfertaBalcaoBody
): Promise<OfertaCriadaBalcao> {
  const tipo = validarTipoOferta(body.tipo);

  if (tipo === TIPOS_OFERTA.compra) {
    return criarOfertaCompraBalcao(req, db, auth, body);
  }

  return criarOfertaVendaBalcao(req, db, auth, body);
}

export async function criarOfertaCompraBalcao(
  req: http.IncomingMessage,
  db: admin.firestore.Firestore,
  auth: admin.auth.Auth,
  body: CriarOfertaBalcaoBody
): Promise<OfertaCriadaBalcao> {
  const usuario = await autenticarUsuarioBalcao(req, auth);
  const tipo = validarTipoOferta(body.tipo);

  if (tipo !== TIPOS_OFERTA.compra) {
    throw new ErroBalcao(
      400,
      'Nesta etapa o endpoint aceita apenas ofertas de compra.',
      'tipo'
    );
  }

  const startupId = normalizarId(body.startup_id, 'startup_id');
  const quantidade = validarQuantidadeTokens(body.quantidade);
  const valorUnitarioCentavos = converterReaisParaCentavos(
    body.valor_unitario
  );
  const valorTotalCentavos = calcularValorTotalCentavos(
    quantidade,
    valorUnitarioCentavos
  );
  const ofertaRef = db.collection(COLECOES_BALCAO.ofertas).doc();

  await db.runTransaction(async (transaction) => {
    const startup = await carregarStartupAtiva(
      transaction,
      db,
      startupId
    );
    validarPrecoDentroDaFaixa(
      valorUnitarioCentavos,
      startup.precoReferenciaCentavos
    );

    const usuarioRef = db.collection(COLECOES_BALCAO.usuarios).doc(usuario.uid);
    const carteira = await carregarCarteira(
      transaction,
      usuarioRef
    );
    validarSaldoDisponivel(carteira, valorTotalCentavos);

    transaction.update(usuarioRef, {
      saldo_disponivel_centavos:
        carteira.saldoDisponivelCentavos - valorTotalCentavos,
      saldo_bloqueado_centavos:
        carteira.saldoBloqueadoCentavos + valorTotalCentavos,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(ofertaRef, montarOferta({
      tipo: TIPOS_OFERTA.compra,
      usuarioUid: usuario.uid,
      startupId: startup.id,
      quantidade,
      valorUnitarioCentavos,
    }));
  });

  return {
    oferta_id: ofertaRef.id,
    tipo: TIPOS_OFERTA.compra,
    startup_id: startupId,
    quantidade_original: quantidade,
    quantidade_restante: quantidade,
    valor_unitario_centavos: valorUnitarioCentavos,
    status: STATUS_OFERTA.aberta,
  };
}

export async function criarOfertaVendaBalcao(
  req: http.IncomingMessage,
  db: admin.firestore.Firestore,
  auth: admin.auth.Auth,
  body: CriarOfertaBalcaoBody
): Promise<OfertaCriadaBalcao> {
  const usuario = await autenticarUsuarioBalcao(req, auth);
  const tipo = validarTipoOferta(body.tipo);

  if (tipo !== TIPOS_OFERTA.venda) {
    throw new ErroBalcao(
      400,
      'Tipo de oferta invalido para venda.',
      'tipo'
    );
  }

  const startupId = normalizarId(body.startup_id, 'startup_id');
  const quantidade = validarQuantidadeTokens(body.quantidade);
  const valorUnitarioCentavos = converterReaisParaCentavos(
    body.valor_unitario
  );
  const ofertaRef = db.collection(COLECOES_BALCAO.ofertas).doc();

  await db.runTransaction(async (transaction) => {
    const startup = await carregarStartupAtiva(
      transaction,
      db,
      startupId
    );
    validarPrecoDentroDaFaixa(
      valorUnitarioCentavos,
      startup.precoReferenciaCentavos
    );

    const ativoRef = db
      .collection(COLECOES_BALCAO.usuarios)
      .doc(usuario.uid)
      .collection('ativos')
      .doc(startup.id);
    const ativo = await carregarAtivo(
      transaction,
      ativoRef
    );
    validarTokensDisponiveis(ativo, quantidade);

    transaction.set(ativoRef, {
      startup_id: startup.id,
      quantidade_disponivel: ativo.quantidadeDisponivel - quantidade,
      quantidade_bloqueada: ativo.quantidadeBloqueada + quantidade,
      valor_medio_centavos: ativo.valorMedioCentavos,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(ofertaRef, montarOferta({
      tipo: TIPOS_OFERTA.venda,
      usuarioUid: usuario.uid,
      startupId: startup.id,
      quantidade,
      valorUnitarioCentavos,
    }));
  });

  return {
    oferta_id: ofertaRef.id,
    tipo: TIPOS_OFERTA.venda,
    startup_id: startupId,
    quantidade_original: quantidade,
    quantidade_restante: quantidade,
    valor_unitario_centavos: valorUnitarioCentavos,
    status: STATUS_OFERTA.aberta,
  };
}

function montarOferta(params: {
  tipo: typeof TIPOS_OFERTA.compra | typeof TIPOS_OFERTA.venda;
  usuarioUid: string;
  startupId: string;
  quantidade: number;
  valorUnitarioCentavos: number;
}): OfertaFirestore {
  const timestamp = admin.firestore.FieldValue.serverTimestamp();

  return {
    tipo: params.tipo,
    usuario_uid: params.usuarioUid,
    startup_id: params.startupId,
    quantidade_original: params.quantidade,
    quantidade_restante: params.quantidade,
    valor_unitario_centavos: params.valorUnitarioCentavos,
    status: STATUS_OFERTA.aberta,
    criado_em: timestamp,
    atualizado_em: timestamp,
  };
}

async function carregarAtivo(
  transaction: admin.firestore.Transaction,
  ativoRef: admin.firestore.DocumentReference
): Promise<AtivoBalcaoTransacao> {
  const doc = await transaction.get(ativoRef);
  const dados = doc.exists ? doc.data() ?? {} : {};

  return {
    quantidadeDisponivel: lerInteiroNaoNegativo(
      dados.quantidade_disponivel
    ),
    quantidadeBloqueada: lerInteiroNaoNegativo(
      dados.quantidade_bloqueada
    ),
    valorMedioCentavos: lerInteiroNaoNegativo(dados.valor_medio_centavos),
  };
}

async function carregarStartupAtiva(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  startupId: string
): Promise<StartupBalcaoTransacao> {
  const startupRef = db.collection(COLECOES_BALCAO.startups).doc(startupId);
  const doc = await transaction.get(startupRef);

  if (!doc.exists) {
    throw new ErroBalcao(404, 'Startup nao encontrada.', 'startup_id');
  }

  const dados = doc.data() ?? {};

  if (String(dados.status ?? '') !== 'ativa') {
    throw new ErroBalcao(404, 'Startup nao encontrada.', 'startup_id');
  }

  const precoAtualCentavos = lerInteiroNaoNegativo(
    dados.preco_atual_centavos
  );
  const precoPrimarioCentavos = lerInteiroNaoNegativo(
    dados.preco_primario_centavos
  );
  const precoReferenciaCentavos =
    precoAtualCentavos > 0 ? precoAtualCentavos : precoPrimarioCentavos;

  if (precoReferenciaCentavos <= 0) {
    throw new ErroBalcao(
      400,
      'Startup ainda nao possui preco de referencia para o balcao.',
      'startup_id'
    );
  }

  return {
    id: startupId,
    precoReferenciaCentavos,
  };
}

async function carregarCarteira(
  transaction: admin.firestore.Transaction,
  usuarioRef: admin.firestore.DocumentReference
): Promise<CarteiraBalcaoTransacao> {
  const doc = await transaction.get(usuarioRef);

  if (!doc.exists) {
    throw new ErroBalcao(404, 'Usuario nao encontrado.');
  }

  const dados = doc.data() ?? {};

  return {
    saldoDisponivelCentavos: lerInteiroNaoNegativo(
      dados.saldo_disponivel_centavos
    ),
    saldoBloqueadoCentavos: lerInteiroNaoNegativo(
      dados.saldo_bloqueado_centavos
    ),
  };
}

function normalizarId(valor: unknown, field: string): string {
  const id = typeof valor === 'string' ? valor.trim() : '';

  if (!id) {
    throw new ErroBalcao(400, 'Identificador obrigatorio.', field);
  }

  return id;
}

function calcularValorTotalCentavos(
  quantidade: number,
  valorUnitarioCentavos: number
): number {
  const valorTotalCentavos = quantidade * valorUnitarioCentavos;

  if (!Number.isSafeInteger(valorTotalCentavos)) {
    throw new ErroBalcao(
      400,
      'Valor total da oferta ultrapassa o limite permitido.'
    );
  }

  return valorTotalCentavos;
}

function lerInteiroNaoNegativo(valor: unknown): number {
  const numero = Number(valor ?? 0);

  if (!Number.isSafeInteger(numero) || numero < 0) {
    return 0;
  }

  return numero;
}
