// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: metodos para ler e responder requisições

import * as http from "http";
import {ApiResponse} from "./types";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

export function readJsonBody<T = Record<string, unknown>>(
  req: http.IncomingMessage,
): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    let body = "";
    req.on("data", (chunk: Buffer) => {
      body += chunk.toString();
    });
    req.on("end", () => {
      try {
        resolve(body ? (JSON.parse(body) as T) : ({} as T));
      } catch {
        reject(new Error("JSON inválido"));
      }
    });
    req.on("error", reject);
  });
}

export function sendJson(
  res: http.ServerResponse,
  statusCode: number,
  data: ApiResponse,
): void {
  const json = JSON.stringify(data);
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    ...corsHeaders,
  });
  res.end(json);
}

export function handleCorsPreflight(
  req: http.IncomingMessage,
  res: http.ServerResponse,
): boolean {
  if (req.method !== "OPTIONS") {
    return false;
  }

  res.writeHead(204, corsHeaders);
  res.end();
  return true;
}
