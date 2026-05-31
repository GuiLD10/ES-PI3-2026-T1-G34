// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: interface para cadastrar, logar e recuperar senha de usuário

export interface RegisterBody {
  nome: string;
  email: string;
  cpf: string;
  telefone: string;
  senha: string;
  confirmarSenha: string;
}

export interface LoginBody {
  email: string;
  senha: string;
}

export interface ForgotPasswordBody {
  email: string;
}

export interface RefreshSessionBody {
  refreshToken: string;
}

export interface ToggleMfaBody {
  ativar: boolean;
}
