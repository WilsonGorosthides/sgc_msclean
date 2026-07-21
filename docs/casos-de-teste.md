# Casos de Teste — SGC para MSClean

> Formaliza cada critério de aceitação do MVP como um **caso de teste (CT)
> numerado**, com tipo de execução, pré-condições, passos e resultado esperado.
> Complementa `docs/matriz-rastreabilidade.md`: a matriz liga RF ↔ critério ↔ CT
> e diz **o que** está coberto; este documento detalha **como** cada CT é
> executado. Os tipos de execução e a prioridade de verificação manual no
> dispositivo físico da cliente seguem `docs/plano-de-testes.md` §2.
>
> **Situação** de cada CT: `implementado` (teste existe na suíte e passa) ou
> `a implementar` (descreve o comportamento esperado antes do código existir —
> roteiro para o desenvolvimento orientado a testes dos RFs pendentes).

## Convenções

- A numeração CT-001…CT-022 segue a ordem das linhas da matriz de
  rastreabilidade; CT-023 é o caso manual de RNF-001. CT-024, criado depois
  (issue #48), cobre o piso de dígitos do telefone (RF-001) e fica junto do
  CT-003 — o número fora de ordem preserva a numeração dos demais CTs.
- Critérios de aceitação são copiados literalmente da matriz.
- Nos CTs automatizados, os "passos" descrevem o que o teste executa; nos
  manuais, o que a pessoa executa.
- CTs automatizados rodam com `fvm flutter test`; os manuais seguem a ordem de
  preferência do `plano-de-testes.md` §2.1 (dispositivo físico da cliente;
  emulador Android/chrome como alternativa).

## RF-001 — Cadastro de Cliente

### CT-001 — Campos obrigatórios do cadastro
- **Critério:** "Nome e Telefone são campos obrigatórios. Endereço é opcional."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `client_form_screen_test: exige nome e telefone; endereço é
  opcional`
- **Pré-condições:** formulário de cadastro aberto.
- **Passos:**
  1. Acionar o salvar sem preencher nenhum campo.
- **Resultado esperado:** nenhum dado é enviado ao banco; Nome e Telefone são
  apontados como pendentes; Endereço **não** é apontado (issue #61).

### CT-002 — Bloqueio de salvamento com campo vazio ou só espaços
- **Critério:** "Ao tentar salvar com qualquer campo obrigatório vazio (ou só
  com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem
  indicando o(s) campo(s) pendente(s)."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `client_form_screen_test: bloqueia salvar com campo vazio ou só
  espaços`
- **Pré-condições:** formulário de cadastro aberto.
- **Passos:**
  1. Preencher Nome e Endereço válidos e deixar Telefone com `"   "` (só
     espaços).
  2. Acionar o salvar.
- **Resultado esperado:** salvamento bloqueado (nada enviado ao banco);
  mensagem de campo pendente exibida junto ao campo Telefone. O mesmo vale
  para qualquer combinação de campo vazio/só espaços.

### CT-003 — Validação do formato do telefone
- **Critério:** "O Telefone aceita apenas dígitos, espaços e os símbolos
  `+ ( ) -`; outros caracteres são rejeitados na validação."
- **Tipo:** Unitário (função de validação pura) + Widget · **Situação:** implementado
- **Testes:** `validadores: telefone aceita dígitos, espaços e + ( ) -`,
  `validadores: telefone rejeita caracteres inválidos` (unitários, função
  pura `Validadores.telefone`) e `client_form_screen_test: telefone rejeita
  caracteres inválidos` (widget)
- **Pré-condições:** função de validação disponível / formulário aberto.
- **Passos:**
  1. Validar entradas aceitas: `"11 91234-5678"`, `"+55 (11) 91234-5678"`.
  2. Validar entradas rejeitadas: `"11 91234-5678a"`, `"tel: 1234"`, `"12#34"`.
- **Resultado esperado:** as entradas do passo 1 passam; as do passo 2 são
  rejeitadas com mensagem de formato inválido, bloqueando o salvamento.

### CT-024 — Mínimo de 8 dígitos no telefone
- **Critério:** "O Telefone deve conter no mínimo **8 dígitos**; apenas
  dígitos contam na verificação (espaços e os símbolos `+ ( ) -` são
  ignorados na contagem)."
- **Tipo:** Unitário (função de validação pura) · **Situação:** implementado
- **Teste:** `validadores: telefone exige no mínimo 8 dígitos, contando só
  dígitos`
- **Pré-condições:** função de validação disponível.
- **Passos:**
  1. Validar entradas rejeitadas (menos de 8 dígitos): `"1234"`, `"192"`,
     `"(12) 3456-7"`.
  2. Validar entradas aceitas (8 dígitos ou mais): `"3456-7890"`,
     `"+55 (11) 91234-5678"`.
- **Resultado esperado:** as entradas do passo 1 são rejeitadas com a mensagem
  "Telefone deve ter pelo menos 8 dígitos"; as do passo 2 passam.
- **Nota:** a ligação do validador ao formulário (mensagem exibida e
  salvamento bloqueado) já é coberta pelo teste de widget do CT-003. Piso de
  8 decidido na issue #48: aceita fixo local digitado sem DDD; pode subir
  para 10 se a importação da agenda real (#23) mostrar que todos os contatos
  têm DDD.

### CT-004 — Cliente salvo aparece na lista em tempo real
- **Critério:** "Após salvar com sucesso, o novo cliente aparece na lista sem
  necessidade de recarregar a tela (atualização em tempo real via stream)."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: cliente salvo aparece na lista via stream`
- **Pré-condições:** lista aberta com a stream ativa; formulário acessível
  pelo botão de adicionar.
- **Passos:**
  1. Abrir o formulário pelo botão de adicionar.
  2. Preencher os três campos com dados válidos e salvar.
  3. Simular a emissão da stream contendo o cliente novo (no teste de widget)
     ou aguardar a emissão real (verificação manual).
- **Resultado esperado:** o método de gravação do service é chamado com os
  dados preenchidos e o cliente novo aparece na lista sem ação manual de
  atualização.
- **Nota:** o `SupabaseService.addClient` em si **não tem teste unitário**,
  por decisão registrada: é um repasse de uma linha pro Supabase, e mockar a
  cadeia `Future` do builder provaria quase nada. O insert real contra banco
  é responsabilidade do E2E da Fase 2 (`plano-de-testes.md` §2.3). Neste CT,
  o service é mockado e verifica-se a chamada com os dados corretos.

### CT-005 — Formulário fecha após salvar
- **Critério:** "Após salvar, o formulário é fechado e o usuário retorna à
  lista."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `client_form_screen_test: salvar fecha o formulário`
- **Pré-condições:** formulário de cadastro aberto com dados válidos.
- **Passos:**
  1. Acionar o salvar com os três campos válidos.
- **Resultado esperado:** o formulário é fechado e a tela da lista volta a ser
  exibida.
- **Nota:** cobertura extra além dos critérios formais (robustez decidida no
  desenho do RF-001): se o insert **falha** (ex.: sem internet), o app exibe
  SnackBar "Erro ao salvar. Tente novamente." e o formulário permanece aberto
  com os dados digitados — teste `client_form_screen_test: falha ao salvar
  exibe erro e mantém o formulário aberto`.

### CT-025 — Aviso ao salvar sem endereço
- **Critério:** "Ao salvar sem endereço, o sistema pede confirmação; ao
  confirmar, grava; ao cancelar, permanece no formulário."
- **Tipo:** Widget · **Situação:** implementado
- **Testes:** `client_form_screen_test: salvar sem endereço pede confirmação e
  grava ao confirmar` e `client_form_screen_test: cancelar o aviso de sem
  endereço não grava`
- **Pré-condições:** formulário aberto com Nome e Telefone válidos e Endereço
  vazio.
- **Passos:**
  1. Acionar o salvar.
  2. No diálogo, confirmar ("Salvar mesmo assim") ou cancelar.
- **Resultado esperado:** o diálogo "Cliente sem endereço. Deseja salvar mesmo
  assim?" aparece; ao confirmar, o service é chamado (endereço vazio); ao
  cancelar, nada é gravado e o formulário permanece aberto (issue #61).
- **Nota:** o número fora de ordem (após CT-024) segue a convenção de append —
  CT-025 nasce depois, junto do RF-001 a que pertence.

### CT-026 — Múltiplos telefones por cliente
- **Critério:** "O cliente pode ter um ou mais telefones; o formulário permite
  adicionar e remover campos (mínimo um), e cada número é validado
  individualmente."
- **Tipo:** Widget · **Situação:** implementado
- **Testes:** `client_form_screen_test: adiciona e remove campo de telefone`,
  `client_form_screen_test: salva com dois telefones` e
  `client_form_screen_test: segundo telefone inválido bloqueia o salvamento`
- **Pré-condições:** formulário aberto.
- **Passos:**
  1. Adicionar um segundo campo de telefone e depois removê-lo.
  2. Preencher dois telefones válidos e salvar.
  3. Preencher um telefone válido e um inválido e salvar.
- **Resultado esperado:** os campos adicionam/removem (mínimo um mantido); ao
  salvar, o service recebe a lista com todos os números preenchidos; um número
  inválido bloqueia o salvamento (issue #62).
- **Nota:** número fora de ordem (após CT-025) segue a convenção de append.

## RF-002 — Edição de Cliente

### CT-006 — Formulário de edição pré-preenchido
- **Critério:** "O formulário de edição abre pré-preenchido com os dados
  atuais do cliente."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: editar abre formulário pré-preenchido`
- **Pré-condições:** cliente existente na lista.
- **Passos:**
  1. Abrir a edição de um cliente da lista (toque no item).
- **Resultado esperado:** os campos Nome, Endereço e Telefone exibem os
  valores atuais do cliente.

### CT-007 — Edição aplica as validações do cadastro
- **Critério:** "As mesmas validações do cadastro (RF-001) se aplicam: campos
  obrigatórios e formato de telefone."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `client_form_screen_test: edição aplica as validações do
  cadastro`
- **Pré-condições:** formulário de edição aberto e pré-preenchido.
- **Passos:**
  1. Apagar o Nome (deixar vazio) e acionar o salvar.
  2. Restaurar o Nome, inserir caractere inválido no Telefone e acionar o
     salvar.
- **Resultado esperado:** ambos os salvamentos são bloqueados com as mesmas
  mensagens de validação do cadastro (CT-001 a CT-003).

### CT-008 — Edição persiste só após confirmar
- **Critério:** "Uma edição só é considerada salva após o usuário confirmar;
  nesse momento os dados são persistidos no banco e refletidos na lista
  imediatamente ao retornar do formulário."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: edição confirmada persiste e reflete na
  lista ao voltar`
- **Pré-condições:** formulário de edição aberto e pré-preenchido.
- **Passos:**
  1. Alterar o Endereço.
  2. Confirmar o salvamento.
- **Resultado esperado:** o método de atualização do service é chamado com os
  novos dados apenas na confirmação, e a lista exibe a alteração ao retornar
  do formulário (a Home renova a stream no retorno).
- **Nota:** o critério original pedia reflexo "em tempo real" (via evento da
  stream); foi renegociado em `requisitos.md` 2.4 porque os eventos UPDATE do
  realtime não são entregues pelo projeto Supabase atual — diagnóstico e
  caminho de restauração na issue #57.
- **Nota:** o `SupabaseService.updateClient` em si **não tem teste unitário**,
  pela mesma decisão registrada no CT-004 para o `addClient`: repasse de uma
  linha pro Supabase; o update real contra banco é responsabilidade do E2E
  da Fase 2 (`plano-de-testes.md` §2.3). Neste CT, o service é mockado e
  verifica-se a chamada com os dados corretos (incluindo o `id`).

### CT-009 — Cancelar edição não grava nada
- **Critério:** "Ao cancelar, nenhuma alteração é gravada e os dados originais
  do cliente permanecem intactos."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `client_form_screen_test: cancelar edição não grava nada`
- **Pré-condições:** formulário de edição aberto, com alterações digitadas e
  não confirmadas.
- **Passos:**
  1. Alterar qualquer campo.
  2. Cancelar (fechar sem confirmar).
- **Resultado esperado:** nenhuma chamada de gravação ao service; o cliente
  permanece na lista com os dados originais.

## RF-003 — Visualização da Lista

### CT-010 — Lista em ordem alfabética crescente
- **Critério:** "A lista é ordenada por Nome em ordem alfabética crescente
  (ordenação padrão)."
- **Tipo:** Widget + Unitário · **Situação:** implementado
- **Testes:** `home_screen_test: lista populada em ordem alfabética`
  (renderização) e `supabase_service_test: ordena por nome em ordem alfabética
  crescente` (ordenação pedida ao Supabase).
- **Pré-condições:** stream mockada com três clientes.
- **Passos:**
  1. Renderizar a lista com Ana, Bruno e Carla e comparar as posições
     verticais dos itens.
  2. Verificar por interação que o service chama `.order('nome',
     ascending: true)`.
- **Resultado esperado:** itens exibidos de A a Z; ordenação crescente
  explícita na chamada ao Supabase.
- **Nota:** o teste unitário nasceu de bug real — issue #39: o padrão do
  `.order()` da stream do supabase 2.10.2 é decrescente, e a lista chegava
  Z→A. Exemplo de CT criado a partir de defeito encontrado.

### CT-011 — Item exibe nome e endereço
- **Critério:** "Cada item exibe, no mínimo, Nome e Endereço."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: item exibe nome e endereço`.
- **Pré-condições:** stream mockada com um cliente.
- **Passos:**
  1. Renderizar a lista com um cliente.
- **Resultado esperado:** o nome e o endereço do cliente aparecem no item.

### CT-012 — Lista reage à stream em tempo real
- **Critério:** "A lista reflete inserções, edições e exclusões em tempo real
  (stream), sem ação manual de atualização."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: lista reage à emissão da stream`.
- **Pré-condições:** stream controlada pelo teste (StreamController).
- **Passos:**
  1. Emitir lista com um cliente; verificar exibição.
  2. Emitir lista com um cliente a mais (inserção); verificar que aparece.
  3. Emitir lista sem o primeiro cliente (exclusão); verificar que some.
- **Resultado esperado:** cada emissão atualiza a lista exibida, sem qualquer
  ação de recarga.

### CT-013 — Estado vazio exibe mensagem
- **Critério:** "Quando não há nenhum cliente cadastrado, a tela exibe a
  mensagem \"Nenhum cliente encontrado.\" em vez de uma lista vazia
  silenciosa."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: estado vazio exibe mensagem`.
- **Pré-condições:** stream mockada emitindo lista vazia.
- **Passos:**
  1. Renderizar a tela com a stream emitindo `[]`.
- **Resultado esperado:** a mensagem "Nenhum cliente encontrado." é exibida.

## RF-004 — Busca

### CT-014 — Filtro por nome ou endereço
- **Critério:** "A busca filtra por **Nome** ou **Endereço** (correspondência
  de substring)."
- **Tipo:** Unitário · **Situação:** implementado
- **Teste:** `supabase_service_test: filtro por nome ou endereço`.
- **Pré-condições:** função pura `filtrarClientes` com três linhas de dados.
- **Passos:**
  1. Filtrar por substring presente só em um nome.
  2. Filtrar por substring presente em dois endereços.
  3. Filtrar por termo sem correspondência.
- **Resultado esperado:** cada filtro retorna exatamente os clientes cujo nome
  **ou** endereço contém o termo; sem correspondência retorna lista vazia.

### CT-015 — Filtro case-insensitive
- **Critério:** "A busca é **case-insensitive** (não diferencia maiúsculas de
  minúsculas)."
- **Tipo:** Unitário · **Situação:** implementado
- **Teste:** `supabase_service_test: filtro case-insensitive`.
- **Pré-condições:** função pura `filtrarClientes` com três linhas de dados.
- **Passos:**
  1. Filtrar o mesmo termo em MAIÚSCULAS, minúsculas e MiStUrAdO.
- **Resultado esperado:** as três variações retornam o mesmo resultado.

### CT-016 — Filtragem em tempo real ao digitar
- **Critério:** "A lista é filtrada em tempo real conforme o usuário digita,
  sem necessidade de botão \"buscar\"."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: filtragem ao digitar na busca`.
- **Pré-condições:** lista renderizada com dois clientes; streams mockadas por
  termo de busca.
- **Passos:**
  1. Digitar termo que corresponde a um só cliente.
  2. Limpar o campo de busca.
- **Resultado esperado:** ao digitar, só o correspondente permanece (sem botão
  de buscar); ao limpar, a lista completa volta.

### CT-017 — Busca sem correspondência exibe mensagem
- **Critério:** "Quando nenhum cliente corresponde ao termo, a tela exibe a
  mensagem \"Nenhum cliente encontrado.\"."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: busca sem correspondência exibe mensagem`.
- **Pré-condições:** lista renderizada com clientes; stream do termo sem
  correspondência mockada vazia.
- **Passos:**
  1. Digitar termo que não corresponde a nenhum cliente.
- **Resultado esperado:** a mensagem "Nenhum cliente encontrado." é exibida.

### CT-018 — Busca vazia exibe todos
- **Critério:** "Com o campo de busca vazio, todos os clientes são exibidos."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: busca vazia exibe todos`.
- **Pré-condições:** stream mockada com três clientes; campo de busca vazio.
- **Passos:**
  1. Renderizar a tela sem digitar nada na busca.
- **Resultado esperado:** os três clientes aparecem na lista.

## RF-008 — Exclusão de Cliente

### CT-019 — Exclusão exige confirmação
- **Critério:** "A exclusão exige confirmação explícita do usuário (diálogo
  \"Confirmar exclusão?\") antes de efetivar."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: exclusão pede confirmação antes de remover`
- **Pré-condições:** cliente existente na lista.
- **Passos:**
  1. Acionar a exclusão de um cliente (lixeira no item).
- **Resultado esperado:** um diálogo de confirmação é exibido; nada é removido
  antes da resposta.

### CT-020 — Cancelar confirmação não remove
- **Critério:** "Ao cancelar a confirmação, o cliente **não** é removido e
  permanece na lista."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: cancelar a confirmação não remove`
- **Pré-condições:** diálogo de confirmação de exclusão aberto.
- **Passos:**
  1. Cancelar o diálogo.
- **Resultado esperado:** nenhuma chamada de exclusão ao service; o cliente
  permanece na lista.

### CT-021 — Confirmar remove e reflete na lista
- **Critério:** "Ao confirmar, o cliente é removido do banco e desaparece da
  lista imediatamente após a confirmação."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: confirmar remove e a lista reflete ao renovar
  a stream`
- **Pré-condições:** diálogo de confirmação de exclusão aberto.
- **Passos:**
  1. Confirmar o diálogo.
  2. A Home renova a stream após a exclusão.
- **Resultado esperado:** o método de exclusão do service é chamado com o
  cliente correto; o item desaparece da lista sem ação manual.
- **Nota:** o critério original pedia reflexo "em tempo real"; foi renegociado
  em `requisitos.md` 2.5 para reflexo logo após a confirmação. Por consistência
  com o RF-002 e por robustez, a Home renova a stream após a exclusão,
  independentemente de o evento DELETE nativo do realtime ser entregue — sem
  presumir que ele falhe (ao contrário do UPDATE, o DELETE não foi diagnosticado
  como quebrado; ver contexto na issue #57). O `SupabaseService.deleteClient`
  **não tem teste unitário**, pela mesma decisão do `addClient`/`updateClient`
  (repasse de uma linha, coberto pelo E2E da Fase 2).

### CT-022 — Feedback visual após excluir
- **Critério:** "Após a exclusão bem-sucedida, o sistema dá feedback visual
  (ex.: SnackBar \"Cliente excluído\")."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: exclusão bem-sucedida exibe feedback`
- **Pré-condições:** exclusão confirmada com sucesso.
- **Passos:**
  1. Confirmar a exclusão de um cliente.
- **Resultado esperado:** feedback visual exibido (ex.: SnackBar "Cliente
  excluído").

## RNF-001 — Verificação manual de usabilidade

### CT-023 — Fluxo geral no dispositivo da cliente
- **Requisito:** RNF-001 — "Todas as ações principais (cadastrar, buscar,
  editar, excluir) devem ser alcançáveis em no máximo 2 toques a partir da
  tela inicial, sem necessidade de treinamento prévio."
- **Tipo:** Manual (dispositivo físico da cliente; emulador/chrome como
  alternativa — `plano-de-testes.md` §2.1) · **Situação:** a implementar
  (depende de RF-001, RF-002 e RF-008)
- **Pré-condições:** app instalado no dispositivo da cliente; base com alguns
  clientes reais; nenhuma instrução prévia dada à cliente.
- **Passos:**
  1. Pedir à cliente que cadastre um cliente novo.
  2. Pedir que encontre um cliente específico pela busca.
  3. Pedir que corrija o endereço de um cliente.
  4. Pedir que exclua um cliente que não atende mais.
- **Resultado esperado:** cada ação é iniciada em no máximo 2 toques a partir
  da tela inicial e concluída pela cliente sem ajuda; nenhuma etapa exige
  explicação do desenvolvedor.

## Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2026-07-15 | 1.0 | Wilson Gorosthides | Criação dos casos de teste formais do MVP: CT-001 a CT-022 cobrindo todos os critérios de aceitação da matriz de rastreabilidade (RF-001/002/003/004/008) e CT-023 manual de RNF-001 no dispositivo da cliente. |
| 2026-07-15 | 1.1 | Wilson Gorosthides | CT-001 a CT-005 confirmados como implementados (RF-001, issue #25), com os nomes reais dos testes; nota no CT-004 sobre a ausência deliberada de teste unitário do `addClient` (coberto pelo E2E da Fase 2) e nota no CT-005 sobre a cobertura extra do SnackBar de erro no insert. |
| 2026-07-18 | 1.2 | Wilson Gorosthides | Adiciona CT-024 — mínimo de 8 dígitos no telefone (novo critério do RF-001, issue #48), posicionado junto ao CT-003; convenção de numeração atualizada para explicar o número fora de ordem. |
| 2026-07-18 | 1.3 | Wilson Gorosthides | CT-006 a CT-009 confirmados como implementados (RF-002, issue #26), com os nomes reais dos testes; nota no CT-008 sobre a ausência deliberada de teste unitário do `updateClient` (mesma decisão do `addClient`, coberto pelo E2E da Fase 2). |
| 2026-07-19 | 1.4 | Wilson Gorosthides | CT-008 alinhado ao critério renegociado do RF-002 (`requisitos.md` 2.4): reflexo da edição ao retornar do formulário em vez de "em tempo real"; nome do teste e nota sobre a issue #57 (eventos UPDATE do realtime não entregues). |
| 2026-07-20 | 1.5 | Wilson Gorosthides | CT-019 a CT-022 confirmados como implementados (RF-008, issue #27), com os nomes reais dos testes; CT-021 alinhado ao critério renegociado (`requisitos.md` 2.5, reflexo após a confirmação) e nota sobre a ausência deliberada de teste unitário do `deleteClient`. |
| 2026-07-21 | 1.6 | Wilson Gorosthides | Endereço opcional (RF-001, `requisitos.md` 2.6, issue #61): CT-001 deixa de exigir endereço; novo CT-025 (aviso de confirmação ao salvar sem endereço). |
| 2026-07-21 | 1.7 | Wilson Gorosthides | Múltiplos telefones (RF-001, `requisitos.md` 2.7, issue #62): novo CT-026 (adicionar/remover campos, salvar com dois números, validação por telefone). |
