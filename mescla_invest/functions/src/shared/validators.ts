// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: metodos das validações

export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function validateCpf(cpf: string): boolean {
  const digits = cpf.replace(/\D/g, "");

  if (digits.length !== 11 || /^(\d)\1{10}$/.test(digits)) return false;

  let sum = 0;
  for (let i = 0; i < 9; i++) sum += parseInt(digits[i]) * (10 - i);
  let rest = (sum * 10) % 11;
  if (rest === 10 || rest === 11) rest = 0;
  if (rest !== parseInt(digits[9])) return false;

  sum = 0;
  for (let i = 0; i < 10; i++) sum += parseInt(digits[i]) * (11 - i);
  rest = (sum * 10) % 11;
  if (rest === 10 || rest === 11) rest = 0;
  if (rest !== parseInt(digits[10])) return false;

  return true;
}

export function validatePhone(telefone: string): boolean {
  const digits = telefone.replace(/\D/g, "");
  return digits.length === 10 || digits.length === 11;
}
