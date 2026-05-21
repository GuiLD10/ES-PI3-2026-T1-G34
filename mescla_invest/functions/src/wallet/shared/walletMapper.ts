// Autor: Artur Henrique Pagno
// RA: 21013037
// Descrição: Mapper dos documentos da carteira do Firestore

import { WalletData, TransacaoData } from "../types/walletTypes";

export function mapWalletDocument(
  doc: FirebaseFirestore.DocumentSnapshot
): WalletData {
  const data = doc.data() as Record<string, any>;

  return {
    uid: doc.id,
    nome: data.nome ?? "",
    email: data.email ?? "",
    saldo_disponivel: data.saldo_disponivel ?? 0,
    saldo_bloqueado: data.saldo_bloqueado ?? 0,
  };
}

export function mapTransacaoDocument(
  doc: FirebaseFirestore.DocumentSnapshot
): TransacaoData {
  const data = doc.data() as Record<string, any>;

  return {
    id: doc.id,
    startup_id: data.startup_id ?? "",
    comprador_uid: data.comprador_uid ?? "",
    vendedor_uid: data.vendedor_uid ?? "",
    oferta_compra_id: data.oferta_compra_id ?? "",
    oferta_venda_id: data.oferta_venda_id ?? "",
    mercado: data.mercado ?? "",
    quantidade: data.quantidade ?? 0,
    valor_unitario: data.valor_unitario ?? 0,
    valor_total: data.valor_total ?? 0,
    criado_em: data.criado_em,
  };
}