// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Servidor Node.js — MesclaInvest (sem frameworks)

require('dotenv').config();
const http = require('http');
const admin = require('firebase-admin');
const fetch = require('node-fetch');
const path = require('path');

// Inicialização do Firebase Admin SDK
const serviceAccount = require(path.resolve(__dirname, '../serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

const PORT = process.env.PORT || 3000;
const FIREBASE_WEB_API_KEY = process.env.FIREBASE_WEB_API_KEY;

// Helpers de Validação
function validarEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Validação de CPF com algoritmo dos dígitos verificadores
function validarCpf(cpf) {
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

function validarTelefone(telefone) {
  const digits = telefone.replace(/\D/g, '');
  return digits.length === 10 || digits.length === 11;
}

// Lê o body da requisição e retorna uma Promise com o JSON parseado
function lerBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => { body += chunk.toString(); });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch {
        reject(new Error('JSON inválido'));
      }
    });
    req.on('error', reject);
  });
}

// Envia uma resposta JSON
function enviarJSON(res, statusCode, data) {
  const json = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  });
  res.end(json);
}

// Rota: Cadastro
async function handleRegister(req, res) {
  let body;
  try {
    body = await lerBody(req);
  } catch {
    return enviarJSON(res, 400, { success: false, message: 'Requisição inválida.' });
  }

  const { nome, email, cpf, telefone, senha, confirmarSenha } = body;

  if (!nome || nome.trim().length < 2) {
    return enviarJSON(res, 400, { success: false, field: 'Nome', message: 'Nome está incorreto' });
  }
  if (!email || !validarEmail(email)) {
    return enviarJSON(res, 400, { success: false, field: 'E-mail', message: 'E-mail está incorreto' });
  }
  if (!cpf || !validarCpf(cpf)) {
    return enviarJSON(res, 400, { success: false, field: 'CPF', message: 'CPF está incorreto' });
  }
  if (!telefone || !validarTelefone(telefone)) {
    return enviarJSON(res, 400, { success: false, field: 'Telefone', message: 'Telefone está incorreto' });
  }
  if (!senha || senha.length < 6) {
    return enviarJSON(res, 400, { success: false, field: 'Senha', message: 'Senha está incorreta' });
  }
  if (!confirmarSenha || confirmarSenha !== senha) {
    return enviarJSON(res, 400, { success: false, field: 'Confirmar Senha', message: 'Confirmar Senha está incorreto' });
  }

  try {
    const userRecord = await auth.createUser({
      email: email.trim(),
      password: senha,
      displayName: nome.trim(),
    });

    await db.collection('usuarios').doc(userRecord.uid).set({
      uid: userRecord.uid,
      nome: nome.trim(),
      email: email.trim(),
      cpf: cpf.replace(/\D/g, ''),
      telefone: telefone.replace(/\D/g, ''),
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    return enviarJSON(res, 201, {
      success: true,
      message: 'Cadastro realizado com sucesso!',
      uid: userRecord.uid,
    });
  } catch (error) {
    console.error('Erro no cadastro:', error);
    if (error.code === 'auth/email-already-exists') {
      return enviarJSON(res, 409, { success: false, field: 'E-mail', message: 'E-mail já está cadastrado' });
    }
    return enviarJSON(res, 500, { success: false, message: 'Erro interno ao realizar o cadastro. Tente novamente.' });
  }
}

// Rota: Login
async function handleLogin(req, res) {
  let body;
  try {
    body = await lerBody(req);
  } catch {
    return enviarJSON(res, 400, { success: false, message: 'Requisição inválida.' });
  }

  const { email, senha } = body;

  if (!email || !senha) {
    return enviarJSON(res, 400, { success: false, message: 'E-mail ou senha incorretos' });
  }

  try {
    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_WEB_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim(), password: senha, returnSecureToken: true }),
      }
    );

    const data = await response.json();

    if (!response.ok || data.error) {
      return enviarJSON(res, 401, { success: false, message: 'E-mail ou senha incorretos' });
    }

    return enviarJSON(res, 200, {
      success: true,
      message: 'Login realizado com sucesso!',
      uid: data.localId,
      token: data.idToken,
    });
  } catch (error) {
    console.error('Erro no login:', error);
    return enviarJSON(res, 500, { success: false, message: 'Erro interno ao realizar o login. Tente novamente.' });
  }
}

// Rota: Recuperação de Senha
async function handleForgotPassword(req, res) {
  let body;
  try {
    body = await lerBody(req);
  } catch {
    return enviarJSON(res, 400, { success: false, message: 'Requisição inválida.' });
  }

  const { email } = body;

  if (!email || !validarEmail(email)) {
    return enviarJSON(res, 400, { success: false, message: 'E-mail inválido.' });
  }

  // Verifica se o e-mail existe no Firebase Authentication
  try {
    await auth.getUserByEmail(email.trim());
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return enviarJSON(res, 404, { success: false, message: 'E-mail não encontrado no sistema.' });
    }
    console.error('Erro ao buscar usuário:', error);
    return enviarJSON(res, 500, { success: false, message: 'Erro interno. Tente novamente.' });
  }

  // Envia o e-mail de recuperação via Firebase Auth REST API
  try {
    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${FIREBASE_WEB_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ requestType: 'PASSWORD_RESET', email: email.trim() }),
      }
    );

    const data = await response.json();

    if (!response.ok || data.error) {
      console.error('Erro ao enviar e-mail de recuperação:', data.error);
      return enviarJSON(res, 500, { success: false, message: 'Erro ao enviar e-mail. Tente novamente.' });
    }

    return enviarJSON(res, 200, {
      success: true,
      message: 'Instruções enviadas para o e-mail cadastrado.',
    });
  } catch (error) {
    console.error('Erro ao enviar e-mail de recuperação:', error);
    return enviarJSON(res, 500, { success: false, message: 'Erro interno. Tente novamente.' });
  }
}

// Servidor HTTP
const server = http.createServer(async (req, res) => {
  // Suporte a CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
    });
    return res.end();
  }

  const url = req.url;
  const method = req.method;

  if (method === 'POST' && url === '/auth/register') {
    return handleRegister(req, res);
  }

  if (method === 'POST' && url === '/auth/login') {
    return handleLogin(req, res);
  }

  if (method === 'POST' && url === '/auth/forgot-password') {
    return handleForgotPassword(req, res);
  }

  // Rota não encontrada
  enviarJSON(res, 404, { success: false, message: 'Rota não encontrada.' });
});

// Iniciar servidor
server.listen(PORT, () => {
  console.log(`Servidor MesclaInvest rodando em http://localhost:${PORT}`);
});
