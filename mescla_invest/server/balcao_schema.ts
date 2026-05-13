// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Contratos de dados do balcao MesclaInvest

import type * as admin from 'firebase-admin';

export const COLECOES_BALCAO = {
  ofertas: 'ofertas',
  transacoes: 'transacoes',
  usuarios: 'usuarios',
  startups: 'startups',
} as const;

export const TIPOS_OFERTA = {
  compra: 'compra',
  venda: 'venda',
} as const;

export const STATUS_OFERTA = {
  aberta: 'aberta',
  parcial: 'parcial',
  executada: 'executada',
  cancelada: 'cancelada',
} as const;

export const MERCADOS_TRANSACAO = {
  primario: 'primario',
  secundario: 'secundario',
} as const;

export const LIMITE_PRECO_MIN_PERCENTUAL = 50;
export const LIMITE_PRECO_MAX_PERCENTUAL = 200;

export type TipoOferta = typeof TIPOS_OFERTA[keyof typeof TIPOS_OFERTA];
export type StatusOferta = typeof STATUS_OFERTA[keyof typeof STATUS_OFERTA];
export type MercadoTransacao =
  typeof MERCADOS_TRANSACAO[keyof typeof MERCADOS_TRANSACAO];
export type CampoTimestamp =
  | admin.firestore.Timestamp
  | admin.firestore.FieldValue;

export interface OfertaFirestore {
  tipo: TipoOferta;
  usuario_uid: string;
  startup_id: string;
  quantidade_original: number;
  quantidade_restante: number;
  valor_unitario_centavos: number;
  status: StatusOferta;
  criado_em: CampoTimestamp;
  atualizado_em: CampoTimestamp;
}

export interface TransacaoBalcaoFirestore {
  mercado: typeof MERCADOS_TRANSACAO.secundario;
  comprador_uid: string;
  vendedor_uid: string;
  startup_id: string;
  oferta_compra_id: string;
  oferta_venda_id: string;
  quantidade: number;
  valor_unitario_centavos: number;
  valor_total_centavos: number;
  criado_em: CampoTimestamp;
}
