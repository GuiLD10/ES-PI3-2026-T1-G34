// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Tipos da carteira do investidor

import type {Timestamp} from "firebase-admin/firestore";

export interface WalletData {
  uid: string;
  nome: string;
  email: string;
  saldo_disponivel: number;
  saldo_bloqueado: number;
  saldo_disponivel_centavos: number;
  saldo_bloqueado_centavos: number;
}

export interface TransacaoData {
  id: string;
  startup_id: string;
  startup_nome: string;
  comprador_uid: string;
  vendedor_uid: string;
  oferta_compra_id: string;
  oferta_venda_id: string;
  mercado: string;
  quantidade: number;
  valor_unitario: number;
  valor_total: number;
  valor_unitario_centavos: number;
  valor_total_centavos: number;
  criado_em: Timestamp | string | null;
}

export interface AtivoData {
  startup_id: string;
  quantidade_disponivel: number;
  quantidade_bloqueada: number;
  valor_medio_centavos: number;
}

export interface PricePointData {
  preco_centavos: number;
  data: string;
}

export interface PortfolioAtivoResponse {
  startup_id: string;
  startup_nome: string;
  quantidade_disponivel: number;
  quantidade_bloqueada: number;
  valor_medio_centavos: number;
  preco_atual_centavos: number;
  preco_primario_centavos: number;
  historico_precos: PricePointData[];
}
