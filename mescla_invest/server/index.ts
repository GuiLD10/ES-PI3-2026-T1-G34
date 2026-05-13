// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: Servidor Node.js

import 'dotenv/config';
import * as http from 'http';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch';
import * as path from 'path';
import { criarOfertaBalcao } from './balcao_ordens';
import { ErroBalcao } from './balcao_validacoes';

//  Interfaces 

interface RegisterBody {
  nome: string;
  email: string;
  cpf: string;
  telefone: string;
  senha: string;
  confirmarSenha: string;
}

interface LoginBody {
  email: string;
  senha: string;
}

interface ForgotPasswordBody {
  email: string;
}

interface StartupData {
  id: string;
  nome: string;
  descricao: string;
  setor: string;
  estagio: string;
  status: string;
  capital_aportado: number;
  tokens_emitidos: number;
  preco_atual_centavos: number;
  preco_primario_centavos: number;
  video_demo: string;
  socios: unknown[];
  mentores_conselho: unknown[];
  perguntas_respostas: unknown[];
  criado_em: string | null;
  atualizado_em: string | null;
}

interface FirebaseLoginResponse {
  localId?: string;
  idToken?: string;
  error?: { message: string };
}

interface ApiResponse {
  success: boolean;
  message?: string;
  uid?: string;
  token?: string;
  field?: string;
  data?: unknown;
}

//  Inicialização do Firebase Admin SDK 

const serviceAccount = require(path.resolve(__dirname, '../serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

const PORT: number = Number(process.env.PORT) || 3000;
const FIREBASE_WEB_API_KEY: string = process.env.FIREBASE_WEB_API_KEY ?? '';

//  Helpers de Validação 

function validarEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Validação de CPF com algoritmo dos dígitos verificadores
function validarCpf(cpf: string): boolean {
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

function validarTelefone(telefone: string): boolean {
  const digits = telefone.replace(/\D/g, '');
  return digits.length === 10 || digits.length === 11;
}

// Lê o body da requisição e retorna uma Promise com o JSON parseado
function lerBody<T = Record<string, unknown>>(req: http.IncomingMessage): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    let body = '';
    req.on('data', (chunk: Buffer) => { body += chunk.toString(); });
    req.on('end', () => {
      try {
        resolve(body ? (JSON.parse(body) as T) : ({} as T));
      } catch {
        reject(new Error('JSON inválido'));
      }
    });
    req.on('error', reject);
  });
}

// Envia uma resposta JSON
function enviarJSON(res: http.ServerResponse, statusCode: number, data: ApiResponse): void {
  const json = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  });
  res.end(json);
}

function converterFirestoreValor(valor: unknown): unknown {
  if (valor === null || valor === undefined) return valor;
  if (typeof (valor as admin.firestore.Timestamp).toDate === 'function') {
    return (valor as admin.firestore.Timestamp).toDate().toISOString();
  }
  if (Array.isArray(valor)) return valor.map(converterFirestoreValor);

  if (typeof valor === 'object') {
    const objeto: Record<string, unknown> = {};
    Object.entries(valor as Record<string, unknown>).forEach(([chave, item]) => {
      objeto[chave] = converterFirestoreValor(item);
    });
    return objeto;
  }

  return valor;
}

function montarStartup(doc: admin.firestore.DocumentSnapshot): StartupData {
  const dados = converterFirestoreValor(doc.data()) as Record<string, unknown>;

  return {
    id: doc.id,
    nome: (dados.nome as string) || '',
    descricao: (dados.descricao as string) || '',
    setor: (dados.setor as string) || '',
    estagio: (dados.estagio as string) || '',
    status: (dados.status as string) || '',
    capital_aportado: Number(dados.capital_aportado) || 0,
    tokens_emitidos: Number(dados.tokens_emitidos) || 0,
    preco_atual_centavos: Number(dados.preco_atual_centavos) || 0,
    preco_primario_centavos: Number(dados.preco_primario_centavos) || 0,
    video_demo: (dados.video_demo as string) || '',
    socios: Array.isArray(dados.socios) ? dados.socios : [],
    mentores_conselho: Array.isArray(dados.mentores_conselho) ? dados.mentores_conselho : [],
    perguntas_respostas: Array.isArray(dados.perguntas_respostas) ? dados.perguntas_respostas : [],
    criado_em: (dados.criado_em as string) || null,
    atualizado_em: (dados.atualizado_em as string) || null,
  };
}

//  Rota: Cadastro 

async function handleRegister(req: http.IncomingMessage, res: http.ServerResponse): Promise<void> {
  let body: RegisterBody;
  try {
    body = await lerBody<RegisterBody>(req);
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
      saldo_disponivel_centavos: 0,
      saldo_bloqueado_centavos: 0,
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    return enviarJSON(res, 201, {
      success: true,
      message: 'Cadastro realizado com sucesso!',
      uid: userRecord.uid,
    });
  } catch (error: unknown) {
    console.error('Erro no cadastro:', error);
    const firebaseError = error as { code?: string };
    if (firebaseError.code === 'auth/email-already-exists') {
      return enviarJSON(res, 409, { success: false, field: 'E-mail', message: 'E-mail já está cadastrado' });
    }
    return enviarJSON(res, 500, { success: false, message: 'Erro interno ao realizar o cadastro. Tente novamente.' });
  }
}

