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

Instruções para execução do sistema (Ambiente de testes)

### Requisitos

- Flutter SDK configurado
- Node.js 24
- Firebase CLI atualizada com suporte a `nodejs24`
- Acesso ao projeto Firebase `mesclainvest-d3745`

### 1. Clonar o repositório

```powershell
git clone https://github.com/GuiLD10/ES-PI3-2026-T1-G34.git
cd ES-PI3-2026-T1-G34/mescla_invest
```

### 2. Instalar dependências do Flutter

```powershell
flutter pub get
```

### 3. Instalar dependências das Functions

```powershell
cd functions
npm install
cd ..
```

### 4. Configurar variáveis locais

```powershell
Copy-Item functions\.env.example functions\.env
```

Preencha `functions/.env` com a Web API Key do Firebase:

```env
WEB_API_KEY=sua_chave_web_do_firebase
```

### 5. Entrar no Firebase

```powershell
firebase login --reauth
```

### 6. Compilar as Functions

```powershell
cd functions
npm run build
cd ..
```

### 7. Subir o emulador das Functions

```powershell
firebase emulators:start --only functions --project mesclainvest-d3745
```

### 8. Rodar o aplicativo Flutter

Em outro terminal, dentro de `mescla_invest`:

```powershell
flutter run -d chrome
```

Por padrão, o app chama as Functions locais em:

```text
http://localhost:5001/mesclainvest-d3745/us-central1
```

Para usar outra URL de Functions:

```powershell
flutter run -d chrome --dart-define=FUNCTIONS_BASE_URL=http://localhost:5001/mesclainvest-d3745/us-central1
```

## Validações

Functions:

```powershell
cd mescla_invest/functions
npm run lint
npm run build
npm run typecheck
```

Flutter:

```powershell
cd mescla_invest
flutter analyze
flutter test
```

## Links úteis

- 🔗 [Wireframe (Whimsical)](https://whimsical.com/bruna-s8/wireframe-mesclainvest-D9Wwwm8dKGrSkBwpFQ9yGN)
- 🔗 [Documentação Flutter](https://docs.flutter.dev/)
- 🔗 [Console Firebase](https://console.firebase.google.com/)
