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
  video_demo: string;
  socios: unknown[];
  mentores_conselho: unknown[];
  perguntas_respostas: unknown[];
  criado_em: string | null;
  atualizado_em: string | null;
}
