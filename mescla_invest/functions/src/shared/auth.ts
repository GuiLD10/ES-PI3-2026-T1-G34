// Autor: Rafael Lanza de Queiroz
// RA: 22010825
// Descricao: Utilitarios compartilhados para autenticacao por Bearer token

import * as http from "http";
import {auth} from "./firebase";

export interface AuthenticatedRequestUser {
  uid: string;
  email?: string;
}

export class AuthRequestError extends Error {
  readonly statusCode: number;

  constructor(statusCode: number, message: string) {
    super(message);
    this.name = "AuthRequestError";
    this.statusCode = statusCode;
  }
}

export function extractBearerToken(
  authorizationHeader: string | string[] | undefined,
): string {
  const header = Array.isArray(authorizationHeader) ?
    authorizationHeader[0] :
    authorizationHeader;

  if (!header) {
    throw new AuthRequestError(401, "Token de autenticacao nao informado.");
  }

  const [type, token] = header.trim().split(/\s+/);

  if (type !== "Bearer" || !token) {
    throw new AuthRequestError(401, "Token de autenticacao invalido.");
  }

  return token;
}

export async function authenticateRequest(
  req: http.IncomingMessage,
): Promise<AuthenticatedRequestUser> {
  const token = extractBearerToken(req.headers.authorization);

  try {
    const decodedToken = await auth.verifyIdToken(token);
    return {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };
  } catch {
    throw new AuthRequestError(
      401,
      "Token de autenticacao expirado ou invalido.",
    );
  }
}
