// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: metodos das validações

//valida email
export function validarEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Validação de CPF com algoritmo dos dígitos verificadores
export function validarCpf(cpf: string): boolean {
  const digits = cpf.replace(/\D/g, '');

  // Deve ter exatamente 11 dígitos e não pode ser uma sequência repetida (ex: 111.111.111-11)
  if (digits.length !== 11 || /^(\d)\1{10}$/.test(digits)) return false;

  // Validação do primeiro dígito verificador
  let soma = 0;
  for (let i = 0; i < 9; i++) soma += parseInt(digits[i]) * (10 - i);
  let resto = (soma * 10) % 11;
  if (resto === 10 || resto === 11) resto = 0;
  if (resto !== parseInt(digits[9])) return false;

  // Validação do segundo dígito verificador
  soma = 0;
  for (let i = 0; i < 10; i++) soma += parseInt(digits[i]) * (11 - i);
  resto = (soma * 10) % 11;
  if (resto === 10 || resto === 11) resto = 0;
  if (resto !== parseInt(digits[10])) return false;

  return true;
}

//valida quantidade de digitos do telefone
export function validarTelefone(telefone: string): boolean {
  const digits = telefone.replace(/\D/g, '');
  return digits.length === 10 || digits.length === 11;
}