//  Rota: Login 

async function handleLogin(req: http.IncomingMessage, res: http.ServerResponse): Promise<void> {
  let body: LoginBody;
  try {
    body = await lerBody<LoginBody>(req);
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

    const data = (await response.json()) as FirebaseLoginResponse;

    if (!response.ok || data.error) {
      return enviarJSON(res, 401, { success: false, message: 'E-mail ou senha incorretos' });
    }

    return enviarJSON(res, 200, {
      success: true,
      message: 'Login realizado com sucesso!',
      uid: data.localId,
      token: data.idToken,
    });
  } catch (error: unknown) {
    console.error('Erro no login:', error);
    return enviarJSON(res, 500, { success: false, message: 'Erro interno ao realizar o login. Tente novamente.' });
  }
}

//  Rota: Recuperação de Senha 

async function handleForgotPassword(req: http.IncomingMessage, res: http.ServerResponse): Promise<void> {
  let body: ForgotPasswordBody;
  try {
    body = await lerBody<ForgotPasswordBody>(req);
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
  } catch (error: unknown) {
    const firebaseError = error as { code?: string };
    if (firebaseError.code === 'auth/user-not-found') {
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

    const data = (await response.json()) as FirebaseLoginResponse;

    if (!response.ok || data.error) {
      console.error('Erro ao enviar e-mail de recuperação:', data.error);
      return enviarJSON(res, 500, { success: false, message: 'Erro ao enviar e-mail. Tente novamente.' });
    }

    return enviarJSON(res, 200, {
      success: true,
      message: 'Instruções enviadas para o e-mail cadastrado.',
    });
  } catch (error: unknown) {
    console.error('Erro ao enviar e-mail de recuperação:', error);
    return enviarJSON(res, 500, { success: false, message: 'Erro interno. Tente novamente.' });
  }
}

//  Rota: Listar Startups 

async function handleListStartups(_req: http.IncomingMessage, res: http.ServerResponse): Promise<void> {
  try {
    const snapshot = await db
      .collection('startups')
      .where('status', '==', 'ativa')
      .get();

    const startups: StartupData[] = snapshot.docs
      .map(montarStartup)
      .sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));

    return enviarJSON(res, 200, {
      success: true,
      data: startups,
    });
  } catch (error: unknown) {
    console.error('Erro ao listar startups:', error);
    return enviarJSON(res, 500, {
      success: false,
      message: 'Erro interno ao buscar startups. Tente novamente.',
    });
  }
}

//  Rota: Buscar Startup por ID 

async function handleGetStartupById(
  _req: http.IncomingMessage,
  res: http.ServerResponse,
  startupId: string
): Promise<void> {
  if (!startupId) {
    return enviarJSON(res, 400, {
      success: false,
      message: 'ID da startup é obrigatório.',
    });
  }

  try {
    const doc = await db.collection('startups').doc(startupId).get();

    if (!doc.exists) {
      return enviarJSON(res, 404, {
        success: false,
        message: 'Startup não encontrada.',
      });
    }

    const startup = montarStartup(doc);

    if (startup.status !== 'ativa') {
      return enviarJSON(res, 404, {
        success: false,
        message: 'Startup não encontrada.',
      });
    }

    return enviarJSON(res, 200, {
      success: true,
      data: startup,
    });
  } catch (error: unknown) {
    console.error('Erro ao buscar startup:', error);
    return enviarJSON(res, 500, {
      success: false,
      message: 'Erro interno ao buscar startup. Tente novamente.',
    });
  }
}

//  Rota: Criar Oferta no Balcao

async function handleCreateOrder(req: http.IncomingMessage, res: http.ServerResponse): Promise<void> {
  let body: Record<string, unknown>;
  try {
    body = await lerBody<Record<string, unknown>>(req);
  } catch {
    return enviarJSON(res, 400, { success: false, message: 'RequisiÃ§Ã£o invÃ¡lida.' });
  }

  try {
    const oferta = await criarOfertaBalcao(req, db, auth, body);

    return enviarJSON(res, 201, {
      success: true,
      message: 'Oferta criada com sucesso.',
      data: oferta,
    });
  } catch (error: unknown) {
    if (error instanceof ErroBalcao) {
      return enviarJSON(res, error.statusCode, {
        success: false,
        field: error.field,
        message: error.message,
      });
    }

    console.error('Erro ao criar oferta no balcao:', error);
    return enviarJSON(res, 500, {
      success: false,
      message: 'Erro interno ao criar oferta no balcao. Tente novamente.',
    });
  }
}

//  Servidor HTTP 

const server = http.createServer(async (req: http.IncomingMessage, res: http.ServerResponse) => {
  // Suporte a CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    });
    return res.end();
  }

  const parsedUrl = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);
  const url = parsedUrl.pathname;
  const method = req.method;

  if (method === 'GET' && url === '/startups') {
    return handleListStartups(req, res);
  }

  if (method === 'GET' && url.startsWith('/startups/')) {
    const startupId = decodeURIComponent(url.replace('/startups/', '').trim());
    return handleGetStartupById(req, res, startupId);
  }

  if (method === 'POST' && url === '/orders') {
    return handleCreateOrder(req, res);
  }

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

//  Iniciar servidor 

server.listen(PORT, () => {
  console.log(`Servidor MesclaInvest rodando em http://localhost:${PORT}`);
});
