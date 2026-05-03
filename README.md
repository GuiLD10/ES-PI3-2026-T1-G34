# Time 34

# Membros
ARTUR HENRIQUE PAGNO, 
BRUNA RODRIGUES CARDOSO, 
GUILHERME LANGE DALLORA, 
HENRIQUE SOARES CUNHA, 
RAFAEL LANZA DE QUEIROZ

MesclaInvest 
Descrição do Projeto 
É um aplicativo mobile desenvolvido como parte do Projeto Integrador III do curso de Engenharia de Software da Puc-Campinas.
O projeto tem como objetivo simular um ambiente de investimento em startups. Para isso será utilizado tokenização de ativos baseados em blockchain. 
Cada startup possui tokens que representam participações simuladas, o que permite os usuários realizarem operações de compra e venda dentro de um ambiente educacional. 

O projeto explora conceitos de:
- Blockchain
- Tokenização de ativos
- Mercados digitais de investimento
- Aplicações mobile para sistemas financeiros
OBS.: A aplicação possui caráter educacional, ou seja, não envolve dinheiro real e integração com redes blockchain reais.

Tecnologias Utilizadas
- Flutter - Desenvolvimento da aplicação mobile
- Dart - Linguagem de programação do Flutter
- Firebase Firestore - Banco de dados NoSQL
- Firebase Authentication - Autenticação de usuários
- Node.js + TypeScript - Servidor backend
- GitHub - Versionamento do código
- Git - Controle de versão

Instruções para execuçção do sistema (Ambiente de testes)
- Passos para executar o sistema em ambiente de testes:
### 1. Clonar o repositório
git clone https://github.com/GuiLD10/ES-PI3-2026-T1-G34.git
cd ES-PI3-2026-T1-G34

### 2. Configure os arquivos sensíveis

O projeto precisa de dois arquivos que **não estão no repositório** por segurança. Você deve criá-los manualmente.

#### `mescla_invest/serviceAccountKey.json`
Salve o arquivo 'serviceAccountKey.json' na pasta 'mescla_invest'.

#### `mescla_invest/server/.env`
Crie o arquivo `mescla_invest/server/.env` com o conteúdo do .env.

### 3. Instale as dependências do servidor Node.js

O servidor utiliza **TypeScript**. As dependências de desenvolvimento (compilador e tipos) já estão listadas no `package.json` e serão instaladas automaticamente:

```bash
cd mescla_invest/server
npm install
```

---

### 4. Instale as dependências do Flutter

```bash
cd mescla_invest
flutter pub get
```

---

### 5. Configure a URL base do servidor no Flutter

Abra o arquivo `mescla_invest/lib/core/services/auth_service.dart` e ajuste a constante `_baseUrl` conforme o ambiente:

```dart
// Para rodar no emulador Android (aponta para o localhost da máquina host)
static const String _baseUrl = 'http://10.0.2.2:3000';

// Para rodar no Windows (app desktop) ou Chrome (web)
static const String _baseUrl = 'http://localhost:3000';

// Para rodar em dispositivo físico (use o IP da sua máquina na rede local)
static const String _baseUrl = 'http://192.168.X.X:3000';
```

---

### 6. Inicie o servidor Node.js (TypeScript)

Abra um terminal e execute:

```bash
cd mescla_invest/server
npm run dev
```

Este comando utiliza `ts-node` para executar o `index.ts` diretamente, sem necessidade de compilação prévia.

Você verá a mensagem:
```
Servidor MesclaInvest rodando em http://localhost:3000
```

> **Mantenha este terminal aberto** enquanto usa o app. Sempre que editar o `index.ts`, pare o servidor com `Ctrl+C` e reinicie com `npm run dev`.

#### Alternativa: build de produção

Se preferir compilar o TypeScript antes de executar:

```bash
npm run build   # Compila index.ts → dist/index.js
npm start       # Executa a versão compilada
```

---

### 7. Rode o aplicativo Flutter

Abra **outro terminal** e execute:

```bash
cd mescla_invest
flutter run
```

Se houver mais de um dispositivo disponível, o Flutter listará as opções. Escolha o desejado.

Para forçar um dispositivo específico:
```bash
flutter run -d chrome        # Navegador Chrome (web)
flutter run -d windows       # App desktop Windows
flutter run -d <device-id>   # Emulador ou dispositivo Android/iOS
```

## Links úteis

- 🔗 [Wireframe (Whimsical)](https://whimsical.com/bruna-s8/wireframe-mesclainvest-D9Wwwm8dKGrSkBwpFQ9yGN)
- 🔗 [Documentação Flutter](https://docs.flutter.dev/)
- 🔗 [Console Firebase](https://console.firebase.google.com/)
