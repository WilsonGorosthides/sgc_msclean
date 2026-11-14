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
- CT-029 em diante cobrem a agenda (`requisitos.md` §2.2). Os CTs de cada RF da
  agenda são escritos no PR que entrega o RF, como primeiro commit; os do RF-010
  vieram antes, junto do requisito de semana e mês (`requisitos.md` 3.2). Os do
  RF-005 (CT-040 a CT-048) ficam antes dos do RF-010 no documento, na ordem dos
  RFs, embora numerados depois.
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

### CT-027 — Endereço estruturado
- **Critério:** "O Endereço é estruturado em campos (logradouro, número, bairro,
  complemento, ponto de referência), todos opcionais."
- **Tipo:** Unitário + Widget · **Situação:** implementado
- **Testes:** o grupo `endereco_test:` (ida e volta jsonb, `vazio`, `resumo`,
  `buscavel`, `consultaMaps`); `client_form_screen_test: salvar fecha o
  formulário` (os campos estruturados chegam ao service como `Endereco`);
  `home_screen_test: item exibe nome e endereço` (resumo na lista).
- **Pré-condições:** value object `Endereco` disponível / formulário aberto.
- **Passos:**
  1. Serializar e reconstruir um `Endereco` completo (toMap/fromMap) e conferir
     os getters derivados (`vazio`, `resumo`, `buscavel`, `consultaMaps`).
  2. Preencher os campos estruturados no formulário e salvar.
- **Resultado esperado:** o `Endereco` é persistido como jsonb (round-trip
  preserva os campos); `resumo` monta a linha da lista; `buscavel` alimenta a
  busca; `consultaMaps` usa só os campos de chegar (sem complemento/referência).
