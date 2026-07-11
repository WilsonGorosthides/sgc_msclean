# Plano de Testes — SGC para MSClean

> Define **o que** testar, **como** e **em que ordem** no MVP do SGC.
> Cobre a estratégia, os níveis de teste e o fluxo de execução; a matriz de
> rastreabilidade requisito ↔ teste vive em documento próprio
> (`docs/matriz-rastreabilidade.md`), referenciado na seção 7. Aprofunda, em plano
> formal, a Estratégia de Testes esboçada em `docs/arquitetura.md` §8 — não a
> substitui nem a contradiz.

## 1. Introdução

### 1.1 Objetivo

Estabelecer um plano de testes verificável para o MVP do SGC, garantindo que cada
funcionalidade entregue seja rastreável a um critério de aceitação de
`docs/requisitos.md`. O plano precede a implementação de cada feature (teste antes
da feature), conforme a decisão registrada na auditoria inicial e em
`arquitetura.md` §8.

### 1.2 Escopo

Este plano cobre os requisitos funcionais do **MVP**:

| RF | Descrição | Situação atual |
|---|---|---|
| RF-001 | Cadastro de Cliente | Não implementado |
| RF-002 | Edição de Cliente | Não implementado |
| RF-003 | Visualização da Lista | Implementado |
| RF-004 | Busca por palavra-chave | Implementado |
| RF-008 | Exclusão de Cliente | Não implementado |

**Fora de escopo** deste plano: RF-005 (histórico de serviço), RF-006 (histórico de
pagamento) e RF-007 (autenticação), previstos para o Pós-MVP (ver README, seção
Roadmap). Testes desses requisitos serão planejados quando entrarem em
desenvolvimento.

### 1.3 Owner

Projeto solo. Wilson Gorosthides acumula os papéis de desenvolvimento e QA:
escreve os testes, implementa as features e faz a autorrevisão antes do PR.

## 2. Estratégia e Tipos de Teste

### 2.1 Ambiente de testes

Os testes rodam **localmente**, sem matriz de dispositivos físicos — o app não
depende de hardware específico (RNF-003: um único código-fonte para Android e web
desktop, sem sensores, câmera ou recursos nativos críticos).

| Recurso | Comando |
|---|---|
| Testes automatizados (unit + widget) | `fvm flutter test` |
| Execução manual em web desktop | `fvm flutter run -d chrome` |
| Execução manual em Android | `fvm flutter run -d <emulador>` |

A verificação manual em Android usa **emulador**; não há requisito de device físico
nem de cobrir múltiplos modelos/versões de aparelho.

### 2.2 Tipos de teste

- **Unitário** — valida lógica isolada, com o cliente Supabase mockado (ver seção 5):
  - `ClientModel`: `fromMap` com campos presentes, ausentes e nulos; ida e volta
    `toMap`/`fromMap`.
  - `SupabaseService`: lógica de filtro da busca (case-insensitive, por nome ou
    endereço, resultado vazio) e mapeamento da stream para `ClientModel`.
- **Widget** — verifica os estados da `HomeScreen`:
  - **Carregando** (enquanto a stream não emitiu).
  - **Vazio** — exibe "Nenhum cliente encontrado.".
  - **Populado** — renderiza a lista ordenada por nome.
  - **Filtrando** — ao digitar na busca, a lista reduz ao correspondente e volta ao
    completo quando o campo é limpo.

### 2.3 Modelo de teste (pirâmide de 3 camadas)

O projeto adota uma pirâmide enxuta, dimensionada ao porte do app:

```
        ┌─────────────────────────┐
        │  integration_test (E2E) │   Fase 2 — documentado, não ativo
        ├─────────────────────────┤
        │        widget           │   ativo hoje
        ├─────────────────────────┤
        │        unitário         │   ativo hoje (base da pirâmide)
        └─────────────────────────┘
```

