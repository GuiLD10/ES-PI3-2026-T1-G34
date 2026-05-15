# MesclaInvest

Aplicativo Flutter com backend em Firebase Functions.

## Requisitos

- Flutter SDK configurado
- Node.js 20
- Firebase CLI atualizada com suporte a `nodejs20`
- Acesso ao projeto Firebase `mesclainvest-d3745`

## Preparacao inicial

Todos os comandos abaixo devem ser executados a partir da pasta `mescla_invest`.

Instale as dependencias do Flutter:

```powershell
flutter pub get
```

Confira a versao da Firebase CLI:

```powershell
firebase --version
```

Se o emulador mostrar `Cannot deploy function with runtime nodejs20`, atualize a Firebase CLI:

```powershell
npm install -g firebase-tools@latest
```

Instale as dependencias das Functions:

```powershell
cd functions
npm install
cd ..
```

Crie o arquivo local de variaveis das Functions:

```powershell
Copy-Item functions\.env.example functions\.env
```

Preencha `functions/.env` com a Web API Key do Firebase:

```env
WEB_API_KEY=sua_chave_web_do_firebase
```

Use `WEB_API_KEY`, nao `FIREBASE_WEB_API_KEY`, porque o prefixo `FIREBASE_` e reservado pela Firebase CLI.

O arquivo `functions/.env` nao deve ser commitado. Se existir um `.env` na raiz do projeto, ele nao e usado neste fluxo.

## Rodando para teste manual

Entre no Firebase com uma conta que tenha acesso ao projeto:

```powershell
firebase login --reauth
```

Compile as Functions:

```powershell
cd functions
npm run build
cd ..
```

No primeiro terminal, suba o emulador das Functions:

```powershell
firebase emulators:start --only functions --project mesclainvest-d3745
```

A mensagem dizendo que a Emulator UI nao sera iniciada e esperada, porque somente o emulador de Functions esta rodando. A mensagem dizendo que Auth e Firestore afetarao producao tambem e esperada neste fluxo de teste com dados reais.

No segundo terminal, rode o app Flutter no Chrome:

```powershell
flutter run -d chrome
```

Por padrao, o app chama as Functions locais nesta URL:

```text
http://localhost:5001/mesclainvest-d3745/us-central1
```

Para usar outra URL de Functions:

```powershell
flutter run -d chrome --dart-define=FUNCTIONS_BASE_URL=http://localhost:5001/mesclainvest-d3745/us-central1
```

Neste fluxo, apenas as Functions rodam localmente. As chamadas de Auth e Firestore feitas pelo backend usam o projeto Firebase configurado em `.firebaserc`.

## Checklist de teste manual

- Criar uma conta nova pelo app.
- Tentar criar a mesma conta novamente e confirmar o erro de e-mail em uso.
- Fazer login com a conta criada.
- Tentar login com senha incorreta e confirmar erro de credenciais.
- Solicitar recuperacao de senha.
- Abrir a listagem de startups.
- Abrir os detalhes de uma startup.

## Validacoes

Functions:

```powershell
cd functions
npm run lint
npm run build
npm run typecheck
cd ..
```

Flutter no escopo de integracao com as Functions:

```powershell
dart analyze lib\core\services\auth_service.dart lib\core\services\startup_service.dart lib\models\startup_model.dart
```

Validacoes completas do Flutter:

```powershell
flutter analyze
flutter test
```
