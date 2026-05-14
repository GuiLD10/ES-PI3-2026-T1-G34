// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: conecta com o banco de dados para recuperar senha

import {auth} from "../../shared/firebase";

export async function getUserByEmail(email: string) {
  return await auth.getUserByEmail(email.trim());
}