- **Unitário e widget — ativos hoje.** Cobrem model, service e os estados da tela.
- **`integration_test` (E2E) — Fase 2, documentado, não ativo.** Cobriria o fluxo
  ponta a ponta cadastrar → listar → editar → excluir em app real contra um
  Supabase.

**Por que o E2E não entra agora:**

1. **Não há fluxo real para testar.** RF-001/002/008 (cadastro, edição, exclusão)
   ainda não estão implementados; sem eles, o fluxo E2E não existe.
2. **Exigiria um Supabase de teste dedicado.** Um E2E real precisa de um projeto/
   schema Supabase isolado (dados descartáveis, sem tocar produção), infraestrutura
   que não se justifica antes de haver o que testar.

**Gatilho de entrada da Fase 2:** quando RF-001, RF-002 e RF-008 estiverem
implementados, planeja-se a suíte `integration_test` do fluxo E2E — em conjunto com
o provisionamento de um Supabase de teste dedicado.

## 3. Critérios de Entrada e Saída

Aplicam-se por feature do MVP (unidade = RF de `requisitos.md`).

### 3.1 Critérios de entrada (começar a testar quando)

- Critérios de aceitação do RF definidos em `requisitos.md` §2.
- Dependências de código disponíveis (`ClientModel`, `SupabaseService`, tela alvo).
- `mocktail` disponível como dependência de teste.

### 3.2 Critérios de saída (feature pronta quando)

- Todos os critérios de aceitação do RF cobertos por ao menos um caso de teste.
- `fvm flutter test` verde (nenhum teste falhando ou pulado sem justificativa).
- `fvm flutter analyze` sem erros.
- Rastreabilidade atualizada (seção 7): o RF aponta para o(s) caso(s) de teste real.

Estes critérios são locais (suíte rodando na máquina do desenvolvedor). Não há
etapa de "build instalável em device" como gate — a validação é a suíte local
verde mais a verificação manual opcional em chrome/emulador.

## 4. Níveis de Teste

| Nível | Alvo | Ferramenta | Situação | Diretório |
|---|---|---|---|---|
| Unitário | `ClientModel`, `SupabaseService` | `flutter_test` + `mocktail` | Ativo | `test/unit/` |
| Widget | Estados da `HomeScreen` | `flutter_test` | Ativo | `test/widget/` |
| Integração (E2E) | Fluxo cadastrar→listar→editar→excluir | `integration_test` | Fase 2 (documentado) | `integration_test/` |

Mocks e *fakes* compartilhados ficam em `test/mocks/` (ex.: mock do cliente
Supabase e da stream de `clientes`).

Os diretórios são relativos à raiz do app Flutter (`app/sgc_msclean/`). Substituem o
`test/widget_test.dart` legado — o smoke test do contador, que a auditoria
registrou como quebrado e será removido ao entrarem os primeiros testes reais
(`arquitetura.md` §8).

## 5. Automação de Testes

### 5.1 Ferramentas

- **`flutter_test`** — framework de teste oficial do Flutter (unitário e widget).
- **`mocktail`** — biblioteca de mock para isolar o cliente Supabase nos testes de
  service. Escolhida por **não exigir `build_runner`** (sem geração de código): os
  mocks são escritos à mão, o que mantém a suíte simples e rápida de manter no porte
  deste projeto.

### 5.2 Integração Contínua (CI)

**Não há CI configurado.** O repositório ainda não tem `.github/workflows` — os
testes rodam apenas localmente, por decisão manual do desenvolvedor.

Isto é **dívida técnica registrada**, não uma capacidade existente:

| Item | Situação | Quando abrir issue |
|---|---|---|
| CI (GitHub Actions) rodando `flutter analyze` + `flutter test` em cada PR | Inexistente | Quando o RF-001 estiver perto de fechar — a primeira feature de escrita torna a regressão silenciosa cara o bastante para justificar o gate automático. |

Enquanto não houver CI, o gate de qualidade é a suíte local verde exigida pela
Definição de Pronto (`gerencia-de-configuracao.md` §9).

