// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: interface para restornar e interpretar respostas

export interface FirebaseLoginResponse {
  localId?: string;
  idToken?: string;
  refreshToken?: string;
  error?: { message: string };
}

export interface FirebaseRefreshTokenResponse {
  user_id?: string;
  id_token?: string;
  refresh_token?: string;
  error?: { message: string };
}

export interface ApiResponse {
  success: boolean;
  message?: string;
  uid?: string;
  token?: string;
  refreshToken?: string;
  field?: string;
  data?: unknown;
  name?: string;
  email?: string;
  startup_id?: string;
  tendencia?: string;
  variacao_percentual?: number;
  preco_inicial_centavos?: number;
  preco_final_centavos?: number;
  volume_total_centavos?: number;
  quantidade_total_tokens?: number;
  total_transacoes?: number;
  periodo?: string;
  telefone?: string;
  requiresMfa?: boolean;
  mfaAtivo?: boolean;
}
