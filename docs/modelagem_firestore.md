# Modelagem Firestore - MesclaInvest

Autor principal: Rafael Lanza de Queiroz  
RA: 22010825

## Objetivo

Este documento consolida a modelagem inicial das colecoes do Firebase Firestore usadas pelo MesclaInvest, com foco na colecao `startups`.

A Fase 1 da implementacao do catalogo tem como objetivo definir quais campos existem no banco, como eles devem ser interpretados pelo backend e como serao usados pelo aplicativo Flutter.

## Colecoes Existentes

Atualmente o projeto utiliza pelo menos duas colecoes principais no Firestore:

- `usuarios`
- `startups`

A colecao `usuarios` ja e usada pelo backend na rota de cadastro. A colecao `startups` ja existe no Firestore, mas ainda nao e consumida pelo backend nem pelo aplicativo Flutter.

## Colecao `usuarios`

A colecao `usuarios` armazena os dados complementares do usuario criado no Firebase Authentication.

Estrutura atual:

```txt
usuarios/{uid}
  uid: string
  nome: string
  email: string
  cpf: string
  telefone: string
  saldo_disponivel_centavos: number
  saldo_bloqueado_centavos: number
  criadoEm: timestamp
  atualizado_em: timestamp
  ativos/{startupId}
    startup_id: string
    quantidade_disponivel: number
    quantidade_bloqueada: number
    valor_medio_centavos: number
    atualizado_em: timestamp
```

Observacoes:

- O `uid` e gerado pelo Firebase Authentication.
- A senha nao deve ser salva no Firestore.
- O CPF e o telefone sao salvos apenas com digitos.
- Esta colecao serve para dados de perfil e identificacao do usuario.
- Os saldos sao armazenados em centavos para evitar erros de ponto flutuante.
- `saldo_disponivel_centavos` representa saldo livre para negociacao.
- `saldo_bloqueado_centavos` representa saldo reservado em ofertas abertas ou parciais.
- A subcolecao `ativos` representa a custodia simulada de tokens por startup.
- `quantidade_disponivel` representa tokens livres para venda.
- `quantidade_bloqueada` representa tokens reservados em ofertas de venda abertas ou parciais.

## Colecao `startups`

A colecao `startups` armazena os projetos que serao exibidos no catalogo do aplicativo.

Estrutura definida:

```txt
startups/{startupId}
  nome: string
  descricao: string
  setor: string
  estagio: string
  status: string
  capital_aportado: number
  tokens_emitidos: number
  preco_atual_centavos: number
  preco_primario_centavos: number
  video_demo: string
  socios: array<map>
  mentores_conselho: array<map>
  perguntas_respostas: array<map>
  criado_em: timestamp
  atualizado_em: timestamp
```

Exemplo de documento:

```json
{
  "nome": "EcoTech",
  "descricao": "Plataforma que usa sensores IoT para monitoramento de consumo de agua e energia em empresas.",
  "setor": "Sustentabilidade / IoT",
  "estagio": "Em operacao",
  "status": "ativa",
  "capital_aportado": 350000,
  "tokens_emitidos": 1000000,
  "preco_atual_centavos": 150,
  "preco_primario_centavos": 100,
  "video_demo": "https://exemplo.com/demo",
  "socios": [
    {
      "nome": "Ana Souza",
      "participacao": 40
    },
    {
      "nome": "Carlos Lima",
      "participacao": 35
    },
    {
      "nome": "Pedro Duarte",
      "participacao": 25
    }
  ],
  "mentores_conselho": [
    {
      "nome": "Prof. Ricardo Martins",
      "papel": "Mentor"
    },
    {
      "nome": "Juliana Prado",
      "papel": "Investidora Anjo"
    }
  ],
  "perguntas_respostas": []
}
```

## Campos Da Startup

### `nome`

Nome da startup exibido no catalogo e na tela de detalhes.

Tipo:

```txt
string
```

Obrigatorio:

```txt
sim
```

### `descricao`

Descricao resumida do projeto. No catalogo, pode ser exibida de forma abreviada. Na tela de detalhes, deve ser exibida completa.

Tipo:

```txt
string
```

Obrigatorio:

```txt
sim
```

### `setor`

Area de atuacao da startup.

Exemplos:

```txt
Sustentabilidade / IoT
Fintech
Educacao
Saude
Agronegocio
```

Tipo:

```txt
string
```

Obrigatorio:

```txt
recomendado
```

### `estagio`

Nivel de maturidade da startup.

Valores esperados:

```txt
Nova
Em operacao
Em expansao
```

Tipo:

```txt
string
```

Obrigatorio:

```txt
sim
```

Uso no aplicativo:

- Filtro por estagio no catalogo.
- Indicador de maturidade e risco do projeto.

### `status`

Indica se a startup deve aparecer no aplicativo.

Valores esperados:

```txt
ativa
inativa
```

Tipo:

```txt
string
```

Obrigatorio:

```txt
sim
```

Decisao da Fase 1:

- A rota `GET /startups` deve retornar apenas startups com `status == "ativa"`.
- Startups inativas podem continuar no Firestore, mas nao devem aparecer no catalogo.

### `capital_aportado`

Valor simulado de capital ja aportado na startup.

Tipo:

```txt
number
```

Obrigatorio:

```txt
sim
```

Uso no aplicativo:

- Exibicao no catalogo ou detalhes.
- Pode ser formatado em reais no Flutter.

### `tokens_emitidos`

Quantidade total de tokens simulados emitidos para a startup.

Tipo:

