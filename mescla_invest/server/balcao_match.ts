// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Motor de match e liquidacao do balcao MesclaInvest

import * as admin from 'firebase-admin';

import {
  COLECOES_BALCAO,
  MERCADOS_TRANSACAO,
  STATUS_OFERTA,
  TIPOS_OFERTA,
  type OfertaFirestore,
  type StatusOferta,
  type TipoOferta,
  type TransacaoBalcaoFirestore,
} from './balcao_schema';
import { ErroBalcao } from './balcao_validacoes';

const MAX_CANDIDATOS_MATCH = 100;
const MAX_TRANSACOES_POR_MATCH = 20;

interface OfertaMatch {
  id: string;
  ref: admin.firestore.DocumentReference;
  tipo: TipoOferta;
  usuarioUid: string;
  startupId: string;
  quantidadeOriginal: number;
  quantidadeRestante: number;
  valorUnitarioCentavos: number;
  status: StatusOferta;
  criadoEmMs: number;
}

interface EstadoUsuario {
  ref: admin.firestore.DocumentReference;
  saldoDisponivelCentavos: number;
  saldoBloqueadoCentavos: number;
}

interface EstadoAtivo {
  ref: admin.firestore.DocumentReference;
  startupId: string;
  quantidadeDisponivel: number;
  quantidadeBloqueada: number;
  valorMedioCentavos: number;
}

interface TransacaoPendente {
  compradorUid: string;
  vendedorUid: string;
  ofertaCompraId: string;
  ofertaVendaId: string;
  quantidade: number;
  valorUnitarioCentavos: number;
  valorTotalCentavos: number;
}

export interface ResultadoMatchBalcao {
  status: StatusOferta;
  quantidade_restante: number;
  quantidade_executada: number;
  transacoes_executadas: number;
}

export async function executarMatchBalcao(
  db: admin.firestore.Firestore,
  ofertaId: string
): Promise<ResultadoMatchBalcao> {
  return db.runTransaction(async (transaction) => {
    const ofertaRef = db.collection(COLECOES_BALCAO.ofertas).doc(ofertaId);
    const ofertaDoc = await transaction.get(ofertaRef);

    if (!ofertaDoc.exists) {
      throw new ErroBalcao(404, 'Oferta nao encontrada.');
    }

    const ofertaPrincipal = montarOfertaMatch(ofertaDoc);

    if (!ofertaPodeExecutar(ofertaPrincipal)) {
      return montarResultado(ofertaPrincipal, 0, 0);
    }

    const candidatosSnapshot = await transaction.get(
      db
        .collection(COLECOES_BALCAO.ofertas)
        .where('startup_id', '==', ofertaPrincipal.startupId)
        .limit(MAX_CANDIDATOS_MATCH)
    );
    const candidatos = candidatosSnapshot.docs
      .map(montarOfertaMatch)
      .filter((oferta) => oferta.id !== ofertaPrincipal.id)
      .filter((oferta) => ofertaPodeExecutar(oferta))
      .filter((oferta) => oferta.tipo !== ofertaPrincipal.tipo)
      .filter((oferta) => oferta.usuarioUid !== ofertaPrincipal.usuarioUid)
      .filter((oferta) => ofertaCompativel(ofertaPrincipal, oferta))
      .sort((a, b) => compararPrioridade(ofertaPrincipal.tipo, a, b));
    const ofertasSelecionadas = selecionarOfertasParaExecucao(
      ofertaPrincipal,
      candidatos
    );

    if (ofertasSelecionadas.length === 0) {
      return montarResultado(ofertaPrincipal, 0, 0);
    }

    const usuarios = await carregarUsuarios(
      transaction,
      db,
      ofertaPrincipal,
      ofertasSelecionadas
    );
    const ativos = await carregarAtivos(
      transaction,
      db,
      ofertaPrincipal,
      ofertasSelecionadas
    );
    const ofertas = new Map<string, OfertaMatch>([
      [ofertaPrincipal.id, { ...ofertaPrincipal }],
      ...ofertasSelecionadas.map((oferta) => [oferta.id, { ...oferta }] as const),
    ]);
    const transacoes = liquidarOfertas(
      ofertaPrincipal,
      ofertasSelecionadas,
      ofertas,
      usuarios,
      ativos
    );

    escreverUsuarios(transaction, usuarios);
    escreverAtivos(transaction, ativos);
    escreverOfertas(transaction, ofertas);
    escreverTransacoes(transaction, db, ofertaPrincipal.startupId, transacoes);
    atualizarPrecoAtual(transaction, db, ofertaPrincipal.startupId, transacoes);

    const ofertaFinal = ofertas.get(ofertaPrincipal.id) ?? ofertaPrincipal;

    return montarResultado(
      ofertaFinal,
      ofertaPrincipal.quantidadeRestante - ofertaFinal.quantidadeRestante,
      transacoes.length
    );
  });
}

