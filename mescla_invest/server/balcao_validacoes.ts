// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Validacoes e seguranca do balcao MesclaInvest

import type * as http from 'http';
import type * as admin from 'firebase-admin';

import {
  COLECOES_BALCAO,
  LIMITE_PRECO_MAX_PERCENTUAL,
  LIMITE_PRECO_MIN_PERCENTUAL,
  TIPOS_OFERTA,
  type TipoOferta,
} from './balcao_schema';

export class ErroBalcao extends Error {
  readonly statusCode: number;
  readonly field?: string;

  constructor(statusCode: number, message: string, field?: string) {
    super(message);
    this.name = 'ErroBalcao';
    this.statusCode = statusCode;
    this.field = field;
  }
}

export interface UsuarioAutenticadoBalcao {
  uid: string;
  email?: string;
}

export interface StartupReferenciaBalcao {
  id: string;
  status: string;
  precoAtualCentavos: number;
  precoPrimarioCentavos: number;
  precoReferenciaCentavos: number;
}

export interface CarteiraBalcao {
  saldoDisponivelCentavos: number;
  saldoBloqueadoCentavos: number;
}

export interface AtivoBalcao {
  quantidadeDisponivel: number;
  quantidadeBloqueada: number;
  valorMedioCentavos: number;
}

export function extrairBearerToken(
  authorizationHeader: string | string[] | undefined
): string {
  const header = Array.isArray(authorizationHeader)
    ? authorizationHeader[0]
    : authorizationHeader;

  if (!header) {
    throw new ErroBalcao(401, 'Token de autenticacao nao informado.');
  }

  const [tipo, token] = header.trim().split(/\s+/);

  if (tipo !== 'Bearer' || !token) {
    throw new ErroBalcao(401, 'Token de autenticacao invalido.');
  }

  return token;
}

export async function autenticarUsuarioBalcao(
  req: http.IncomingMessage,
  auth: admin.auth.Auth
): Promise<UsuarioAutenticadoBalcao> {
  const token = extrairBearerToken(req.headers.authorization);

  try {
    const decodedToken = await auth.verifyIdToken(token);
    return {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };
  } catch {
    throw new ErroBalcao(401, 'Token de autenticacao expirado ou invalido.');
  }
}

export function validarTipoOferta(tipo: unknown): TipoOferta {
  if (tipo === TIPOS_OFERTA.compra || tipo === TIPOS_OFERTA.venda) {
    return tipo;
  }

  throw new ErroBalcao(
    400,
    'Tipo de oferta deve ser compra ou venda.',
    'tipo'
  );
}

export function validarQuantidadeTokens(quantidade: unknown): number {
  const valor = typeof quantidade === 'number'
    ? quantidade
    : Number(quantidade);

  if (!Number.isInteger(valor) || valor <= 0) {
    throw new ErroBalcao(
      400,
      'Quantidade de tokens deve ser um numero inteiro positivo.',
      'quantidade'
    );
  }

  return valor;
}

export function converterReaisParaCentavos(
  valor: unknown,
  field = 'valor_unitario'
): number {
  const numero = typeof valor === 'string'
    ? Number(valor.replace(',', '.'))
    : Number(valor);

  if (!Number.isFinite(numero)) {
    throw new ErroBalcao(400, 'Valor monetario invalido.', field);
  }

  const centavos = Math.round(numero * 100);

  if (!Number.isSafeInteger(centavos) || centavos <= 0) {
    throw new ErroBalcao(
      400,
      'Valor monetario deve ser maior que zero.',
      field
    );
  }

  return centavos;
}

export async function buscarStartupAtivaBalcao(
  db: admin.firestore.Firestore,
  startupId: unknown
): Promise<StartupReferenciaBalcao> {
  const id = normalizarId(startupId, 'startup_id');
  const doc = await db.collection(COLECOES_BALCAO.startups).doc(id).get();

  if (!doc.exists) {
    throw new ErroBalcao(404, 'Startup nao encontrada.', 'startup_id');
  }

  const dados = doc.data() ?? {};
  const status = String(dados.status ?? '');

  if (status !== 'ativa') {
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
    id,
    status,
    precoAtualCentavos,
    precoPrimarioCentavos,
    precoReferenciaCentavos,
  };
}

export function validarPrecoDentroDaFaixa(
  valorUnitarioCentavos: number,
  precoReferenciaCentavos: number
): void {
  const precoMinimo = Math.max(
    1,
    Math.ceil((precoReferenciaCentavos * LIMITE_PRECO_MIN_PERCENTUAL) / 100)
  );
  const precoMaximo = Math.floor(
    (precoReferenciaCentavos * LIMITE_PRECO_MAX_PERCENTUAL) / 100
  );

  if (
    valorUnitarioCentavos < precoMinimo ||
    valorUnitarioCentavos > precoMaximo
  ) {
    throw new ErroBalcao(
      400,
      `Preco deve estar entre ${precoMinimo} e ${precoMaximo} centavos.`,
      'valor_unitario'
    );
  }
}

export async function buscarCarteiraBalcao(
  db: admin.firestore.Firestore,
  uid: string
): Promise<CarteiraBalcao> {
  const doc = await db.collection(COLECOES_BALCAO.usuarios).doc(uid).get();

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

export async function buscarAtivoBalcao(
  db: admin.firestore.Firestore,
  uid: string,
  startupId: string
): Promise<AtivoBalcao> {
  const doc = await db
    .collection(COLECOES_BALCAO.usuarios)
    .doc(uid)
    .collection('ativos')
    .doc(startupId)
    .get();

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

export function validarSaldoDisponivel(
  carteira: CarteiraBalcao,
  valorNecessarioCentavos: number
): void {
  if (carteira.saldoDisponivelCentavos < valorNecessarioCentavos) {
    throw new ErroBalcao(
      400,
      'Saldo disponivel insuficiente para criar a oferta.',
      'saldo'
    );
  }
}

export function validarTokensDisponiveis(
  ativo: AtivoBalcao,
  quantidadeNecessaria: number
): void {
  if (ativo.quantidadeDisponivel < quantidadeNecessaria) {
    throw new ErroBalcao(
      400,
      'Quantidade de tokens disponivel insuficiente para criar a oferta.',
      'quantidade'
    );
  }
}

export function validarUsuariosDiferentes(
  usuarioUid: string,
  contraparteUid: string
): void {
  if (usuarioUid === contraparteUid) {
    throw new ErroBalcao(
      400,
      'Nao e permitido executar uma oferta contra o proprio usuario.'
    );
  }
}

function normalizarId(valor: unknown, field: string): string {
  const id = typeof valor === 'string' ? valor.trim() : '';

  if (!id) {
    throw new ErroBalcao(400, 'Identificador obrigatorio.', field);
  }

  return id;
}

function lerInteiroNaoNegativo(valor: unknown): number {
  const numero = Number(valor ?? 0);

  if (!Number.isSafeInteger(numero) || numero < 0) {
    return 0;
  }

  return numero;
}