- **Nota:** número fora de ordem (após CT-026) segue a convenção de append.
  A abertura no Google Maps a partir de `consultaMaps` é coberta à parte pelo
  RF-009 (issue #66).

## RF-002 — Edição de Cliente

### CT-006 — Formulário de edição pré-preenchido
- **Critério:** "O formulário de edição abre pré-preenchido com os dados
  atuais do cliente."
- **Tipo:** Widget · **Situação:** implementado
- **Teste:** `home_screen_test: editar abre formulário pré-preenchido`
- **Pré-condições:** cliente existente na lista.
- **Passos:**
  1. Abrir a edição de um cliente da lista (toque no item).
- **Resultado esperado:** os campos Nome, Telefone e os campos estruturados do
  Endereço (logradouro, número etc.) exibem os valores atuais do cliente.

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
- **Critério:** "Cada item exibe, no mínimo, Nome e um resumo do endereço; quando
  o cliente não tem endereço, um texto discreto \"Sem endereço\" ocupa o lugar."
- **Tipo:** Widget · **Situação:** implementado
- **Testes:** `home_screen_test: item exibe nome e endereço` e
  `home_screen_test: item sem endereço exibe placeholder`.
- **Pré-condições:** stream mockada com um cliente.
- **Passos:**
  1. Renderizar a lista com um cliente com endereço e conferir o resumo.
  2. Renderizar com um cliente sem endereço e conferir o placeholder.
- **Resultado esperado:** o nome e o resumo do endereço (logradouro, número —
  bairro) aparecem no item; sem endereço, aparece "Sem endereço".

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
- **Critério:** "A busca filtra por **Nome** ou por **qualquer campo do
  Endereço** (correspondência de substring)."
- **Tipo:** Unitário · **Situação:** implementado
- **Teste:** `supabase_service_test: filtro por nome ou endereço`.
- **Pré-condições:** função pura `filtrarClientes` com três linhas de dados.
- **Passos:**
  1. Filtrar por substring presente só em um nome.
  2. Filtrar por substring presente no logradouro de dois clientes.
  3. Filtrar por substring presente no bairro de um cliente.
  4. Filtrar por termo sem correspondência.
- **Resultado esperado:** cada filtro retorna exatamente os clientes cujo nome
  **ou** qualquer campo do endereço (via `Endereco.buscavel`) contém o termo;
  sem correspondência retorna lista vazia.

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

## RF-009 — Abrir Endereço no Mapa

### CT-028 — Abrir endereço no Google Maps
- **Critério:** "A partir de um cliente com endereço, uma ação abre o endereço no
  Google Maps; quando o cliente não tem endereço, a ação não é exibida."
- **Tipo:** Unitário + Widget · **Situação:** implementado
- **Testes:** `maps_launcher_test: urlMaps monta a busca do Google Maps a partir
  do endereço` e `maps_launcher_test: urlMaps de endereço vazio é nula` (função
  pura); `home_screen_test: item com endereço mostra o botão de abrir no mapa e
  dispara` e `home_screen_test: item sem endereço não mostra o botão de abrir no
  mapa` (widget).
- **Pré-condições:** value object `Endereco` disponível / lista renderizada.
- **Passos:**
  1. Montar a URL do Maps a partir de um endereço preenchido e de um vazio.
  2. Renderizar a lista com um cliente com endereço e tocar no ícone de mapa.
  3. Renderizar com um cliente sem endereço.
- **Resultado esperado:** a URL usa os campos de chegar + a âncora Campo Grande -
  MS (nula quando não há o que abrir); o ícone de mapa aparece e dispara a
  abertura só quando o cliente tem endereço.
- **Nota:** o disparo real via `url_launcher` é injetável na `HomeScreen`
  (parâmetro `abrirMaps`); o teste de widget verifica a chamada sem mockar o
  canal nativo do plugin. Número fora de ordem (após CT-027) segue a convenção
  de append.

## RF-005 — Registrar Atendimento

> Primeira entrega **enxuta** (issue #77): o valor é digitado. O cálculo pela
> tabela de preços (RF-013) e o pré-preenchimento pelo atendimento anterior
> (RNF-006) ganham CTs nas suas entregas. Como na agenda, o "hoje" é injetado.

### CT-040 — Registro parte do dia selecionado
- **Critério:** "O registro parte de um dia da agenda: a Data já vem preenchida
  com o dia selecionado."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: novo atendimento parte do dia selecionado e, salvo, consta no período` · `atendimento_form_screen_test: exige cliente e período; hora é opcional`
- **Pré-condições:** agenda aberta com um dia selecionado diferente de hoje.
- **Passos:**
  1. Acionar "Novo atendimento" na agenda.
  2. Escolher cliente e período e salvar.
- **Resultado esperado:** o formulário exibe a data do dia selecionado, sem
  campo para digitá-la; o atendimento salvo tem essa data.

### CT-041 — Cliente e Período obrigatórios; Hora opcional
- **Critério:** "**Cliente e Período são obrigatórios.** **Hora é opcional**."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: exige cliente e período; hora é opcional` · `atendimento_form_screen_test: hora inválida bloqueia; hora válida é gravada` · `validadores: hora é opcional e, quando informada, segue HH:MM`
- **Pré-condições:** formulário aberto.
- **Passos:**
  1. Salvar sem cliente e sem período.
  2. Escolher cliente e período, deixar a hora vazia e salvar.
- **Resultado esperado:** no passo 1 nada é gravado e o formulário aponta os
  dois campos; no passo 2 o atendimento é gravado com hora nula.

### CT-042 — Hora alterável depois sem refazer o atendimento
- **Critério:** "Quando informada, a Hora pode ser alterada depois sem refazer o
  atendimento."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: tocar no cartão abre a edição e a hora alterada é atualizada` · `atendimento_form_screen_test: edição abre preenchida e salva pelo update`
- **Pré-condições:** um atendimento do dia, com hora.
- **Passos:**
  1. Tocar no cartão do atendimento na agenda.
  2. Trocar a hora e salvar.
- **Resultado esperado:** o formulário abre preenchido com os dados do
  atendimento; ao salvar, o mesmo atendimento (mesmo id) é atualizado com a
  nova hora, sem criar outro.

### CT-043 — Peças do serviço como lista
- **Critério:** "As **Peças do serviço** são uma lista: cada peça tem **tipo**
  (tapete, sofá, poltrona, cortina, colchão, outro), **quantidade** e, quando o
  tipo é medido por metragem, **largura e comprimento**. Uma peça sem medida é
  registrada apenas por quantidade."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `peca_test: toMap de peça medida leva as medidas; contada só a quantidade` · `peca_test: tapete é o tipo medido por metragem; os demais são contados` · `atendimento_test: toMap grava a linha do banco, sem id e sem criado_em` · `atendimento_form_screen_test: peças: tipo medido mostra as medidas; a lista é gravada` · `atendimento_form_screen_test: remover peça tira a linha`
- **Pré-condições:** formulário aberto com cliente e período escolhidos.
- **Passos:**
  1. Serializar uma peça medida e uma contada (função pura).
  2. Adicionar uma peça "tapete" com largura e comprimento e uma "sofá" com
     quantidade 2; salvar.
- **Resultado esperado:** só os tipos medidos exibem os campos de medida; o
  atendimento salvo traz as duas peças, a medida com largura e comprimento, a
  contada só com a quantidade.

### CT-044 — Valor informado pela proprietária
- **Critério:** "O **Valor** [...] **pode ser sobrescrito** pela proprietária
  antes de salvar." (nesta entrega, o valor é só digitado; o cálculo é o RF-013)
- **Tipo:** Unitário + Widget · **Situação:** implementado — `agenda_test: lerValor aceita virgula ou ponto e devolve nulo para vazio` · `atendimento_form_screen_test: valor digitado com vírgula; campo vazio grava sem valor`
- **Pré-condições:** formulário aberto com cliente e período escolhidos.
- **Passos:**
  1. Converter "180,50", "180" e "" (função pura).
  2. Digitar um valor com vírgula e salvar; depois salvar com o campo vazio.
- **Resultado esperado:** "180,50" vira 180.5 e vazio vira nulo; o atendimento
  salvo traz o valor digitado, ou nenhum valor quando o campo fica vazio.

### CT-045 — Cliente novo entra só com o nome (provisório)
- **Critério:** "O Cliente pode ser escolhido entre os cadastrados **ou**
  informado por um nome ainda não cadastrado. Neste segundo caso o sistema cria
  um **cliente provisório** apenas com o nome."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: nome não cadastrado cria cliente provisório só com o nome` · `atendimento_form_screen_test: busca filtra os clientes pelo nome`
- **Pré-condições:** formulário aberto; o nome digitado não existe na lista.
- **Passos:**
  1. Digitar um nome na busca de cliente.
  2. Acionar "Anotar só o nome".
  3. Escolher o período e salvar.
- **Resultado esperado:** um cliente é criado só com o nome (sem telefone e sem
  endereço) e o atendimento salvo aponta para ele.

### CT-046 — Cliente provisório sinalizado na lista
- **Critério:** "O cliente provisório é sinalizado na lista de clientes até ser
  completado."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `client_model_test: provisório é o cliente sem telefone (RF-005)` · `home_screen_test: cliente provisório exibe o selo na lista`
- **Pré-condições:** lista com um cliente sem telefone e um completo.
- **Passos:**
  1. Consultar a regra de provisório (função pura).
  2. Renderizar a lista de clientes.
- **Resultado esperado:** cliente sem telefone é provisório; só ele exibe o selo
  "provisório" na lista. Ao editá-lo, o telefone continua obrigatório (RF-001),
  e é isso que o completa.

### CT-047 — Local pré-preenchido com o endereço, editável
- **Critério:** "Quando o Cliente tem endereço cadastrado, o Local vem
  pré-preenchido com o resumo do endereço (mesmo resumo do RF-003), e pode ser
  alterado."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: local vem do endereço do cliente e pode ser alterado` · `atendimento_form_screen_test: trocar o cliente volta à busca`
- **Pré-condições:** um cliente com endereço e um sem.
- **Passos:**
  1. Escolher o cliente com endereço; conferir o Local.
  2. Alterar o Local e salvar.
  3. Reabrir e escolher o cliente sem endereço.
- **Resultado esperado:** o Local vem com o resumo do endereço; o valor
  alterado é o que fica gravado; para o cliente sem endereço o Local vem vazio.

### CT-048 — Atendimento salvo consta no dia e no período
- **Critério:** "Ao salvar, o atendimento passa a constar no dia e no período
  correspondentes da agenda."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: novo atendimento parte do dia selecionado e, salvo, consta no período`
- **Pré-condições:** agenda aberta num dia vazio.
- **Passos:**
  1. Registrar um atendimento da tarde nesse dia e voltar à agenda.
- **Resultado esperado:** a agenda continua no mesmo dia e o cartão aparece na
  seção Tarde, sem recarregar o app.

## RF-010 — Agenda por Data

> Os testes automatizados da agenda recebem a data de "hoje" por injeção (relógio
> fixo), nunca de `DateTime.now()` direto — sem isso, o resultado dependeria do
> dia em que a suíte roda. Nos exemplos abaixo, "hoje" é uma quarta-feira.

### CT-029 — Agenda abre no dia de hoje
- **Critério:** "Ao abrir o aplicativo, o sistema exibe a agenda posicionada no
  **dia de hoje**."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: abre no dia de hoje e mostra só os atendimentos de hoje`
- **Pré-condições:** relógio fixo; atendimentos registrados em hoje e em outro
  dia.
- **Passos:**
  1. Abrir o aplicativo.
- **Resultado esperado:** a primeira tela é a agenda; o dia selecionado é hoje;
  só os atendimentos de hoje aparecem.

### CT-030 — Agrupamento por período e ordenação dentro do período
- **Critério:** "Os atendimentos do dia selecionado são agrupados por
  **período** (manhã, depois tarde) e, dentro do período, ordenados por hora
  quando houver — os sem hora aparecem depois dos com hora, na ordem em que
  foram registrados."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `agenda_test: manhã antes da tarde; com hora por hora; sem hora por registro` · `agenda_test: período sem atendimento não aparece nos grupos` · `agenda_screen_test: agrupa por período e ordena por hora, sem hora depois` · `agenda_screen_test: cartão exibe a hora, ou "sem hora", e o local`
- **Pré-condições:** um dia com, na manhã, um atendimento às 10:00, um às 08:00
  e dois sem hora (registrados em ordem conhecida); na tarde, um sem hora.
- **Passos:**
  1. Ordenar a lista do dia (função pura).
  2. Renderizar a agenda nesse dia.
- **Resultado esperado:** a seção Manhã vem antes da Tarde; na manhã, a ordem é
  08:00, 10:00 e depois os dois sem hora, na ordem de registro.

### CT-031 — Contagem de atendimentos por período
- **Critério:** "Cada período exibe **quantos atendimentos tem**, para que a
  carga do dia seja visível antes de aceitar mais um."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: cada período exibe quantos atendimentos tem`
- **Pré-condições:** um dia com três atendimentos na manhã e um na tarde.
- **Passos:**
  1. Renderizar a agenda nesse dia.
- **Resultado esperado:** o cabeçalho da Manhã exibe 3 e o da Tarde exibe 1.

### CT-032 — Navegar para outro dia sem digitar data
- **Critério:** "O usuário navega para outros dias sem precisar digitar uma
  data."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: navega para outro dia tocando na faixa da semana`
- **Pré-condições:** agenda aberta em hoje; atendimento registrado em amanhã.
- **Passos:**
  1. Tocar no dia de amanhã na faixa da semana.
- **Resultado esperado:** o dia selecionado passa a ser amanhã e o atendimento
  de amanhã é exibido; nenhum campo de texto de data é usado.

### CT-033 — Dia sem atendimentos exibe mensagem
- **Critério:** "Um dia sem atendimentos exibe a mensagem "Nenhum atendimento
  neste dia." em vez de uma lista vazia silenciosa (consistente com o RF-003)."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: dia sem atendimento exibe a mensagem`
- **Pré-condições:** nenhum atendimento no dia selecionado.
- **Passos:**
  1. Renderizar a agenda nesse dia.
- **Resultado esperado:** a mensagem "Nenhum atendimento neste dia." é exibida;
  nenhum cabeçalho de período aparece.

### CT-034 — Dias com atendimento são distinguíveis dos vazios
- **Critério:** "Na navegação entre dias, os dias que possuem ao menos um
  atendimento são visualmente distinguíveis dos vazios."
- **Tipo:** Widget · **Situação:** implementado — `agenda_test: conta atendimentos por dia` · `agenda_screen_test: dias com atendimento têm marca; os vazios não`
- **Pré-condições:** semana com atendimentos em alguns dias e nenhum em outros.
- **Passos:**
  1. Renderizar a faixa da semana.
- **Resultado esperado:** os dias com atendimento trazem a marca de ocupado; os
  vazios, não.

### CT-035 — Semana visível com a quantidade por dia e navegação por semana
- **Critério:** "A **semana** do dia selecionado fica visível junto ao dia: os
  sete dias (domingo a sábado), cada um com a **quantidade de atendimentos**. O
  usuário avança e retrocede de semana em semana."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `agenda_test: semana vai do domingo ao sábado que contêm o dia` · `agenda_test: domingo abre a semana e sábado a fecha` · `agenda_test: semana que atravessa a virada de mês` · `agenda_test: trocar de semana seleciona o domingo, ou hoje se estiver na semana` · `agenda_screen_test: faixa mostra domingo a sábado com a quantidade por dia` · `agenda_screen_test: avança e retrocede a semana`
- **Pré-condições:** hoje é quarta-feira; dois atendimentos na segunda da
  semana corrente e um na terça da semana seguinte.
- **Passos:**
  1. Calcular os sete dias da semana de uma data (função pura), incluindo uma
     semana que atravessa a virada de mês.
  2. Renderizar a agenda e conferir a faixa da semana.
  3. Avançar uma semana; depois retroceder duas.
- **Resultado esperado:** a faixa vai do domingo ao sábado que contêm o dia
  selecionado; a segunda exibe 2; ao avançar, a faixa mostra a semana seguinte
  e a terça exibe 1; ao retroceder, mostra a semana anterior à inicial. Ao
  trocar de semana, o dia selecionado passa a ser o domingo da semana de
  destino — ou hoje, quando a semana de destino é a corrente (issue #87).

### CT-036 — Mês em calendário com a quantidade por dia e navegação por mês
- **Critério:** "A partir da agenda, em **um toque**, o usuário abre o **mês**
  em formato de calendário: cada dia do mês exibe a quantidade de atendimentos.
  O usuário avança e retrocede de mês em mês."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `agenda_test: grade do mês alinha o dia 1 à coluna do dia da semana` · `agenda_test: grade de um mês que começa no domingo não tem vazios antes` · `agenda_test: somar meses cai no dia 1 do mês de destino` · `agenda_screen_test: abre o mês com um toque e navega entre meses`
- **Pré-condições:** agenda aberta; atendimentos em dias conhecidos do mês
  corrente e do mês seguinte.
- **Passos:**
  1. Contar atendimentos por dia de um mês (função pura).
  2. Na agenda, tocar uma vez na ação de abrir o mês.
  3. Avançar um mês; depois retroceder.
- **Resultado esperado:** o calendário do mês corrente abre com um único toque;
  cada dia com atendimento exibe a sua quantidade e os vazios não exibem
  número; avançar e retroceder trocam o mês exibido e as quantidades.

### CT-037 — Tocar em um dia da semana ou do mês seleciona e exibe
- **Critério:** "Tocar em um dia, na semana ou no mês, seleciona esse dia e
  exibe os seus atendimentos."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: tocar num dia do mês seleciona e volta à visão do dia`
- **Pré-condições:** atendimento registrado em um dia de outra semana do mês.
- **Passos:**
  1. Abrir o mês e tocar nesse dia.
- **Resultado esperado:** a agenda volta à visão do dia, com esse dia
  selecionado, a semana dele na faixa e o atendimento exibido. (O toque em um
  dia da faixa da semana é exercitado pelo CT-032.)

### CT-038 — Hoje identificável e atalho de retorno a hoje
- **Critério:** "O **dia de hoje** é identificável na semana e no mês, e um
  atalho volta a hoje a partir de qualquer data."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: hoje tem marca própria na semana e no mês` · `agenda_screen_test: atalho volta a hoje a partir de outro mês`
- **Pré-condições:** relógio fixo.
- **Passos:**
  1. Conferir a marca de hoje na faixa da semana e no calendário do mês.
  2. Navegar para um dia de outro mês.
  3. Acionar o atalho de voltar a hoje.
- **Resultado esperado:** hoje tem marca própria, distinta da marca de dia
  selecionado; depois do atalho, o dia selecionado é hoje. Com hoje já
  selecionado, o atalho não é exibido.

### CT-039 — Lista de clientes acessível a partir da agenda
- **Critério:** "A lista de clientes (RF-003) continua acessível, deixando de
  ser a tela inicial."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: lista de clientes abre pela agenda e volta ao mesmo dia`
- **Pré-condições:** agenda aberta.
- **Passos:**
  1. Tocar na ação de clientes da agenda.
- **Resultado esperado:** a lista de clientes (RF-003) é exibida em um toque, e
  voltar retorna à agenda no mesmo dia selecionado.

## RF-014 — Estados de Conclusão do Atendimento

### CT-049 — Dois marcadores independentes
- **Critério:** "Cada atendimento tem dois marcadores **independentes**:
  *serviço feito* e *cliente pagou*, cada um podendo ser ligado e desligado."
- **Tipo:** Unitário + Widget · **Situação:** a implementar
- **Pré-condições:** um atendimento sem marca e outro com as duas.
- **Passos:**
  1. Ler uma linha do banco com e sem as colunas `feito` e `pago` (função pura).
  2. Na agenda, marcar "Feito" no primeiro; desmarcar "Pago" no segundo.
- **Resultado esperado:** colunas ausentes valem falso; marcar "Feito" grava só
  o feito e não liga o pago; desmarcar "Pago" grava só o pago e mantém o feito.

### CT-050 — Concluído somente com os dois marcados
- **Critério:** "Um atendimento é considerado **concluído** somente quando **os
  dois** estão marcados."
- **Tipo:** Unitário + Widget · **Situação:** a implementar
- **Pré-condições:** atendimentos nas quatro combinações de feito e pago.
- **Passos:**
  1. Consultar `concluido` em cada combinação (função pura).
  2. Renderizar a agenda.
- **Resultado esperado:** só o atendimento com feito e pago é concluído e exibe
  a indicação "Concluído".

### CT-051 — Três situações distinguíveis na agenda
- **Critério:** "A agenda distingue visualmente três situações: nada marcado, um
  dos dois marcado, e concluído."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** um dia com um atendimento sem marca, um só com "Feito" e
  um concluído.
- **Passos:**
  1. Renderizar a agenda nesse dia.
- **Resultado esperado:** o primeiro mostra as duas marcas vazias; o segundo, só
  a marca "Feito" preenchida; o terceiro, as duas preenchidas e o cartão com a
  indicação de concluído.

### CT-052 — Marcar sem abrir o formulário
- **Critério:** "Marcar ou desmarcar não exige abrir o formulário de edição do
  atendimento."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** um atendimento no dia.
- **Passos:**
  1. Tocar na marca "Feito" do cartão.
  2. Repetir com a gravação falhando.
- **Resultado esperado:** a marca muda no próprio cartão, sem abrir o
  formulário; se a gravação falha, a marca volta ao estado anterior e um aviso é
  exibido.

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
| 2026-07-21 | 1.8 | Wilson Gorosthides | Endereço estruturado (RF-001/003/004, `requisitos.md` 2.8, issue #65): novo CT-027 (value object `Endereco`, jsonb, resumo, busca); CT-006 (campos estruturados no pré-preenchimento), CT-011 (resumo + placeholder) e CT-014 (busca por qualquer campo) ajustados. |
| 2026-07-21 | 1.9 | Wilson Gorosthides | Abrir no mapa (RF-009, `requisitos.md` 2.9, issue #66): novo CT-028 (montagem da URL do Google Maps e o botão de mapa que aparece/dispara só com endereço). |
| 2026-11-12 | 1.10 | Wilson Gorosthides | Primeiros casos da agenda: CT-029 a CT-039 para o RF-010 (`requisitos.md` 3.2) — abertura em hoje, agrupamento e ordenação por período, contagem por período, navegação entre dias, dia vazio, dias ocupados distinguíveis, semana com quantidade por dia, mês em calendário, seleção de dia pela semana ou pelo mês, hoje identificável com atalho, e acesso à lista de clientes. Todos "a implementar". Convenção nova: a data de hoje é injetada nos testes. |
| 2026-11-13 | 1.11 | Wilson Gorosthides | CT-029 a CT-039 passam a "implementado" com os testes reais da entrega do RF-010 (issue #75): `atendimento_test`, `agenda_test` (funções puras de semana, mês, contagem e ordem) e `agenda_screen_test` (catorze casos de widget com o relógio injetado). |
| 2026-11-13 | 1.12 | Wilson Gorosthides | Casos do RF-005 enxuto (issue #77): CT-040 a CT-048 — data do dia selecionado, cliente e período obrigatórios com hora opcional, hora alterável depois, peças como lista, valor digitado, cliente provisório só com o nome e o seu selo na lista, local pré-preenchido com o endereço, e o atendimento salvo constando no dia e no período. Todos "a implementar". |
| 2026-11-13 | 1.13 | Wilson Gorosthides | CT-040 a CT-048 passam a "implementado" com os testes da entrega do RF-005 enxuto (issue #77): `atendimento_form_screen_test` (onze casos), mais os novos casos em `agenda_screen_test`, `home_screen_test`, `atendimento_test`, `agenda_test`, `client_model_test` e `validators_test`. |
| 2026-11-13 | 1.14 | Wilson Gorosthides | CT-035 fixa qual dia fica selecionado ao trocar de semana: o domingo da semana de destino, ou hoje se ela for a corrente (bug #87); novo teste unitário associado. |
| 2026-11-13 | 1.15 | Wilson Gorosthides | Casos do RF-014 (issue #79): CT-049 a CT-052 — dois marcadores independentes, concluído só com os dois, três situações distinguíveis na agenda, e marcar sem abrir o formulário. Todos "a implementar". |