function montarOfertaMatch(
  doc: admin.firestore.QueryDocumentSnapshot | admin.firestore.DocumentSnapshot
): OfertaMatch {
  const dados = doc.data() as Partial<OfertaFirestore> | undefined;

  if (!dados) {
    throw new ErroBalcao(404, 'Oferta nao encontrada.');
  }

  return {
    id: doc.id,
    ref: doc.ref,
    tipo: lerTipoOferta(dados.tipo),
    usuarioUid: String(dados.usuario_uid ?? ''),
    startupId: String(dados.startup_id ?? ''),
    quantidadeOriginal: lerInteiroPositivo(dados.quantidade_original),
    quantidadeRestante: lerInteiroNaoNegativo(dados.quantidade_restante),
    valorUnitarioCentavos: lerInteiroPositivo(dados.valor_unitario_centavos),
    status: lerStatusOferta(dados.status),
    criadoEmMs: lerTimestampMs(dados.criado_em),
  };
}

function ofertaPodeExecutar(oferta: OfertaMatch): boolean {
  return (
    (oferta.status === STATUS_OFERTA.aberta ||
      oferta.status === STATUS_OFERTA.parcial) &&
    oferta.quantidadeRestante > 0
  );
}

function ofertaCompativel(
  principal: OfertaMatch,
  candidata: OfertaMatch
): boolean {
  if (principal.tipo === TIPOS_OFERTA.compra) {
    return candidata.valorUnitarioCentavos <= principal.valorUnitarioCentavos;
  }

  return candidata.valorUnitarioCentavos >= principal.valorUnitarioCentavos;
}

function compararPrioridade(
  tipoPrincipal: TipoOferta,
  a: OfertaMatch,
  b: OfertaMatch
): number {
  const diferencaPreco = tipoPrincipal === TIPOS_OFERTA.compra
    ? a.valorUnitarioCentavos - b.valorUnitarioCentavos
    : b.valorUnitarioCentavos - a.valorUnitarioCentavos;

  if (diferencaPreco !== 0) {
    return diferencaPreco;
  }

  return a.criadoEmMs - b.criadoEmMs;
}

function selecionarOfertasParaExecucao(
  principal: OfertaMatch,
  candidatas: OfertaMatch[]
): OfertaMatch[] {
  const selecionadas: OfertaMatch[] = [];
  let quantidadeRestante = principal.quantidadeRestante;

  for (const candidata of candidatas) {
    if (quantidadeRestante <= 0) break;
    if (selecionadas.length >= MAX_TRANSACOES_POR_MATCH) break;

    selecionadas.push(candidata);
    quantidadeRestante -= Math.min(
      quantidadeRestante,
      candidata.quantidadeRestante
    );
  }

  return selecionadas;
}

