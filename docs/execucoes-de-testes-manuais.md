# Registro de Execuções de Testes Manuais — SGC para MSClean

> Registra cada rodada de **testes manuais**: data, versão testada, ambiente,
> resultados e issues abertas. O plano define a estratégia, os casos o roteiro,
> a matriz a cobertura — este documento, a **execução**.
>
> Testes **automatizados** ficam de fora: o CI já registra cada execução
> (`analyze + test` por PR).

## Convenções

- Cada rodada é uma seção `Execução NNN`, em ordem cronológica.
- Toda rodada registra **data**, **objeto** (PR/commit testado), **ambiente**
  (`plano-de-testes.md` §2.1), **executor** e o resultado por passo, mapeado aos
  CT-IDs de `casos-de-teste.md` quando houver.
- **Resultados possíveis:**

| Resultado | Significado |
|---|---|
| Aprovado | Comportamento observado igual ao esperado. |
| Aprovado com ressalva | Critério atendido, mas a rodada revelou algo a tratar (vira issue). |
| Reprovado | Comportamento observado diferente do esperado (vira issue de bug). |
| Adiado | Passo não executado nesta rodada, com motivo e destino registrados. |

- Todo achado (reprovação ou ressalva) referencia a issue aberta a partir dele.
- Ocorrências de **ambiente** (ex.: backend fora do ar) também são registradas,
  mesmo quando não são defeito do app.

## Execução 001 — Verificação manual do RF-001 (pré-merge do PR #44)

- **Data:** 2026-07-16
- **Objeto:** PR #44 (`feat/rf-001-cadastro-cliente`) — RF-001 Cadastro de
  Cliente, antes do merge na `main`.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  **real** do MVP — alternativa prevista em `plano-de-testes.md` §2.1 (o
  dispositivo da cliente não estava acessível).
- **Executor:** Wilson Gorosthides.
- **Roteiro:** ad-hoc de 10 passos montado para a validação do PR (anterior à
  execução formal do CT-023, que depende de RF-002 e RF-008). Os passos foram
  mapeados a posteriori aos CT-IDs correspondentes.

### Ocorrência de ambiente (antes da rodada)

Na primeira tentativa de salvar um cliente, o app exibiu o SnackBar genérico
"Erro ao salvar. Tente novamente.". Diagnóstico via REST (curl direto na API do
Supabase): o DNS do projeto não resolvia — o projeto estava **pausado** pelo
free tier do Supabase (inatividade). **Não era defeito do app.** Após o resume
pelo painel, tabela `clientes`, RLS e policy foram verificados intactos via REST
(GET 200, POST 201, DELETE 204) e a rodada prosseguiu.

Aprendizados que viraram rastro:

