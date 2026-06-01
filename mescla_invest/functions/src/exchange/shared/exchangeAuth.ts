// Autor: Rafael Lanza de Queiroz
// RA: 22010825

import * as http from "http";
import {
  authenticateRequest,
  AuthRequestError,
  extractBearerToken as extractSharedBearerToken,
} from "../../shared/auth";
import {AuthenticatedExchangeUser} from "../types/exchangeTypes";
import {ExchangeError} from "./exchangeErrors";

export function extractBearerToken(
  authorizationHeader: string | string[] | undefined,
): string {
  try {
    return extractSharedBearerToken(authorizationHeader);
  } catch (error) {
    if (error instanceof AuthRequestError) {
      throw new ExchangeError(error.statusCode, error.message);
    }

    throw error;
  }
}

export async function authenticateExchangeUser(
  req: http.IncomingMessage,
): Promise<AuthenticatedExchangeUser> {
  try {
    const user = await authenticateRequest(req);
    return {
      uid: user.uid,
      email: user.email,
    };
  } catch (error) {
    if (error instanceof AuthRequestError) {
      throw new ExchangeError(error.statusCode, error.message);
    }

    throw error;
  }
}