async function carregarUsuarios(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  principal: OfertaMatch,
  candidatas: OfertaMatch[]
): Promise<Map<string, EstadoUsuario>> {
  const uids = new Set<string>([
    principal.usuarioUid,
    ...candidatas.map((oferta) => oferta.usuarioUid),
  ]);
  const usuarios = new Map<string, EstadoUsuario>();

  for (const uid of uids) {
    const ref = db.collection(COLECOES_BALCAO.usuarios).doc(uid);
    const doc = await transaction.get(ref);

    if (!doc.exists) {
      throw new ErroBalcao(409, 'Usuario da oferta nao encontrado.');
    }

    const dados = doc.data() ?? {};
    usuarios.set(uid, {
      ref,
      saldoDisponivelCentavos: lerInteiroNaoNegativo(
        dados.saldo_disponivel_centavos
      ),
      saldoBloqueadoCentavos: lerInteiroNaoNegativo(
        dados.saldo_bloqueado_centavos
      ),
    });
  }

  return usuarios;
}

async function carregarAtivos(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  principal: OfertaMatch,
  candidatas: OfertaMatch[]
): Promise<Map<string, EstadoAtivo>> {
  const ativos = new Map<string, EstadoAtivo>();
  const uids = new Set<string>([
    principal.usuarioUid,
    ...candidatas.map((oferta) => oferta.usuarioUid),
  ]);

  for (const uid of uids) {
    const ref = db
      .collection(COLECOES_BALCAO.usuarios)
      .doc(uid)
      .collection('ativos')
      .doc(principal.startupId);
    const doc = await transaction.get(ref);
    const dados = doc.exists ? doc.data() ?? {} : {};

    ativos.set(montarChaveAtivo(uid, principal.startupId), {
      ref,
      startupId: principal.startupId,
      quantidadeDisponivel: lerInteiroNaoNegativo(
        dados.quantidade_disponivel
      ),
      quantidadeBloqueada: lerInteiroNaoNegativo(
        dados.quantidade_bloqueada
      ),
      valorMedioCentavos: lerInteiroNaoNegativo(dados.valor_medio_centavos),
    });
  }

  return ativos;
}

function liquidarOfertas(
  principal: OfertaMatch,
  candidatas: OfertaMatch[],
  ofertas: Map<string, OfertaMatch>,
  usuarios: Map<string, EstadoUsuario>,
  ativos: Map<string, EstadoAtivo>
): TransacaoPendente[] {
  const transacoes: TransacaoPendente[] = [];
  const ofertaPrincipal = obterOferta(ofertas, principal.id);

  for (const candidataOriginal of candidatas) {
    if (ofertaPrincipal.quantidadeRestante <= 0) break;

    const candidata = obterOferta(ofertas, candidataOriginal.id);
    const quantidadeExecutada = Math.min(
      ofertaPrincipal.quantidadeRestante,
      candidata.quantidadeRestante
    );

    if (quantidadeExecutada <= 0) continue;

    const ofertaCompra = ofertaPrincipal.tipo === TIPOS_OFERTA.compra
      ? ofertaPrincipal
      : candidata;
    const ofertaVenda = ofertaPrincipal.tipo === TIPOS_OFERTA.venda
      ? ofertaPrincipal
      : candidata;
    const valorUnitarioCentavos = candidata.valorUnitarioCentavos;

    liquidarTransferencia({
      ofertaCompra,
      ofertaVenda,
      quantidadeExecutada,
      valorUnitarioCentavos,
      usuarios,
      ativos,
    });

    ofertaPrincipal.quantidadeRestante -= quantidadeExecutada;
    candidata.quantidadeRestante -= quantidadeExecutada;
    ofertaPrincipal.status = calcularStatusOferta(ofertaPrincipal);
    candidata.status = calcularStatusOferta(candidata);

    transacoes.push({
      compradorUid: ofertaCompra.usuarioUid,
      vendedorUid: ofertaVenda.usuarioUid,
      ofertaCompraId: ofertaCompra.id,
      ofertaVendaId: ofertaVenda.id,
      quantidade: quantidadeExecutada,
      valorUnitarioCentavos,
      valorTotalCentavos: quantidadeExecutada * valorUnitarioCentavos,
    });
  }

  return transacoes;
}

