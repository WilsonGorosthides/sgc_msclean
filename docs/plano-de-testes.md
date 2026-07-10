# Plano de Testes — SGC para MSClean

> Define **o que** testar, **como** e **em que ordem** no MVP do SGC.
> Cobre a estratégia, os níveis de teste, a rastreabilidade requisito ↔ teste e o
> fluxo de execução. Aprofunda, em plano formal, a Estratégia de Testes esboçada em
> `docs/arquitetura.md` §8 — não a substitui nem a contradiz.

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

Liga cada RF do MVP ao seu critério de aceitação (copiado literalmente de
`requisitos.md` §2) e ao nome do caso de teste que o exercita. Casos de RFs ainda
não implementados (RF-001, RF-002, RF-008) ficam **a definir** até o teste ser
escrito, na ordem "teste antes da feature".

| RF | Critério de aceitação (`requisitos.md` §2) | Caso de teste |
|---|---|---|
| RF-001 | Nome, Endereço e Telefone são campos obrigatórios. | `a definir` |
| RF-001 | Ao tentar salvar com qualquer campo obrigatório vazio (ou só com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem indicando o(s) campo(s) pendente(s). | `a definir` |
| RF-001 | O Telefone aceita apenas dígitos, espaços e os símbolos `+ ( ) -`; outros caracteres são rejeitados na validação. | `a definir` |
| RF-001 | Após salvar com sucesso, o novo cliente aparece na lista sem necessidade de recarregar a tela (atualização em tempo real via stream). | `a definir` |
| RF-001 | Após salvar, o formulário é fechado e o usuário retorna à lista. | `a definir` |
| RF-002 | O formulário de edição abre pré-preenchido com os dados atuais do cliente. | `a definir` |
| RF-002 | As mesmas validações do cadastro (RF-001) se aplicam: campos obrigatórios e formato de telefone. | `a definir` |
| RF-002 | Uma edição só é considerada salva após o usuário confirmar; nesse momento os dados são persistidos no banco e refletidos na lista em tempo real. | `a definir` |
| RF-002 | Ao cancelar, nenhuma alteração é gravada e os dados originais do cliente permanecem intactos. | `a definir` |
| RF-003 | A lista é ordenada por Nome em ordem alfabética crescente (ordenação padrão). | `home_screen_test: lista populada em ordem alfabética` |
| RF-003 | Cada item exibe, no mínimo, Nome e Endereço. | `home_screen_test: item exibe nome e endereço` |
| RF-003 | A lista reflete inserções, edições e exclusões em tempo real (stream), sem ação manual de atualização. | `home_screen_test: lista reage à emissão da stream` |
| RF-003 | Quando não há nenhum cliente cadastrado, a tela exibe a mensagem "Nenhum cliente encontrado." em vez de uma lista vazia silenciosa. | `home_screen_test: estado vazio exibe mensagem` |
| RF-004 | A busca filtra por **Nome** ou **Endereço** (correspondência de substring). | `supabase_service_test: filtro por nome ou endereço` |
| RF-004 | A busca é **case-insensitive** (não diferencia maiúsculas de minúsculas). | `supabase_service_test: filtro case-insensitive` |
| RF-004 | A lista é filtrada em tempo real conforme o usuário digita, sem necessidade de botão "buscar". | `home_screen_test: filtragem ao digitar na busca` |
| RF-004 | Quando nenhum cliente corresponde ao termo, a tela exibe a mensagem "Nenhum cliente encontrado.". | `home_screen_test: busca sem correspondência exibe mensagem` |
| RF-004 | Com o campo de busca vazio, todos os clientes são exibidos. | `home_screen_test: busca vazia exibe todos` |
| RF-008 | A exclusão exige confirmação explícita do usuário (diálogo "Confirmar exclusão?") antes de efetivar. | `a definir` |
| RF-008 | Ao cancelar a confirmação, o cliente **não** é removido e permanece na lista. | `a definir` |
| RF-008 | Ao confirmar, o cliente é removido do banco e desaparece da lista em tempo real. | `a definir` |
| RF-008 | Após a exclusão bem-sucedida, o sistema dá feedback visual (ex.: SnackBar "Cliente excluído"). | `a definir` |

Os nomes de caso de teste para RF-003 e RF-004 são o alvo pretendido da suíte; à
medida que os testes forem escritos, esta tabela é a fonte que confirma que nenhum
critério ficou descoberto.

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
