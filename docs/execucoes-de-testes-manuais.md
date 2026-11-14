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
- Desde 2026-11-13 a verificação manual não é mais feita a cada PR: os passos
  de cada entrega acumulam na **Pilha de verificação manual** (seção abaixo) e
  são executados de uma vez antes da instalação do APK (`plano-de-testes.md`
  §5.2). Ao rodar a pilha, ela vira a próxima `Execução NNN` e a seção é
  esvaziada.
- Ocorrências de **ambiente** (ex.: backend fora do ar) também são registradas,
  mesmo quando não são defeito do app.

## Pilha de verificação manual (pendente)

Passos ainda não executados, por entrega, na ordem em que foram mergeadas.
Rodar tudo antes de instalar o APK (issue #23).

**SQL a aplicar no painel antes da rodada:** nenhum.

_(nenhuma entrega na pilha)_

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

## Execução 004 — Verificação manual do endereço opcional (pré-merge, #61)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/endereco-opcional` — endereço opcional com aviso
  (RF-001, `requisitos.md` 2.6), antes do merge.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`).
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Salvar vazio aponta Nome e Telefone, não Endereço | CT-001 | Aprovado |
| 2 | Salvar sem endereço abre o aviso de confirmação | CT-025 | Aprovado |
| 3 | Confirmar ("Salvar mesmo assim") grava e fecha | CT-025 | Aprovado |
| 4 | Cliente sem endereço mostra "Sem endereço" na lista | #61 | Aprovado |
| 5 | Cancelar o aviso não grava e mantém o formulário | CT-025 | Aprovado |
| 6 | Cadastro completo (com endereço) salva sem diálogo | Regressão | Aprovado |

### Veredicto

**#61 validado** em rodada única, suíte automatizada verde. Endereço passa a
opcional com confirmação, sem regressão no cadastro completo.

## Execução 005 — Verificação manual dos múltiplos telefones (pré-merge, #62)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/multiplos-telefones` — um ou mais telefones por
  cliente (RF-001, `requisitos.md` 2.7), antes do merge. Inclui a **migração
  do Supabase** (`telefone` text → `telefones` text[]).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP (após a migração aplicada no SQL Editor).
- **Executor:** o desenvolvedor.

### Migração (pré-teste)

`ALTER TABLE` aplicado no SQL Editor: adiciona `telefones text[]`, copia os
valores de `telefone` para a lista, zera nulos e remove a coluna antiga. O
aviso de operação destrutiva (do `drop column`) foi confirmado após verificar
que os números tinham sido copiados. Migração concluída com sucesso.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Cadastro com um telefone | RF-001 | Aprovado |
| 2 | Cadastro com dois telefones grava o array no banco | CT-026 | Aprovado |
| 3 | Edição vem com os telefones pré-preenchidos | CT-006 | Aprovado |
| 4 | Remover um telefone na edição persiste o restante | CT-026 | Aprovado |
| 5 | Segundo telefone inválido bloqueia o salvamento | CT-026 | Aprovado |
| 6 | Endereço opcional, busca e exclusão sem regressão | Regressão | Aprovado |

### Veredicto

**#62 validado**, suíte automatizada verde e migração do Supabase aplicada. O
app passa a aceitar um ou mais telefones por cliente. Com esta entrega, as duas
mudanças de requisito de preparação para os dados reais (#61 e #62) estão
concluídas.

## Execução 006 — Verificação manual do endereço estruturado (pré-merge, #65)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/endereco-estruturado` — endereço estruturado
  (RF-001/003/004, `requisitos.md` 2.8), antes do merge. Inclui a **migração do
  Supabase** (`endereco` text → jsonb).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP (após a migração aplicada no SQL Editor).
- **Executor:** o desenvolvedor.

### Migração (pré-teste)

`ALTER TABLE` aplicado no SQL Editor: cria `endereco_novo jsonb`, copia o texto
antigo para a chave `logradouro`, zera nulos como `{}`, remove a coluna `text`
e renomeia. Concluída com sucesso. Uma tentativa acidental de reexecutar a
migração acusou `invalid input syntax for type json` no `endereco <> ''` — o
próprio erro confirmou que a coluna já era jsonb (migração já aplicada); a
coluna `endereco_novo` recriada pela reexecução foi removida com
`drop column if exists`. Sem campos de CEP/cidade: a área de atendimento é só
Campo Grande - MS (âncora fixa na consulta ao mapa).

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Cadastro com os campos estruturados grava o objeto jsonb no banco | CT-027 | Aprovado |
| 2 | A lista mostra o resumo (logradouro, número - bairro) | CT-011 | Aprovado |
| 3 | Salvar sem nenhum campo: aviso, confirmar grava, "Sem endereço" na lista | CT-025, CT-011 | Aprovado |
| 4 | Edição vem com os campos pré-preenchidos e reflete ao voltar | CT-006, CT-008 | Aprovado |
| 5 | Busca encontra por bairro/rua, além do nome | CT-014 | Aprovado |
| 6 | Múltiplos telefones e exclusão sem regressão | Regressão | Aprovado |

### Veredicto

**#65 validado**, suíte automatizada verde e migração do Supabase aplicada
(text → jsonb). O endereço passa a ser estruturado (logradouro, número, bairro,
complemento, referência), preparando o resumo na lista, a busca por qualquer
campo e a abertura no mapa (#66).

## Execução 007 — Verificação manual do abrir no Google Maps (pré-merge, #66)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/abrir-endereco-no-maps` — RF-009 abrir o endereço no
  Google Maps (`requisitos.md` 2.9), antes do merge. Sem mudança de schema
  (nenhuma migração).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP.
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Cliente com endereço mostra o ícone de mapa; tocar abre o Google Maps na localização | CT-028 | Aprovado |
| 2 | Cliente sem endereço não mostra o ícone de mapa | CT-028 | Aprovado |
| 3 | Regressão: toque na linha abre a edição; a lixeira exclui — o ícone de mapa convive com eles | Regressão | Aprovado |

### Veredicto

**#66 validado** em rodada única, suíte automatizada verde. A partir de um
cliente com endereço, um toque abre o Google Maps na localização; sem endereço,
o ícone não aparece. Fecha o par de entregas do endereço estruturado (#65) + o
mapa (#66).

## Execução 008 — Verificação manual da agenda como tela inicial (pré-merge, #75)

- **Data:** 2026-11-13.
- **Objeto:** branch `feat/agenda-por-data-tela-inicial` — RF-010 agenda por
  data, com as visões de dia, semana e mês (`requisitos.md` 3.2), antes do
  merge. Com mudança de schema: criação da tabela `atendimentos` (RLS e
  publicação de realtime — SQL em `arquitetura.md` §4), aplicada pelo
  desenvolvedor no painel antes da rodada, mais um seed de oito atendimentos
  de exemplo inserido pelo SQL Editor (o app ainda não os cria; isso é o
  RF-005).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP. A verificação no celular da proprietária fica para a instalação
  do APK (issue #23).
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | O app abre na agenda, em "Hoje", com a data por extenso e só os atendimentos de hoje | CT-029 | Aprovado |
| 2 | Manhã antes da Tarde; na manhã, 08:00, 10:00 e depois os sem hora na ordem de registro | CT-030 | Aprovado |
| 3 | Cartão com hora ou "sem hora", local, resumo das peças e valor em reais | CT-030 | Aprovado |
| 4 | Cabeçalho de cada período com a quantidade (Manhã 4, Tarde 1) | CT-031 | Aprovado |
| 5 | Tocar em amanhã na faixa da semana troca o dia, sem campo de data | CT-032 | Aprovado |
| 6 | Dia vazio exibe "Nenhum atendimento neste dia." e nenhum período | CT-033 | Aprovado |
| 7 | Na faixa, só os dias com atendimento exibem a quantidade | CT-034 | Aprovado |
| 8 | Faixa de domingo a sábado; setas avançam e retrocedem a semana com as quantidades | CT-035 | Aprovado |
| 9 | Um toque abre o mês em calendário com a quantidade por dia; setas trocam o mês | CT-036 | Aprovado |
| 10 | Tocar num dia do mês seleciona, volta à visão do dia e mostra a semana dele | CT-037 | Aprovado |
| 11 | Hoje tem marca própria na semana e no mês; o atalho de voltar a hoje só aparece fora de hoje | CT-038 | Aprovado |
| 12 | Ícone de pessoas abre "MSClean - Clientes"; voltar retorna ao mesmo dia | CT-039 | Aprovado |
| 13 | Regressão: cadastrar, editar e excluir cliente pela lista | CT-004, CT-008, CT-021 | Aprovado |
| 14 | Atendimento inserido pelo painel com o app aberto aparece na agenda (realtime) | RF-010 | Aprovado |

### Veredicto

**#75 validado** em rodada única, suíte automatizada verde. A agenda passa a
ser a tela inicial: o dia agrupado por período, a semana sempre à vista e o mês
a um toque, com a lista de clientes acessível a partir dela. Decisões aceitas
na revisão: semana de domingo a sábado (a confirmar com a proprietária no uso
real), FK `cliente_id` com `on delete cascade`, tabela sem
feito/pago/observação (entram no RF-014 e no RF-005) e mês como alternância na
mesma tela.

## Execução 009 — Verificação manual do registro de atendimento (pós-merge, #77)

- **Data:** 2026-11-13.
- **Objeto:** PR #89 (issue #77) — RF-005 enxuto, registrar e editar atendimento
  a partir do dia da agenda (`requisitos.md` §2.2). Sem mudança de schema. A
  rodada foi feita antes do merge; o registro entra depois dele.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`) e celular físico
  (SM A505GT, Android 11, `fvm flutter run -d`), contra o Supabase real do MVP.
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Novo atendimento abre com a data do dia selecionado, sem campo de data | CT-040 | Aprovado |
| 2 | Salvar sem cliente e sem período não grava e aponta os dois campos | CT-041 | Aprovado |
| 3 | Cliente com endereço, período Tarde, peças (tapete com medidas e sofá) e valor `180,50`; o Local vem do endereço; o cartão aparece na Tarde do mesmo dia | CT-043, CT-044, CT-047, CT-048 | Aprovado |
| 4 | Tocar no cartão abre a edição; a hora alterada atualiza o mesmo atendimento, sem duplicar | CT-042 | Aprovado |
| 5 | "Anotar só o nome" cria o cliente provisório, o atendimento aparece na Manhã e a lista de clientes mostra o selo "provisório" | CT-045, CT-046 | Aprovado |

### Ocorrências
- A hora abreviada (`8`, `830`, `1430`) passou a ser completada para `HH:MM`
  durante a rodada, por sugestão do desenvolvedor, e o botão foi renomeado para
  "Salvar atendimento" para não ser confundido com a marca de serviço feito
  (RF-014); ambos já estavam no PR.
- No celular, a primeira abertura veio sem dados por falta de rede do aparelho
  (nenhuma rede ativa); o app mostrou "Nenhum cliente encontrado." porque a
  falha de conexão não é distinguida de lista vazia — bug já registrado (#47).
  Com a rede restabelecida, os dados apareceram.
- Achados fora de escopo, abertos como issues: #87 (a seleção acompanha o mesmo
  dia da semana ao trocar a semana pela seta) e #88 (abrir o Local no Google
  Maps a partir do cartão).

### Veredicto

**#77 validado** em rodada única, no Chrome e no celular, com a suíte
automatizada verde. A proprietária já consegue registrar e editar atendimentos
pelo próprio app.

## Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2026-07-17 | 1.0 | Wilson Gorosthides | Criação do registro de execuções de testes manuais, com as convenções de registro e a Execução 001 (RF-001, pré-merge do PR #44) — issue #49. |
| 2026-07-19 | 1.1 | Wilson Gorosthides | Execução 002 (RF-002, pré-merge do PR #55): duas rodadas, com o diagnóstico do CT-008 (realtime UPDATE não entregue, issue #57), a renegociação do critério (`requisitos.md` 2.4) e a aprovação final. |
| 2026-07-20 | 1.2 | Wilson Gorosthides | Execução 003 (RF-008, pré-merge do PR de exclusão): rodada única, quatro CTs aprovados, sem regressão; reflexo da exclusão imediato via renovação da stream (`requisitos.md` 2.5). MVP completo. |
| 2026-07-21 | 1.3 | Wilson Gorosthides | Execução 004 (endereço opcional, pré-merge #61): rodada única, CT-001/CT-025 aprovados, sem regressão. |
| 2026-07-21 | 1.4 | Wilson Gorosthides | Execução 005 (múltiplos telefones, pré-merge #62): rodada única com a migração do Supabase (`telefone`→`telefones` text[]); CT-006/CT-026 aprovados, sem regressão. |
| 2026-07-21 | 1.5 | Wilson Gorosthides | Execução 006 (endereço estruturado, pré-merge #65): rodada única com a migração do Supabase (`endereco` text → jsonb); CT-027/CT-011/CT-025/CT-006/CT-008/CT-014 aprovados, sem regressão. |
| 2026-07-21 | 1.6 | Wilson Gorosthides | Execução 007 (abrir no Google Maps, pré-merge #66): rodada única, sem migração; CT-028 aprovado, sem regressão em edição e exclusão. |
| 2026-11-13 | 1.7 | Wilson Gorosthides | Execução 008 (agenda como tela inicial, pré-merge #75): rodada única no Chrome, com a criação da tabela `atendimentos` no Supabase; CT-029 a CT-039 aprovados, sem regressão no cadastro de clientes. |
| 2026-11-13 | 1.8 | Wilson Gorosthides | Execução 009 (registro de atendimento, #77, PR #89): rodada única no Chrome e no celular; CT-040 a CT-048 aprovados, sem migração. Registra a falha de rede do celular na primeira abertura (bug #47) e os achados #87 e #88. |
| 2026-11-13 | 1.9 | Wilson Gorosthides | Nova seção "Pilha de verificação manual (pendente)" e convenção correspondente: os passos manuais de cada entrega acumulam ali e são executados de uma vez antes do APK (replanejamento do fluxo; `plano-de-testes.md` 1.8). |