function liquidarTransferencia(params: {
  ofertaCompra: OfertaMatch;
  ofertaVenda: OfertaMatch;
  quantidadeExecutada: number;
  valorUnitarioCentavos: number;
  usuarios: Map<string, EstadoUsuario>;
  ativos: Map<string, EstadoAtivo>;
}): void {
  const comprador = obterUsuario(params.usuarios, params.ofertaCompra.usuarioUid);
  const vendedor = obterUsuario(params.usuarios, params.ofertaVenda.usuarioUid);
  const ativoComprador = obterAtivo(
    params.ativos,
    params.ofertaCompra.usuarioUid,
    params.ofertaCompra.startupId
  );
  const ativoVendedor = obterAtivo(
    params.ativos,
    params.ofertaVenda.usuarioUid,
    params.ofertaVenda.startupId
  );
  const valorBloqueadoCompra =
    params.quantidadeExecutada * params.ofertaCompra.valorUnitarioCentavos;
  const valorExecutado =
    params.quantidadeExecutada * params.valorUnitarioCentavos;
  const diferencaCompra = valorBloqueadoCompra - valorExecutado;

  garantirSaldoBloqueado(comprador, valorBloqueadoCompra);
  garantirTokensBloqueados(ativoVendedor, params.quantidadeExecutada);

  comprador.saldoBloqueadoCentavos -= valorBloqueadoCompra;
  comprador.saldoDisponivelCentavos += diferencaCompra;
  vendedor.saldoDisponivelCentavos += valorExecutado;
  ativoVendedor.quantidadeBloqueada -= params.quantidadeExecutada;
  atualizarAtivoComprador(
    ativoComprador,
    params.quantidadeExecutada,
    params.valorUnitarioCentavos
  );
}

function atualizarAtivoComprador(
  ativo: EstadoAtivo,
  quantidadeComprada: number,
  valorUnitarioCentavos: number
): void {
  const quantidadeAtual =
    ativo.quantidadeDisponivel + ativo.quantidadeBloqueada;
  const quantidadeFinal = quantidadeAtual + quantidadeComprada;

  if (quantidadeFinal <= 0) {
    ativo.valorMedioCentavos = 0;
  } else {
    ativo.valorMedioCentavos = Math.round(
      (
        (quantidadeAtual * ativo.valorMedioCentavos) +
        (quantidadeComprada * valorUnitarioCentavos)
      ) / quantidadeFinal
    );
  }

  ativo.quantidadeDisponivel += quantidadeComprada;
}

