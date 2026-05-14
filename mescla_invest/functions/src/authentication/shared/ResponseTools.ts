// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: metodos para ler e responder requisições
import * as http from 'http';
import { ApiResponse } from './ResponsesInterfaces';

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