```txt
number
```

Obrigatorio:

```txt
sim
```

Uso no aplicativo:

- Exibicao na tela de detalhes.
- Base futura para compra e venda simulada de tokens.

### `preco_atual_centavos`

Preco atual de referencia do token da startup, sempre armazenado em centavos.

Tipo:

```txt
number
```

Obrigatorio:

```txt
recomendado
```

Uso no aplicativo:

- Exibicao do preco atual nas telas de negociacao.
- Referencia para validar faixas de preco do balcao.
- Base futura para o dashboard de valorizacao.

### `preco_primario_centavos`

Preco inicial ou primario do token da startup, sempre armazenado em centavos.

Tipo:

```txt
number
```

Obrigatorio:

```txt
recomendado
```

Uso no aplicativo:

- Referencia inicial quando ainda nao houver transacoes.
- Fallback para validar ofertas do balcao quando `preco_atual_centavos` ainda nao estiver definido.

### `video_demo`

Link para video demonstrativo da startup.

Tipo:

```txt
string
```

Obrigatorio:

```txt
nao
```

Uso no aplicativo:

- Pode ser exibido como link na tela de detalhes.
- Se estiver vazio, a interface deve ocultar a secao de video.

### `socios`

Lista de socios e suas participacoes percentuais.

Tipo:

```txt
array<map>
```

Estrutura de cada item:

```txt
nome: string
participacao: number
```

Exemplo:

```json
{
  "nome": "Ana Souza",
  "participacao": 40
}
```

Uso no aplicativo:

- Exibicao da estrutura societaria.
- Pode ser mostrado em lista ou grafico simples no detalhe da startup.

### `mentores_conselho`

Lista de mentores, conselheiros ou participantes externos.

Tipo:

```txt
array<map>
```

Estrutura de cada item:

```txt
nome: string
papel: string
```

Exemplo:

```json
{
  "nome": "Prof. Ricardo Martins",
  "papel": "Mentor"
}
```

Uso no aplicativo:

- Exibicao na tela de detalhes.
- Pode ser omitido se a lista estiver vazia.

### `perguntas_respostas`

Lista de perguntas e respostas publicas relacionadas a startup.

Tipo:

```txt
array<map>
```

Estrutura recomendada:

```txt
pergunta: string
resposta: string
autor: string
criado_em: timestamp
```

Observacao:

- No exemplo atual, a lista esta vazia.
- A estrutura acima e uma recomendacao para manter padrao quando a funcionalidade de perguntas for implementada.

### `criado_em`

Data de criacao do documento da startup.

Tipo:

```txt
timestamp
```

Obrigatorio:

```txt
sim
```

### `atualizado_em`

Data da ultima atualizacao do documento da startup.

Tipo:

```txt
timestamp
```

Obrigatorio:

```txt
sim
```

## Decisoes Para O Backend

Na proxima fase, o backend deve criar rotas para expor os dados da colecao `startups`.

Rotas planejadas:

```txt
GET /startups
GET /startups/:id
```

Contrato da rota `GET /startups`:

- Buscar documentos da colecao `startups`.
- Retornar apenas startups com `status == "ativa"`.
- Ordenar preferencialmente por `nome`.
- Retornar dados suficientes para o catalogo.

Campos recomendados para o catalogo:

```txt
id
nome
descricao
setor
estagio
status
capital_aportado
tokens_emitidos
preco_atual_centavos
preco_primario_centavos
```

Contrato da rota `GET /startups/:id`:

- Buscar uma startup especifica pelo ID do documento.
- Retornar todos os campos necessarios para a tela de detalhes.
- Retornar erro `404` caso o documento nao exista.

## Decisoes Para O Flutter

O aplicativo Flutter deve criar ou atualizar os seguintes elementos:

```txt
lib/models/startup_model.dart
lib/core/services/startup_service.dart
lib/screens/catalog/catalog_screen.dart
lib/screens/catalog/startup_detail_screen.dart
lib/widgets/startup_card.dart
```

Decisoes:

- O `StartupModel` deve converter os nomes do Firestore para nomes Dart.
- No Firestore, os campos usam `snake_case`, como `capital_aportado`.
- No Dart, os atributos devem usar `camelCase`, como `capitalAportado`.
- A tela de catalogo nao deve acessar HTTP diretamente.
- A tela deve chamar `StartupService`, que chama o backend.

## Mapeamento Firestore Para Dart

```txt
Firestore              Dart
------------------------------------
id                     id
nome                   nome
descricao              descricao
setor                  setor
estagio                estagio
status                 status
capital_aportado       capitalAportado
tokens_emitidos        tokensEmitidos
preco_atual_centavos   precoAtualCentavos
preco_primario_centavos precoPrimarioCentavos
video_demo             videoDemo
socios                 socios
mentores_conselho      mentoresConselho
perguntas_respostas    perguntasRespostas
criado_em              criadoEm
atualizado_em          atualizadoEm
```

## Criterios De Conclusao Da Fase 1

A Fase 1 esta concluida quando:

- O schema da colecao `startups` esta documentado.
- Os campos obrigatorios e opcionais estao claros.
- Os valores esperados para `estagio` e `status` estao definidos.
- O contrato planejado para as rotas do backend esta descrito.
- O mapeamento entre Firestore e Dart esta definido.

## Proxima Fase

A Fase 2 deve implementar as rotas do backend:

```txt
GET /startups
GET /startups/:id
```

Essas rotas serao a ponte entre a colecao `startups` do Firestore e o aplicativo Flutter.