function escreverUsuarios(
  transaction: admin.firestore.Transaction,
  usuarios: Map<string, EstadoUsuario>
): void {
  usuarios.forEach((usuario) => {
    transaction.update(usuario.ref, {
      saldo_disponivel_centavos: usuario.saldoDisponivelCentavos,
      saldo_bloqueado_centavos: usuario.saldoBloqueadoCentavos,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

function escreverAtivos(
  transaction: admin.firestore.Transaction,
  ativos: Map<string, EstadoAtivo>
): void {
  ativos.forEach((ativo) => {
    transaction.set(ativo.ref, {
      startup_id: ativo.startupId,
      quantidade_disponivel: ativo.quantidadeDisponivel,
      quantidade_bloqueada: ativo.quantidadeBloqueada,
      valor_medio_centavos: ativo.valorMedioCentavos,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

function escreverOfertas(
  transaction: admin.firestore.Transaction,
  ofertas: Map<string, OfertaMatch>
): void {
  ofertas.forEach((oferta) => {
    transaction.update(oferta.ref, {
      quantidade_restante: oferta.quantidadeRestante,
      status: oferta.status,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

function escreverTransacoes(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  startupId: string,
  transacoes: TransacaoPendente[]
): void {
  transacoes.forEach((transacao) => {
    const transacaoRef = db.collection(COLECOES_BALCAO.transacoes).doc();
    const registro: TransacaoBalcaoFirestore = {
      mercado: MERCADOS_TRANSACAO.secundario,
      comprador_uid: transacao.compradorUid,
      vendedor_uid: transacao.vendedorUid,
      startup_id: startupId,
      oferta_compra_id: transacao.ofertaCompraId,
      oferta_venda_id: transacao.ofertaVendaId,
      quantidade: transacao.quantidade,
      valor_unitario_centavos: transacao.valorUnitarioCentavos,
      valor_total_centavos: transacao.valorTotalCentavos,
      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.set(transacaoRef, registro);
  });
}

function atualizarPrecoAtual(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  startupId: string,
  transacoes: TransacaoPendente[]
): void {
  const ultimaTransacao = transacoes[transacoes.length - 1];

  if (!ultimaTransacao) return;

  transaction.update(db.collection(COLECOES_BALCAO.startups).doc(startupId), {
    preco_atual_centavos: ultimaTransacao.valorUnitarioCentavos,
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function calcularStatusOferta(oferta: OfertaMatch): StatusOferta {
  if (oferta.quantidadeRestante <= 0) {
    return STATUS_OFERTA.executada;
  }

  if (oferta.quantidadeRestante < oferta.quantidadeOriginal) {
    return STATUS_OFERTA.parcial;
  }

  return STATUS_OFERTA.aberta;
}

function montarResultado(
  oferta: OfertaMatch,
  quantidadeExecutada: number,
  totalTransacoes: number
): ResultadoMatchBalcao {
  return {
    status: oferta.status,
    quantidade_restante: oferta.quantidadeRestante,
    quantidade_executada: quantidadeExecutada,
    transacoes_executadas: totalTransacoes,
  };
}

function obterOferta(
  ofertas: Map<string, OfertaMatch>,
  ofertaId: string
): OfertaMatch {
  const oferta = ofertas.get(ofertaId);

  if (!oferta) {
    throw new ErroBalcao(409, 'Oferta inconsistente durante a liquidacao.');
  }

  return oferta;
}

function obterUsuario(
  usuarios: Map<string, EstadoUsuario>,
  uid: string
): EstadoUsuario {
  const usuario = usuarios.get(uid);

  if (!usuario) {
    throw new ErroBalcao(409, 'Usuario inconsistente durante a liquidacao.');
  }

  return usuario;
}

function obterAtivo(
  ativos: Map<string, EstadoAtivo>,
  uid: string,
  startupId: string
): EstadoAtivo {
  const ativo = ativos.get(montarChaveAtivo(uid, startupId));

  if (!ativo) {
    throw new ErroBalcao(409, 'Ativo inconsistente durante a liquidacao.');
  }

  return ativo;
}

function garantirSaldoBloqueado(
  usuario: EstadoUsuario,
  valorNecessarioCentavos: number
): void {
  if (usuario.saldoBloqueadoCentavos < valorNecessarioCentavos) {
    throw new ErroBalcao(
      409,
      'Saldo bloqueado inconsistente para liquidar a oferta.'
    );
  }
}

function garantirTokensBloqueados(
  ativo: EstadoAtivo,
  quantidadeNecessaria: number
): void {
  if (ativo.quantidadeBloqueada < quantidadeNecessaria) {
    throw new ErroBalcao(
      409,
      'Tokens bloqueados inconsistentes para liquidar a oferta.'
    );
  }
}

function montarChaveAtivo(uid: string, startupId: string): string {
  return `${uid}:${startupId}`;
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

function lerInteiroPositivo(valor: unknown): number {
  const numero = Number(valor);

  if (!Number.isSafeInteger(numero) || numero <= 0) {
    throw new ErroBalcao(409, 'Numero positivo esperado na oferta.');
  }

  return numero;
}

function lerInteiroNaoNegativo(valor: unknown): number {
  const numero = Number(valor ?? 0);

  if (!Number.isSafeInteger(numero) || numero < 0) {
    throw new ErroBalcao(409, 'Numero nao negativo esperado na oferta.');
  }

  return numero;
}

function lerTimestampMs(valor: unknown): number {
  if (
    valor &&
    typeof (valor as admin.firestore.Timestamp).toMillis === 'function'
  ) {
    return (valor as admin.firestore.Timestamp).toMillis();
  }

  return 0;
}