## 6. Cobertura

A meta de cobertura é **qualitativa**, não um percentual numérico:

> **Toda feature do MVP tem ao menos um teste rastreável a um critério de aceitação
> de `requisitos.md`.**

Nenhuma feature do MVP é considerada pronta sem teste correspondente. Não se
persegue um número de cobertura (ex.: "80% de linhas") — perseguir percentual num
projeto deste porte incentiva testes de baixo valor só para inflar a métrica. O que
importa é que cada critério de aceitação verificável tenha um caso de teste que o
exercite, o que a matriz de rastreabilidade (seção 7) torna auditável.

## 7. Matriz de Rastreabilidade

A matriz que liga cada RF do MVP ao seu critério de aceitação (`requisitos.md` §2) e
ao caso de teste que o exercita vive em documento próprio:
**[`docs/matriz-rastreabilidade.md`](./matriz-rastreabilidade.md)**.

Foi extraída para lá porque é conteúdo que muda a cada RF fechado (o caso de teste
sai de "a definir" para o nome real), enquanto este plano é estável — mantê-la
separada evita que cada feature nova gere diff no plano de testes inteiro. A matriz
é o artefato que torna auditável a meta de cobertura da seção 6: nenhum critério de
aceitação verificável fica descoberto.

## 8. Modelo de Severidade e Prioridade

Classificação simplificada, com **dois níveis** em cada eixo — suficiente para o
porte do projeto (usuária única, um desenvolvedor). Severidade descreve o impacto
técnico do defeito; prioridade, a urgência de corrigi-lo.

**Severidade:**

| Nível | Significado |
|---|---|
| Alta | Bloqueia uma funcionalidade do MVP ou corrompe/perde dados de cliente (ex.: salvar não persiste, exclusão remove o cliente errado, lista não carrega). |
| Baixa | Não bloqueia o uso; afeta acabamento ou casos de borda (ex.: mensagem com texto impreciso, ordenação incorreta com acentuação). |

**Prioridade:**

| Nível | Significado |
|---|---|
| Alta | Corrigir antes de fechar o RF/abrir o PR. |
| Baixa | Pode virar issue e ser tratado depois, sem travar a entrega atual. |

Regra prática: todo defeito de severidade Alta é prioridade Alta. Um defeito de
severidade Baixa pode ser prioridade Baixa (vira dívida/issue) quando não
compromete os critérios de aceitação do RF em entrega.

## 9. Plano de Execução

Fluxo de trabalho solo, aplicado por feature do MVP:

1. **Branch.** Criar branch dedicada da `main` atualizada
   (`<tipo>/<descricao>`, `gerencia-de-configuracao.md` §4).
2. **Testes antes do código.** Escrever os casos de teste do RF a partir dos
   critérios de aceitação de `requisitos.md` §2 (a suíte falha — vermelho — porque
   a feature ainda não existe).
3. **Implementação.** Implementar a feature até os testes passarem.
4. **Suíte verde.** `fvm flutter test` e `fvm flutter analyze` sem falhas nem erros.
5. **PR.** Abrir o PR seguindo `gerencia-de-configuracao.md` §6 (título
   `pr(<tipo>): ...`, corpo no template, `Closes #N`).
6. **Autorrevisão.** Revisar o próprio diff antes do merge — código, testes e
   sincronização de documentação (Definição de Pronto, §9 da GCS).

Enquanto não houver CI (seção 5.2), os passos 4 e 6 são executados manualmente pelo
desenvolvedor; a suíte local verde é o gate de qualidade.

## 10. Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2026-07-10 | 1.0 | Wilson Gorosthides | Criação do plano de testes do MVP: estratégia (pirâmide de 3 camadas com E2E como Fase 2), níveis de teste, automação com `mocktail`, cobertura qualitativa, matriz de rastreabilidade dos RFs do MVP, modelo de severidade/prioridade e plano de execução solo. |