- O estado "lista vazia" pode mascarar erro de conexão ("Nenhum cliente
  encontrado." aparece mesmo com o backend fora) → **issue #47** (bug).
- Restaurar o ambiente do zero depende de conhecimento não documentado →
  reforça a urgência do guia de deploy (**issue #21**).

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Estado vazio: "Nenhum cliente encontrado." com a tabela vazia | CT-013 | Aprovado |
| 2 | Caminho feliz: salvar fecha o formulário e o cliente aparece na lista sem recarga | CT-004, CT-005 | Aprovado |
| 3 | Campos obrigatórios: salvar com tudo vazio bloqueia e aponta os três campos | CT-001 | Aprovado |
| 4 | Só espaços no telefone: salvamento bloqueado apontando o campo | CT-002 | Aprovado |
| 5 | Telefone inválido: `12#34` rejeitado com a mensagem de formato | CT-003 | Aprovado com ressalva |
| 6 | Ordem alfabética com inserção em tempo real (novo cliente "B" entra entre "A" e "C") | CT-010, CT-012 | Aprovado |
| 7 | Busca: filtra ao digitar, mensagem sem correspondência, limpar restaura | CT-014–CT-018 | Aprovado |
| 8 | Realtime na direção contrária: exclusão pelo painel do Supabase some da lista sem F5 | CT-012 | Aprovado |
| 9 | Erro de rede: salvar offline exibe SnackBar e mantém o formulário aberto | — | Adiado |
| 10 | Limpeza dos dados de teste | — | Concluída |

Notas por passo:

- **Passo 5 (ressalva):** o critério do RF-001 restringe apenas os *caracteres*
  do telefone — por isso, removido o `#`, o valor `1234` (4 dígitos) foi salvo.
  Comportamento **conforme o requisito atual**, mas a rodada expôs que o
  critério não impede telefone curto demais → **issue #48** (mudança de
  requisito, decisão pendente: mínimo de dígitos).
- **Passo 8:** houve dificuldade inicial para localizar a tabela no painel do
  Supabase (projeto recém-restaurado da pausa); o passo foi concluído junto com
  a limpeza (passo 10) — a exclusão pelo painel refletiu na lista do app em
  tempo real, como esperado.
- **Passo 9 (adiado):** ficará para verificação em dispositivo físico (alternar
  Wi-Fi no desktop é menos representativo). O comportamento já é coberto pelo
  teste automatizado `client_form_screen_test: falha ao salvar exibe erro e
  mantém o formulário aberto` (nota do CT-005).

### Achados adicionais (fora do escopo do RF-001)

- Tocar em um cliente da lista não abre nenhuma tela — **esperado**: edição
  (RF-002) e exclusão pelo app (RF-008) ainda não existem; são os próximos RFs
  (issues #26/#33 e a story de exclusão).

### Veredicto

**PR #44 validado**: os critérios de aceitação do RF-001 se confirmaram no
ambiente real; nenhum defeito de código encontrado (a única falha observada foi
a ocorrência de ambiente, diagnosticada e resolvida). Merge realizado em
2026-07-16; achados rastreados nas issues #47 e #48.

## Execução 002 — Verificação manual do RF-002 (pré-merge do PR #55)

- **Data:** 2026-07-18 e 2026-07-19 (duas rodadas).
- **Objeto:** PR #55 (`feat/edicao-de-cliente`) — RF-002 Edição de Cliente,
  antes do merge; inclui regressão do critério novo do telefone (CT-024,
  PR #54, já mergeado).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP.
- **Executor:** o desenvolvedor.

### Rodada 1 (2026-07-18)

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| A1–A5 | Telefone: `1234`/`192` bloqueados; 8 dígitos e formatado aceitos; `12#34` rejeitado | CT-024, CT-003 | Aprovado |
| B6 | Toque no cliente abre o formulário pré-preenchido | CT-006 | Aprovado |
| B7 | Validações do cadastro valem na edição | CT-007 | Aprovado |
| B8 | Edição refletida na lista em tempo real | CT-008 | **Reprovado** |
| B9 | Cancelar (voltar) não grava nada | CT-009 | Aprovado com ressalva |
| C10 | Regressão: cadastro, busca, estado vazio | CT-004, CT-014–018 | Aprovado |

- **CT-008 (reprovado):** o banco atualizava (confirmado no painel e via F5),
  mas a lista aberta não refletia; reabrir o cliente mostrava o dado antigo.
- **CT-009 (ressalva):** não há botão "Cancelar" dedicado — o voltar é o
  mecanismo de cancelamento, o que atende o critério; registrado como
  observação de conformidade.

### Diagnóstico do CT-008 (entre as rodadas)

Investigação em camadas, nesta ordem: **(1)** publication do servidor ok
(`pg_publication`: insert/update/delete todos `true`); **(2)** F5 sempre
trazia o dado novo — escrita íntegra, problema só na entrega do evento;
**(3)** upgrade do `supabase_flutter` 2.12→2.16 sem efeito (revertido);
**(4)** defeito real de arquitetura corrigido — a Home recriava a assinatura
realtime a cada rebuild (churn por tecla na busca); a assinatura única
resolveu a lista vazia na abertura, mas não o UPDATE; **(5)** teste puro
(edição pelo painel com o app parado) provou que o evento UPDATE **não
chega** ao app. Conclusão: limitação do projeto Supabase atual — **issue
#57**. Critério do RF-002 **renegociado** (`requisitos.md` 2.4): reflexo
"imediatamente ao retornar do formulário" (a Home renova a stream no
retorno), em vez de "em tempo real".

### Rodada 2 (2026-07-19, pós-renegociação)

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Telefone editado aparece ao reabrir o cliente após salvar | CT-008 | Aprovado |
| 2 | Cliente novo aparece na lista ao voltar do cadastro | CT-004 | Aprovado |
| 3 | Voltar sem salvar mantém a lista intacta | CT-009 | Aprovado |
| 4 | Busca filtra e restaura normalmente | CT-014–018 | Aprovado |

### Veredicto

**PR #55 validado** contra o critério renegociado: todos os CTs do RF-002
aprovados na rodada 2; o achado da rodada 1 virou correção de arquitetura
(assinatura única), mudança de requisito documentada e a issue #57 para
restaurar o realtime pleno no futuro.

## Execução 003 — Verificação manual do RF-008 (pré-merge do PR de exclusão)

- **Data:** 2026-07-20.
- **Objeto:** branch `feat/exclusao-de-cliente` — RF-008 Exclusão de Cliente,
  antes do merge.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP.
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Lixeira abre o diálogo "Confirmar exclusão?"; nada removido antes | CT-019 | Aprovado |
| 2 | Cancelar mantém o cliente na lista | CT-020 | Aprovado |
| 3 | Confirmar remove do banco e some da lista imediatamente | CT-021 | Aprovado |
| 4 | SnackBar "Cliente excluído" após a exclusão | CT-022 | Aprovado |
| 5 | Toque na linha (não na lixeira) abre a edição | Regressão RF-002 | Aprovado |
| 6 | Cadastro e busca seguem funcionando | Regressão | Aprovado |

- **Ponto de atenção do passo 3:** o reflexo da exclusão foi imediato,
  garantido pela renovação local da stream após a ação (critério renegociado,
  `requisitos.md` 2.5). Diferente do UPDATE do RF-002, o DELETE nativo do
  realtime **não** foi testado isoladamente aqui — a renovação foi adotada por
  consistência e robustez, sem presumir que o DELETE falhe (contexto na
  issue #57).

### Veredicto

**RF-008 validado** em rodada única: os quatro critérios aprovados, sem
regressão no cadastro, edição e busca. Com esta feature, o MVP fica completo
(5/5).

## Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2026-07-17 | 1.0 | Wilson Gorosthides | Criação do registro de execuções de testes manuais, com as convenções de registro e a Execução 001 (RF-001, pré-merge do PR #44) — issue #49. |
| 2026-07-19 | 1.1 | Wilson Gorosthides | Execução 002 (RF-002, pré-merge do PR #55): duas rodadas, com o diagnóstico do CT-008 (realtime UPDATE não entregue, issue #57), a renegociação do critério (`requisitos.md` 2.4) e a aprovação final. |
| 2026-07-20 | 1.2 | Wilson Gorosthides | Execução 003 (RF-008, pré-merge do PR de exclusão): rodada única, quatro CTs aprovados, sem regressão; reflexo da exclusão imediato via renovação da stream (`requisitos.md` 2.5). MVP completo. |
