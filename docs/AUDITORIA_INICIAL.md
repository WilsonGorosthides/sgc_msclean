# Auditoria Inicial — SGC para MSClean

| | |
|---|---|
| **Projeto** | SGC (Sistema de Gestão de Clientes) — MSClean |
| **Autor** | Wilson Gorosthides |
| **Data** | 2026-06-27 |
| **Versão** | 1.0 |
| **Status** | Concluída |

## 1. Objetivo da Auditoria

Estabelecer o estado real do projeto na retomada, confrontando o que a
documentação descrevia com o que o código de fato implementa. A auditoria
serve como marco zero: a partir dela, código e documentação passam a ser
mantidos em sincronia. Não é um relatório de defeitos — é o ponto de
referência que torna as próximas decisões rastreáveis.

## 2. Estado Real do Código

App **Flutter** com backend **Supabase**. Toda a lógica está em quatro
arquivos:

```
lib/
├── main.dart                       # inicializa Supabase via .env
├── models/client_model.dart        # id, nome, endereco, telefone
├── screens/home_screen.dart        # lista + busca
└── services/supabase_service.dart  # leitura (stream) apenas
```

**Features implementadas:**

| Requisito | Estado | Evidência |
|---|---|---|
| RF-003 Listagem | ✅ Funciona | `getClientsStream` — stream em tempo real |
| RF-004 Busca | ✅ Funciona | filtro por nome/endereço no `home_screen` |
| RF-001 Cadastro | ❌ A fazer | FAB com `onPressed: () {}` vazio; service sem `insert` |
| RF-002 Edição | ❌ A fazer | sem tela de formulário, sem `update` |
| RF-008 Exclusão | ❌ A fazer | sem `delete` |

**Testes:** o único arquivo (`test/widget_test.dart`) é o template padrão do
Flutter (o "counter increments smoke test"). Procura widgets que não existem
neste app — **falha ao executar**. Cobertura real: 0%.

**Configuração e segurança:**
- `main.dart` exige `SUPABASE_URL` e `SUPABASE_ANON_KEY` de um `.env` que está
  no `.gitignore` (correto) e **não está no repositório**. Não há `.env.example`
  — quem clona não sabe quais chaves preencher e o app não inicia.
- `anonKey` exposta no cliente é o comportamento normal do Supabase; só é
  segura **se houver Row Level Security (RLS) configurada** no painel — o que
  não é verificável pelo código.
- `print()` usado em produção (`home_screen`); `pubspec.yaml` ainda com
  `description: "A new Flutter project."`.

## 3. Estado da Documentação Anterior

A documentação descrevia um sistema **maior e tecnicamente diferente** do que o
código entrega:
- Stack descrita: **Firebase (Firestore + Authentication)**.
- Model descrito: 5 campos (`nomeCompleto`, `endereco`, `telefone`,
  `historicoServicos[]`, `historicoPagamentos[]`).
- Estrutura descrita: pastas `repositories/`, `client_list_screen.dart`,
  `client_form_screen.dart`.
- Escopo descrito: cadastro, edição, exclusão, históricos e autenticação como
  parte do produto.

## 4. Divergências Identificadas

| # | Categoria | Documentado | Real |
|---|---|---|---|
| D1 | **Stack** | Firebase / Firestore / Auth | Supabase / PostgreSQL |
| D2 | **Escopo** | RF-001, 002, 005, 006, 007 implementados | apenas listagem e busca |
| D3 | **Model** | 5 campos (com históricos) | 3 campos (nome, endereco, telefone) |
| D4 | **Estrutura** | `repositories/`, telas de lista/form separadas | `services/`, `home_screen` única |
| D5 | **Testes** | "testes unitários" | template padrão que falha; cobertura 0% |

A origem de D1 é rastreável: o commit "reconstrução da base com supabase" trocou
o backend, mas a documentação nunca foi atualizada.

## 5. Decisões Tomadas

| Tema | Decisão |
|---|---|
| **Stack** | Supabase é a stack oficial. Firebase fica fora. |
| **Escopo do MVP** | Confirmado em 5 RFs: listagem, busca, cadastro, edição, exclusão. |
| **Autenticação** | Fora do MVP. Usuária única no próprio celular; RLS no Supabase é o controle de segurança. Autenticação retorna no Pós-MVP. |
| **Sincronização de docs** | Documentação é atualizada **antes** de iniciar feature nova. Sem divergência acumulada. |
| **Testes** | Plano de testes precede a implementação de cada feature do MVP. |
| **Higiene técnica** | `.env.example` e correção do `pubspec.yaml` entram no fluxo de trabalho. |

## 6. Próximos Passos Imediatos

1. Sincronizar `requisitos.md` e `arquitetura.md` com a realidade (Supabase,
   model de 3 campos, escopo MVP).
2. Criar `.env.example` com as chaves esperadas.
3. Verificar RLS no painel do Supabase.
4. Definir o plano de testes do CRUD antes de codar.
5. Implementar a primeira feature do MVP: cadastro (RF-001).

## 7. Lições Registradas

- **Documentação desacompanhada vira armadilha.** Um README bem escrito mas
  factualmente errado é pior que nenhum — direciona quem retoma para o caminho
  errado. Sincronizar docs passa a ser parte da definição de pronto.
- **Template de teste não é teste.** Arquivo de teste que não cobre o app real
  dá falsa sensação de cobertura. Vale 0% e ainda quebra o CI.
- **Decisão de escopo precisa de registro.** Tirar autenticação e históricos do
  MVP é legítimo, mas só é defensável se estiver documentado com o porquê — é o
  que este documento passa a garantir.
