// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import * as http from "http";
import {auth} from "../../shared/firebase";
import {AuthenticatedExchangeUser} from "../types/exchangeTypes";
import {ExchangeError} from "./exchangeErrors";

export function extractBearerToken(
  authorizationHeader: string | string[] | undefined,
): string {
  const header = Array.isArray(authorizationHeader) ?
    authorizationHeader[0] :
    authorizationHeader;

  if (!header) {
    throw new ExchangeError(401, "Token de autenticacao nao informado.");
  }

  const [type, token] = header.trim().split(/\s+/);

  if (type !== "Bearer" || !token) {
    throw new ExchangeError(401, "Token de autenticacao invalido.");
  }

  return token;
}

export async function authenticateExchangeUser(
  req: http.IncomingMessage,
): Promise<AuthenticatedExchangeUser> {
  const token = extractBearerToken(req.headers.authorization);

  try {
    const decodedToken = await auth.verifyIdToken(token);
    return {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };
  } catch {
    throw new ExchangeError(401, "Token de autenticacao expirado ou invalido.");
  }
}
