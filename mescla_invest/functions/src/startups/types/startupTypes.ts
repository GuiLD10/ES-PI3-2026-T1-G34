// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: interface das startups

export interface StartupData {
  id: string;
  nome: string;
  descricao: string;
  setor: string;
  estagio: string;
  status: string;
  capital_aportado: number;
  tokens_emitidos: number;
  preco_atual_centavos: number;
  preco_primario_centavos: number;
  preco_atual_preciso_centavos: number;
  preco_primario_preciso_centavos: number;
  video_demo: string;
  sumario_executivo: string;
  plano_de_negocios: string;
  socios: unknown[];
  mentores_conselho: unknown[];
  perguntas_respostas: unknown[];
  criado_em: string | null;
  atualizado_em: string | null;
}
