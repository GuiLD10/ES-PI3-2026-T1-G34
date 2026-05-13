// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Cancelamento de ofertas do balcao MesclaInvest

import * as admin from 'firebase-admin';
import type * as http from 'http';

import {
  COLECOES_BALCAO,
  STATUS_OFERTA,
  TIPOS_OFERTA,
  type TipoOferta,
} from './balcao_schema';
import {
  ErroBalcao,
  autenticarUsuarioBalcao,
} from './balcao_validacoes';

export interface OfertaCanceladaBalcao {
  oferta_id: string;
  status: typeof STATUS_OFERTA.cancelada;
  quantidade_restante: number;
}

interface OfertaCancelamento {
  tipo: TipoOferta;
  usuarioUid: string;
  startupId: string;
  quantidadeRestante: number;
  valorUnitarioCentavos: number;
  status: string;
}

interface CarteiraCancelamento {
  saldoDisponivelCentavos: number;
  saldoBloqueadoCentavos: number;
}

interface AtivoCancelamento {
  quantidadeDisponivel: number;
  quantidadeBloqueada: number;
  valorMedioCentavos: number;
}

export async function cancelarOfertaBalcao(
  req: http.IncomingMessage,
  db: admin.firestore.Firestore,
  auth: admin.auth.Auth,
  ofertaId: string
): Promise<OfertaCanceladaBalcao> {
  const usuario = await autenticarUsuarioBalcao(req, auth);
  const id = normalizarId(ofertaId, 'oferta_id');

  await db.runTransaction(async (transaction) => {
    const ofertaRef = db.collection(COLECOES_BALCAO.ofertas).doc(id);
    const ofertaDoc = await transaction.get(ofertaRef);

    if (!ofertaDoc.exists) {
      throw new ErroBalcao(404, 'Oferta nao encontrada.', 'oferta_id');
    }

    const oferta = montarOfertaCancelamento(ofertaDoc.data() ?? {});

    if (oferta.usuarioUid !== usuario.uid) {
      throw new ErroBalcao(403, 'Oferta pertence a outro usuario.');
    }

    if (
      oferta.status !== STATUS_OFERTA.aberta &&
      oferta.status !== STATUS_OFERTA.parcial
    ) {
      throw new ErroBalcao(
        400,
        'Apenas ofertas abertas ou parciais podem ser canceladas.'
      );
    }

    if (oferta.quantidadeRestante <= 0) {
      throw new ErroBalcao(
        400,
        'Oferta sem quantidade restante para cancelar.'
      );
    }

    if (oferta.tipo === TIPOS_OFERTA.compra) {
      await liberarSaldoCompra(transaction, db, oferta);
    } else {
      await liberarTokensVenda(transaction, db, oferta);
    }

    transaction.update(ofertaRef, {
      status: STATUS_OFERTA.cancelada,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    oferta_id: id,
    status: STATUS_OFERTA.cancelada,
    quantidade_restante: 0,
  };
}

async function liberarSaldoCompra(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  oferta: OfertaCancelamento
): Promise<void> {
  const usuarioRef = db
    .collection(COLECOES_BALCAO.usuarios)
    .doc(oferta.usuarioUid);
  const usuarioDoc = await transaction.get(usuarioRef);

  if (!usuarioDoc.exists) {
    throw new ErroBalcao(409, 'Usuario da oferta nao encontrado.');
  }

  const carteira = montarCarteira(usuarioDoc.data() ?? {});
  const valorLiberado = oferta.quantidadeRestante * oferta.valorUnitarioCentavos;

  if (carteira.saldoBloqueadoCentavos < valorLiberado) {
    throw new ErroBalcao(
      409,
      'Saldo bloqueado inconsistente para cancelar a oferta.'
    );
  }

  transaction.update(usuarioRef, {
    saldo_disponivel_centavos:
      carteira.saldoDisponivelCentavos + valorLiberado,
    saldo_bloqueado_centavos:
      carteira.saldoBloqueadoCentavos - valorLiberado,
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function liberarTokensVenda(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  oferta: OfertaCancelamento
): Promise<void> {
  const ativoRef = db
    .collection(COLECOES_BALCAO.usuarios)
    .doc(oferta.usuarioUid)
    .collection('ativos')
    .doc(oferta.startupId);
  const ativoDoc = await transaction.get(ativoRef);
  const ativo = montarAtivo(ativoDoc.exists ? ativoDoc.data() ?? {} : {});

  if (ativo.quantidadeBloqueada < oferta.quantidadeRestante) {
    throw new ErroBalcao(
      409,
      'Tokens bloqueados inconsistentes para cancelar a oferta.'
    );
  }

  transaction.set(ativoRef, {
    startup_id: oferta.startupId,
    quantidade_disponivel:
      ativo.quantidadeDisponivel + oferta.quantidadeRestante,
    quantidade_bloqueada:
      ativo.quantidadeBloqueada - oferta.quantidadeRestante,
    valor_medio_centavos: ativo.valorMedioCentavos,
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

function montarOfertaCancelamento(
  dados: admin.firestore.DocumentData
): OfertaCancelamento {
  return {
    tipo: lerTipoOferta(dados.tipo),
    usuarioUid: String(dados.usuario_uid ?? ''),
    startupId: String(dados.startup_id ?? ''),
    quantidadeRestante: lerInteiroNaoNegativo(dados.quantidade_restante),
    valorUnitarioCentavos: lerInteiroPositivo(dados.valor_unitario_centavos),
    status: String(dados.status ?? ''),
  };
}

function montarCarteira(
  dados: admin.firestore.DocumentData
): CarteiraCancelamento {
  return {
    saldoDisponivelCentavos: lerInteiroNaoNegativo(
      dados.saldo_disponivel_centavos
    ),
    saldoBloqueadoCentavos: lerInteiroNaoNegativo(
      dados.saldo_bloqueado_centavos
    ),
  };
}

function montarAtivo(dados: admin.firestore.DocumentData): AtivoCancelamento {
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
    throw new ErroBalcao(409, 'Numero nao negativo esperado.');
  }

  return numero;
}
