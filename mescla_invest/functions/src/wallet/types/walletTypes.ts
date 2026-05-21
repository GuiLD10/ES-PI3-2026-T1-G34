// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Tipos da carteira do investidor
 
export interface WalletData {
  uid: string;
  nome: string;
  email: string;
  saldo_disponivel: number;
  saldo_bloqueado: number;
}
 
export interface TransacaoData {
  id: string;
  startup_id: string;
  comprador_uid: string;
  vendedor_uid: string;
  oferta_compra_id: string;
  oferta_venda_id: string;
  mercado: string;
  quantidade: number;
  valor_unitario: number;
  valor_total: number;
  criado_em: FirebaseFirestore.Timestamp;
}