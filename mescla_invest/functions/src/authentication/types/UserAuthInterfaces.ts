
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
