// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição:  metodos para ler e responder requisições
import * as http from 'http';
import { ApiResponse } from "../shared/ResponsesInterfaces";
import * as admin from "firebase-admin"
import { StartupData } from '../types/StartupInterfaces';

//lé o conteudo do body
export function lerBody<T = Record<string, unknown>>(req: http.IncomingMessage): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    let body = '';
    req.on('data', (chunk: Buffer) => { body += chunk.toString(); });
    req.on('end', () => {
      try {
        resolve(body ? (JSON.parse(body) as T) : ({} as T));
      } catch {
        reject(new Error('JSON inválido'));
      }
    });
    req.on('error', reject);
  });
}

// Envia uma resposta JSON
export function enviarJSON(res: http.ServerResponse, statusCode: number, data: ApiResponse): void {
  const json = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  });
  res.end(json);
}

export function converterFirestoreValor(valor: unknown): unknown {
  if (valor === null || valor === undefined) return valor;
  if (typeof (valor as admin.firestore.Timestamp).toDate === 'function') {
    return (valor as admin.firestore.Timestamp).toDate().toISOString();
  }
  if (Array.isArray(valor)) return valor.map(converterFirestoreValor);

  if (typeof valor === 'object') {
    const objeto: Record<string, unknown> = {};
    Object.entries(valor as Record<string, unknown>).forEach(([chave, item]) => {
      objeto[chave] = converterFirestoreValor(item);
    });
    return objeto;
  }

  return valor;
}

export function montarStartup(doc: admin.firestore.DocumentSnapshot): StartupData {
  const dados = converterFirestoreValor(doc.data()) as Record<string, unknown>;
  console.log("entrei no montar startup");

  return {
    id: doc.id,
    nome: (dados.nome as string) || '',
    descricao: (dados.descricao as string) || '',
    setor: (dados.setor as string) || '',
    estagio: (dados.estagio as string) || '',
    status: (dados.status as string) || '',
    capital_aportado: Number(dados.capital_aportado) || 0,
    tokens_emitidos: Number(dados.tokens_emitidos) || 0,
    video_demo: (dados.video_demo as string) || '',
    socios: Array.isArray(dados.socios) ? dados.socios : [],
    mentores_conselho: Array.isArray(dados.mentores_conselho) ? dados.mentores_conselho : [],
    perguntas_respostas: Array.isArray(dados.perguntas_respostas) ? dados.perguntas_respostas : [],
    criado_em: (dados.criado_em as string) || null,
    atualizado_em: (dados.atualizado_em as string) || null,
  };
}