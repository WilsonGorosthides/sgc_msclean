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
- CT-053 a CT-058 cobrem o RNF-007 (anotar sem internet, issue #94); ficam
  depois dos casos da agenda, antes do caso manual do RNF-001. CT-059 cobre o
  RNF-008 (identidade visual, issue #96) e vem logo depois deles.
- CT-060 a CT-066 cobrem o RF-015 (avisos no celular, issue #95) e ficam
  depois dos casos do RF-014, na ordem dos RFs da agenda.
- CT-076 a CT-079 cobrem o RF-011 (histórico do cliente, issue #81) e ficam
  entre os casos do RF-010 e os do RF-014, na ordem dos RFs da agenda.
- CT-080 a CT-086 cobrem a parte 1 do RF-013 (tabela de preços, issue #123) e
  ficam entre os casos do RF-011 e os do RF-014.
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


### CT-069 — Busca por relevância
- **Critério:** "Os resultados vêm por **relevância**: nome igual ao termo, depois nome que começa com o termo, depois nome com uma palavra que começa com o termo, depois o termo no meio do nome e, por fim, o termo só no endereço; dentro de cada faixa, ordem alfabética."
- **Tipo:** Unitário · **Situação:** implementado — `supabase_service_test: busca por relevância`
- **Pré-condições:** função pura `filtrarClientes` com clientes em ordem alfabética: "Bruno Neto", "Cris amiga do Neto", "Netinho", "Neto", "Neto Silva", "Sinetol" e um cliente com "Neto" só no endereço.
- **Passos:**
  1. Filtrar por "neto".
  2. Filtrar por "paulo" com "João Paulo" e "Paulo".
- **Resultado esperado:** "Neto"; "Neto Silva" (começa com); "Bruno Neto", "Cris amiga do Neto" (palavra começa com); "Sinetol" (no meio); o do endereço por último. "Netinho" não aparece. Em "paulo", "Paulo" vem antes de "João Paulo".

### CT-070 — Busca sem diferenciar acento
- **Critério:** "A busca **não diferencia acento**: \"joao\" acha \"João\"."
- **Tipo:** Unitário · **Situação:** implementado — `supabase_service_test: busca sem diferenciar acento`
- **Pré-condições:** função pura `filtrarClientes` com "João", "Conceição" e um endereço "Rua Pará".
- **Passos:**
  1. Filtrar por "joao", "conceicao" e "para".
  2. Filtrar por "JOÃO".
- **Resultado esperado:** cada termo acha o cliente acentuado, e o acento no termo também funciona.
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

## RF-016 — Trazer Cliente dos Contatos do Celular

> O seletor de contatos do Android é trocado nos testes por um falso
> (`AgendaDoCelular`), que devolve um contato pronto ou nada (ela desistiu).

### CT-072 — Contato escolhido preenche o cadastro
- **Critério:** "No **cadastro de cliente** (novo) e na escolha de cliente do **atendimento**, um botão **"Dos contatos"** abre o seletor de contatos do próprio Android; o app recebe **só o contato escolhido** (nome e o número tocado), sem pedir acesso à agenda inteira. No cadastro, o contato escolhido **preenche o nome e o telefone**; ela confere e salva como sempre."
- **Tipo:** Widget · **Situação:** implementado — `client_form_screen_test: contatos: contato escolhido preenche nome e telefone` · `client_form_screen_test: contatos: sem contato escolhido nada muda; na edição não há o botão` · `plataforma_test: o app não pede permissão de ler os contatos`
- **Pré-condições:** formulário de cliente novo; o falso devolve "Dona Ivete" com "(67) 99301-8496".
- **Passos:**
  1. Tocar em "Dos contatos".
  2. Repetir com o falso devolvendo nada.
  3. Abrir a edição de um cliente existente.
- **Resultado esperado:** nome "Dona Ivete" e telefone "+55 67 99301-8496" preenchidos; sem contato, nada muda; na edição, o botão não aparece.

### CT-073 — Contato já cadastrado avisa em vez de duplicar
- **Critério:** "Se o telefone do contato **já é de um cliente**, o app avisa **"Já cadastrado como <nome>"** e oferece abrir o cadastro existente, em vez de duplicar; ela ainda pode cadastrar mesmo assim."
- **Tipo:** Widget · **Situação:** implementado — `client_form_screen_test: contatos: contato já cadastrado avisa e abre o cadastro existente` · `client_form_screen_test: contatos: contato já cadastrado pode ser cadastrado mesmo assim`
- **Pré-condições:** a lista de clientes tem "Ivete Souza" com "67 99301-8496"; o falso devolve um contato com "+55 67 99301-8496".
- **Passos:**
  1. Tocar em "Dos contatos".
  2. Escolher "Abrir cadastro".
  3. Repetir e escolher "Cadastrar mesmo assim".
- **Resultado esperado:** aparece "Já cadastrado como Ivete Souza"; "Abrir cadastro" troca para a edição de Ivete Souza; "Cadastrar mesmo assim" preenche o formulário novo.

### CT-074 — Contato no atendimento: cliente existente ou novo com telefone
- **Critério:** "No atendimento, um contato que **já é cliente** seleciona esse cliente; um contato **novo** vira cliente **com o telefone** (não provisório) ao salvar o atendimento, inclusive sem internet (fila do aparelho, RNF-007)."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: contato que já é cliente seleciona o cliente` · `atendimento_form_screen_test: contato novo vira cliente com telefone ao salvar`
- **Pré-condições:** formulário de atendimento novo com os clientes Ana Souza ("11 91111-1111") e Bruno Lima.
- **Passos:**
  1. "Dos contatos" devolve um contato com "+55 11 91111-1111".
  2. Trocar o cliente; "Dos contatos" devolve "Dona Ivete" com "67993018496"; escolher período e salvar.
- **Resultado esperado:** no passo 1, Ana Souza fica escolhida; no passo 2, o cartão mostra "Dona Ivete" e salvar cria o cliente com o telefone "+55 67 99301-8496" (`addClienteDoContato`) antes do atendimento.

### CT-075 — Formato e comparação de telefone
- **Critério:** "O telefone vem no formato da base (`+55 67 99999-9999`); número sem DDD recebe o **67**. Dois números são o mesmo cliente quando batem DDD e os 8 últimos dígitos (com ou sem o nono dígito, com ou sem `+55`)."
- **Tipo:** Unitário · **Situação:** implementado — `telefone_test: formata no padrão da base, com 67 quando falta o DDD` · `telefone_test: compara pelo DDD e os 8 últimos dígitos` · `telefone_test: acha o cliente que já tem o telefone`
- **Pré-condições:** funções puras `formatarTelefone` e `mesmoTelefone`.
- **Passos:**
  1. Formatar "67993018496", "+55 (67) 99301-8496", "993018496", "6733841234" e "+1 202 555 0100".
  2. Comparar "+55 67 99301-8496" com "67 9301-8496", com "(67) 99301-8496" e com "+55 11 99301-8496".
- **Resultado esperado:** "+55 67 99301-8496", "+55 67 99301-8496", "+55 67 99301-8496", "+55 67 3384-1234" e o internacional como veio; iguais, iguais e diferentes (outro DDD).

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
- **Tipo:** Unitário + Widget · **Situação:** implementado — `peca_test: toMap de peça medida leva as medidas; contada só a quantidade` · `peca_test: tapete é o tipo medido por metragem; os demais são contados` · `atendimento_test: toMap grava a linha do banco, sem id e sem criado_em` · `seletor_de_pecas_test: tapete: medidas de 0,5 em 0,5 com os m² na hora` · `seletor_de_pecas_test: colchão, cortina, poltrona e cadeira por − / +` · `seletor_de_pecas_test: sofá: lugares de 2 a canto, retrátil e pôr outro sofá`
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
- **Tipo:** Unitário + Widget · **Situação:** implementado — `agenda_test: lerValor aceita virgula ou ponto e devolve nulo para vazio` · `atendimento_form_screen_test: sem serviço, valor mudado com vírgula; vazio grava sem valor`
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

### CT-101 — Atendimento rápido: peças e valor em tela própria
- **Critério:** "O registro continua **rápido**: peças e valor não são exigidos e ficam numa **linha de resumo** que abre a tela **Peças e valor** (o seletor do RF-013, com o rodapé do total); ao voltar, o resumo mostra as peças e o valor a cobrar, e o atendimento é salvo pelo botão do próprio formulário."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: atendimento rápido: peças e valor numa linha que abre a tela` · `atendimento_form_screen_test: voltar da tela de peças pela seta mantém o que foi marcado` · `atendimento_form_screen_test: exige cliente e período; hora é opcional`
- **Pré-condições:** tabela com higienizar sofá 3 lugares (R$ 200).
- **Passos:**
  1. Abrir um atendimento novo.
  2. Tocar na linha "Adicionar peças e valor", tocar Sofá e Higienizar, e "Pronto".
  3. Em outro registro, abrir a tela, marcar o serviço e voltar pela seta.
  4. Salvar.
- **Resultado esperado:** o formulário não mostra os quadros de peça nem o rodapé do total; a linha abre "Peças e valor"; ao voltar (por "Pronto" ou pela seta), o resumo mostra "sofá 3 lugares" e "R$ 200,00", e o atendimento é gravado com a peça e o valor. Sem abrir a tela, cliente e período bastam para salvar.

### CT-106 — Item avulso pelo nome no resumo
- **Critério:** "No resumo das peças (cartão da agenda, linha do formulário e histórico do cliente), o item do quadro Outros aparece pelo **nome** ("deslocamento", "excesso de pelo de pet"), e não como "outro"."
- **Tipo:** Unitário · **Situação:** implementado — `atendimento_test: item avulso aparece pelo nome no resumo, e não como "outro"`
- **Pré-condições:** peças: sofá de canto; "outro" com o serviço "Excesso de pelo de pet"; "outro" com o serviço "Deslocamento"; "outro" com 2 × "Tira-manchas"; "outro" antigo, sem serviço.
- **Passos:**
  1. Montar o resumo de cada peça (função pura, a mesma do cartão, do formulário e do histórico).
- **Resultado esperado:** "sofá de canto", "excesso de pelo de pet", "deslocamento", "2× tira-manchas" e, na peça antiga sem serviço, "outro".

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

### CT-067 — Trocar o dia na edição
- **Critério:** "Na edição, o dia do atendimento pode ser trocado por um calendário (adiar ou corrigir o dia anotado errado); salvo, o atendimento passa para o dia novo, com peças, valor e marcas, e a agenda passa a mostrar esse dia."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: na edição, trocar o dia leva a data nova ao update` · `atendimento_form_screen_test: no registro novo, a data não abre o calendário` · `agenda_screen_test: salvo com outro dia, a agenda vai para o dia novo`
- **Pré-condições:** um atendimento existente.
- **Passos:**
  1. Abrir a edição e tocar na data.
  2. Escolher outro dia no calendário e salvar.
  3. Abrir um registro novo e tocar na data.
- **Resultado esperado:** o update leva a data nova e mantém o resto; a agenda
  passa a mostrar o dia novo; no registro novo a data não abre o calendário
  (CT-040).

### CT-068 — Excluir atendimento com confirmação
- **Critério:** "Na edição, o atendimento pode ser excluído, após confirmação (cliente que desmarcou ou anotação errada); sem internet, a exclusão avisa e não acontece."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: excluir pede confirmação; cancelar não apaga, confirmar apaga` · `atendimento_form_screen_test: falha ao excluir avisa e mantém o formulário` · `atendimento_form_screen_test: registro novo não mostra o excluir`
- **Pré-condições:** um atendimento existente.
- **Passos:**
  1. Na edição, tocar em excluir e cancelar.
  2. Tocar em excluir e confirmar.
  3. Repetir com a exclusão falhando.
- **Resultado esperado:** cancelar não apaga; confirmar apaga pelo id e volta à
  agenda; a falha avisa e mantém o formulário aberto.

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

## RF-011 — Consultar o Histórico de um Cliente

> O histórico aparece no topo da tela do cliente (a que abre ao tocar no nome
> na lista). Conta só atendimentos **até hoje**: o que está marcado para o
> futuro ainda não é visita. O "hoje" é injetado, como na agenda.

### CT-076 — Última visita e há quanto tempo
- **Critério:** "A partir de um cliente, o sistema exibe a **data do atendimento mais recente** e **há quanto tempo** ele foi (ex.: "há 3 meses")."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `historico_test: há quanto tempo, de hoje a anos` · `client_form_screen_test: histórico: mostra a última visita e há quanto tempo`
- **Pré-condições:** hoje = 17/11/2026; cliente com atendimentos em 10/03/2026 e 12/08/2026, e um marcado para 30/11/2026.
- **Passos:**
  1. Calcular "há quanto tempo" para 0, 1, 5, 30, 95 e 400 dias.
  2. Abrir o cliente.
- **Resultado esperado:** "hoje", "ontem", "há 5 dias", "há 1 mês", "há 3 meses", "há 1 ano"; a tela mostra "há 3 meses" e "última visita em 12/08/26" (o de 30/11 não conta).

### CT-077 — Último valor cobrado, com data e peças
- **Critério:** "O sistema exibe o **valor do atendimento mais recente** que tenha valor registrado, junto da data desse atendimento e das peças que o compuseram."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `historico_test: último valor é o do atendimento mais recente com valor` · `client_form_screen_test: histórico: mostra o último valor com a data e as peças`
- **Pré-condições:** cliente com atendimento de 10/03/2026 (R$ 250,00, tapete 3 × 2) e de 12/08/2026 sem valor.
- **Passos:**
  1. Abrir o cliente.
- **Resultado esperado:** "R$ 250,00" com "cobrado em 10/03/26 · tapete 3 × 2" — o atendimento mais recente sem valor é pulado.

### CT-078 — Atendimentos anteriores, do mais recente ao mais antigo
- **Critério:** "O sistema exibe o histórico dos atendimentos anteriores daquele cliente, do mais recente para o mais antigo, com data, peças e valor de cada um."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `historico_test: só os atendimentos do cliente até hoje, do mais recente ao mais antigo` · `client_form_screen_test: histórico: lista os atendimentos do mais recente ao mais antigo`
- **Pré-condições:** atendimentos do cliente em 10/03/2026 e 12/08/2026, um futuro (30/11/2026) e um de outro cliente.
- **Passos:**
  1. Montar o histórico do cliente.
  2. Abrir o cliente.
- **Resultado esperado:** dois itens, 12/08/26 antes de 10/03/26, cada um com data, peças e valor ("—" quando não há valor); o futuro e o de outro cliente ficam fora.

### CT-079 — Cliente sem atendimento
- **Critério:** "Quando o cliente não tem nenhum atendimento registrado, o sistema exibe "Nenhum atendimento registrado" em vez de campos vazios ou zero."
- **Tipo:** Widget · **Situação:** implementado — `client_form_screen_test: histórico: sem atendimento mostra "Nenhum atendimento registrado"`
- **Pré-condições:** cliente sem atendimentos.
- **Passos:**
  1. Abrir o cliente.
- **Resultado esperado:** "Nenhum atendimento registrado", sem valor nem "há quanto tempo". No cadastro de cliente novo o histórico não aparece.

## RF-013 — Tabela de Preços e Cálculo do Valor

> Parte 1 (issue #123): a tabela editável, CT-080 a CT-086. Parte 2 (issue
> #124): o cálculo no atendimento, CT-087 a CT-092. Seletor de peças (issue
> #134): CT-093 a CT-100 e CT-102; o CT-101 (atendimento rápido) fica junto dos casos
> do RF-005.

### CT-080 — Serviço da tabela: nome, unidade e valor
- **Critério:** "A proprietária mantém a **tabela de preços** como uma lista de **serviços**: cada um com **nome** [...], **unidade de cobrança** (peça ou metro quadrado) e **valor**."
- **Tipo:** Unitário · **Situação:** implementado — `item_de_preco_test: lê nome, unidade e valor; valor nulo é sem valor` · `item_de_preco_test: unidade desconhecida vale peça; rótulos por peça e por m²` · `item_de_preco_test: toMap leva nome, unidade, valor e ordem, sem id nem criado_em`
- **Pré-condições:** linhas do banco com unidade `peca` e `m2`, com e sem valor.
- **Passos:**
  1. Ler cada linha (`ItemDePreco.fromMap`) e gravar de volta (`toMap`).
- **Resultado esperado:** nome, unidade e valor lidos; `valor` nulo vale "sem valor"; unidade desconhecida vale peça; os rótulos são "por peça" e "por m²"; o `toMap` leva nome, unidade, valor e ordem, sem id nem `criado_em`.

### CT-081 — Tabela aberta pela agenda, com nome, unidade e valor
- **Critério:** idem CT-080 (exibição).
- **Tipo:** Widget · **Situação:** implementado — `tabela_de_precos_screen_test: lista nome, unidade e valor; sem valor quando vazio` · `agenda_screen_test: ícone da barra abre a tabela de preços`
- **Pré-condições:** tabela com "Higienização sofá 3 lugares" (por peça, R$ 180,00) e "Higienização de tapete" (por m², sem valor).
- **Passos:**
  1. Na agenda, tocar no ícone da tabela de preços.
- **Resultado esperado:** abre "Tabela de preços" com os dois serviços, cada um com "por peça"/"por m²" e "R$ 180,00"/"sem valor".

### CT-082 — Adicionar e editar um serviço
- **Critério:** "Ela adiciona, edita e remove serviços." (adicionar e editar)
- **Tipo:** Widget · **Situação:** implementado — `tabela_de_precos_screen_test: adicionar exige nome e grava com o valor e a ordem seguinte` · `tabela_de_precos_screen_test: editar abre preenchido e apagar o valor grava sem valor`
- **Pré-condições:** tabela com um serviço.
- **Passos:**
  1. Tocar em adicionar, salvar sem nome; depois preencher "Impermeabilização poltrona", "por peça", valor "90,50" e salvar.
  2. Tocar no serviço existente, apagar o valor e salvar.
- **Resultado esperado:** sem nome não grava e avisa "Informe o nome"; o novo serviço é gravado com valor 90,5 e ordem depois do último; a edição grava o mesmo id com valor nulo ("sem valor"). A lista é renovada ao voltar.

### CT-083 — Remover um serviço com confirmação
- **Critério:** "Ela adiciona, edita e remove serviços." (remover)
- **Tipo:** Widget · **Situação:** implementado — `tabela_de_precos_screen_test: remover pede confirmação; cancelar não remove`
- **Pré-condições:** tabela com um serviço.
- **Passos:**
  1. Tocar na lixeira do serviço e cancelar.
  2. Tocar de novo e confirmar.
- **Resultado esperado:** cancelar não remove; confirmar remove pelo id e mostra "Serviço removido".

### CT-084 — Serviços independentes; combo é escolher os dois
- **Critério:** "**Cada serviço é independente**: impermeabilização é um serviço como higienização [...]" e "O **combo** [...] é escolher os dois serviços; o valor é a soma. Se ela cobra o combo com preço próprio, cadastra o combo como mais um serviço da tabela."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `item_de_preco_test: lista sugerida: higienização e impermeabilização separadas` · `tabela_de_precos_screen_test: dica: serviços independentes e combo`
- **Pré-condições:** nenhuma.
- **Passos:**
  1. Montar a lista sugerida (função pura).
  2. Abrir a tabela de preços.
- **Resultado esperado:** para cada peça que se impermeabiliza (sofás, poltrona, cadeira, tapete), há um item "Higienização ..." e outro "Impermeabilização ..." separados, nenhum chamado de extra; a tela mostra a dica de que cada serviço é independente e de que o combo é escolher os dois ou cadastrar o combo como mais um serviço.

### CT-085 — Tabela vazia começa pela lista sugerida, sem valor
- **Critério:** "A tabela começa com uma **lista inicial** de serviços **sem valor**, que ela completa."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `item_de_preco_test: lista sugerida vem sem valor, com ordem crescente e tapete por m²` · `tabela_de_precos_screen_test: tabela vazia começa com a lista sugerida, sem valor` · `tabela_de_precos_screen_test: com serviço cadastrado, a lista sugerida não aparece`
- **Pré-condições:** tabela vazia; depois, tabela com um serviço.
- **Passos:**
  1. Abrir a tabela vazia e tocar em "Começar com a lista sugerida".
  2. Abrir a tabela com um serviço.
- **Resultado esperado:** a lista sugerida é gravada de uma vez, todos os itens sem valor e com ordem crescente, e a lista é renovada; com serviço cadastrado, o botão não aparece.

### CT-086 — Tabela guardada no aparelho
- **Critério:** apoio ao cálculo sem internet (RNF-007; uso na parte 2, #124).
- **Tipo:** Unitário · **Situação:** implementado — `espelho_local_test: tabela de preços guardada no aparelho abre sem conexão`
- **Pré-condições:** banco com um serviço na tabela; depois, banco fora do ar.
- **Passos:**
  1. Abrir a tabela com o banco no ar.
  2. Reabrir com o banco fora do ar.
- **Resultado esperado:** a segunda abertura mostra o serviço guardado no aparelho, sem erro na stream, e o estado fica "sem conexão".

### CT-087 — Serviço sozinho ou combo na peça, com o preço copiado
- **Critério:** "**Cada serviço é independente**: impermeabilização [...] pode ser orçada e registrada **sozinha**, sem higienização na mesma peça." e "O **combo** [...] é escolher os dois serviços; o valor é a soma."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `atendimento_test: serviços da peça vão ao jsonb com o preço copiado` · `calculo_test: serviço sozinho ou combo: o total é a soma` · `calculo_test: linha da tabela por peça, variante, retrátil e serviço` · `seletor_de_pecas_test: higienizar e impermeabilizar marcados separados ou juntos` · `atendimento_form_screen_test: rodapé fixo: total, detalhes e salvar sem rolar`
- **Pré-condições:** tabela com "Higienização sofá 3 lugares" (R$ 180,00) e "Impermeabilização sofá 3 lugares" (R$ 150,00).
- **Passos:**
  1. Gravar e ler de volta uma peça com serviços (`Peca.toMap`/`fromMap`).
  2. No formulário, peça sofá: marcar só a impermeabilização e salvar.
  3. Em outro registro, marcar os dois serviços.
- **Resultado esperado:** o jsonb da peça leva `servicos` com nome, unidade e valor de cada um (sem a chave quando não há serviço); só a impermeabilização é gravada, com R$ 150,00; com os dois, o total é R$ 330,00. Desde a #134, os serviços de cada peça são os botões Higienizar e Impermeabilizar do seletor (CT-095).

### CT-088 — Serviço por m²: largura × comprimento × valor do metro
- **Critério:** "Para serviços cobrados por metro quadrado, o sistema calcula a área a partir de largura × comprimento e multiplica pelo valor do metro (ex.: `8 × 4,5 = 36 m²`)."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `calculo_test: por m²: largura × comprimento × valor do metro` · `calculo_test: por m² sem medida não soma e avisa que falta medida` · `seletor_de_pecas_test: tapete: medidas de 0,5 em 0,5 com os m² na hora`
- **Pré-condições:** "Higienização de tapete" por m² a R$ 12,00.
- **Passos:**
  1. Calcular um tapete 8 × 4,5 com o serviço (função pura); depois sem uma das medidas; depois dois tapetes iguais.
  2. No formulário, tapete com o serviço, largura 8 e comprimento 4,5.
- **Resultado esperado:** 36 m² × R$ 12,00 = R$ 432,00; sem medida não soma e avisa "falta medida"; dois tapetes iguais somam R$ 864,00.

### CT-089 — Serviço por peça: valor × quantidade
- **Critério:** "Para serviços cobrados por peça, o sistema multiplica o valor pela quantidade."
- **Tipo:** Unitário · **Situação:** implementado — `calculo_test: por peça: valor × quantidade`
- **Pré-condições:** "Higienização poltrona" a R$ 90,00.
- **Passos:**
  1. Calcular duas poltronas com o serviço.
- **Resultado esperado:** R$ 180,00.

### CT-090 — Total à vista enquanto informa; serviço sem valor avisa
- **Critério:** "O valor total é a soma dos serviços, exibido enquanto eles são informados." e "um serviço sem valor não entra no cálculo, e o total avisa que falta valor."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `calculo_test: serviço sem valor não entra na soma e é avisado` · `atendimento_form_screen_test: rodapé fixo: total, detalhes e salvar sem rolar` · `atendimento_form_screen_test: serviço sem valor aparece no aviso do rodapé`
- **Pré-condições:** tabela com um serviço com valor e "Remoção de odor" sem valor.
- **Passos:**
  1. Somar peças com serviços com e sem valor (função pura).
  2. No formulário, marcar o serviço com valor, mudar a quantidade e depois marcar o sem valor.
- **Resultado esperado:** o total muda a cada toque e a cada número digitado; o serviço sem valor não soma e aparece o aviso com o nome dele.

### CT-091 — Valor calculado é sugestão, sobrescrevível
- **Critério:** "O valor calculado é **sugestão, não imposição**: a proprietária pode sobrescrevê-lo (desconto, combinado diferente) sem alterar a tabela."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: valor mudado prevalece; usar o calculado volta ao total`
- **Pré-condições:** tabela com "Higienização sofá 3 lugares" a R$ 180,00.
- **Passos:**
  1. Marcar o serviço: o valor a cobrar acompanha o total.
  2. Mudar o valor (rodapé, desde a #134) e mudar a quantidade.
  3. Tocar em "Usar o calculado" e salvar.
- **Resultado esperado:** o Valor vem "180,00"; digitado, fica 150 mesmo com o total mudando, e grava 150 se salvo assim; "Usar o calculado" volta ao total. A tabela de preços não é gravada.

### CT-092 — Tabela alterada não muda o atendimento registrado
- **Critério:** "Alterar a tabela de preços **não altera** o valor de atendimentos e orçamentos já registrados."
- **Tipo:** Widget · **Situação:** implementado — `atendimento_form_screen_test: atendimento da versão anterior abre e salva os mesmos preços`
- **Pré-condições:** atendimento registrado com "Higienização sofá 3 lugares" copiado a R$ 180,00 e valor R$ 180,00; a tabela agora cobra R$ 200,00.
- **Passos:**
  1. Abrir o atendimento para editar e salvar sem mexer nos serviços.
- **Resultado esperado:** o serviço segue com R$ 180,00 (o preço copiado), o total e o Valor mostram 180,00 e o update grava R$ 180,00.

### CT-093 — Peça escolhida em quadros por família
- **Critério:** "A peça é escolhida em **quadros por família**, com ícone e cor próprios, nesta ordem: sofá, tapete, poltrona, cortina, colchão, cadeira e outros; cada quadro mostra quantas peças daquela família já estão no atendimento (×N)."
- **Tipo:** Widget · **Situação:** implementado — `seletor_de_pecas_test: quadros na ordem das famílias, com selo ×N`
- **Pré-condições:** atendimento novo.
- **Passos:**
  1. Ver os quadros do seletor.
  2. Tocar em Sofá duas vezes e em Poltrona uma.
- **Resultado esperado:** sete quadros na ordem sofá, tapete, poltrona, cortina, colchão, cadeira, outros; sem selo antes de tocar; depois, Sofá com ×2 (dois cartões de sofá) e Poltrona com ×1.

### CT-094 — Ajuste da peça sem digitar
- **Critério:** "A peça é **ajustada sem digitar**, com botões − / + [...]"
- **Tipo:** Unitário + Widget · **Situação:** implementado — `seletor_de_pecas_test: sofá: lugares de 2 a canto, retrátil e pôr outro sofá` · `seletor_de_pecas_test: tapete: medidas de 0,5 em 0,5 com os m² na hora` · `seletor_de_pecas_test: colchão, cortina, poltrona e cadeira por − / +` · `atendimento_test: peça guarda variante e retrátil; serviço antigo reconhecido pelo nome` · `atendimento_test: resumo leva lugares, tamanho e retrátil`
- **Pré-condições:** atendimento novo.
- **Passos:**
  1. Sofá: + e − nos lugares, ligar o retrátil, "Pôr outro sofá".
  2. Tapete: + na largura e no comprimento.
  3. Colchão: + em Casal duas vezes. Cortina: + nas folhas. Poltrona e cadeira: + na quantidade.
  4. Salvar.
- **Resultado esperado:** lugares andam 2 → 3 → 4 → de canto e voltam, sem passar dos limites; o tapete mostra os m² a cada toque (passo de 0,5 m); o colchão Casal vira uma peça com quantidade 2; as peças gravadas levam tipo, quantidade, variante, retrátil e medidas. Nenhum campo de texto é preciso.

### CT-095 — Higienizar e Impermeabilizar em cada peça
- **Critério:** "Em **cada peça**, os serviços **Higienizar** e **Impermeabilizar** são marcados separadamente ou juntos (combo); nenhum é extra do outro, e a peça pode ter só a impermeabilização."
- **Tipo:** Widget · **Situação:** implementado — `seletor_de_pecas_test: higienizar e impermeabilizar marcados separados ou juntos` · `atendimento_form_screen_test: rodapé fixo: total, detalhes e salvar sem rolar`
- **Pré-condições:** tabela com higienizar e impermeabilizar do sofá 3 lugares.
- **Passos:**
  1. No cartão do sofá, marcar só Impermeabilizar e salvar.
  2. Em outro registro, marcar os dois.
- **Resultado esperado:** só a impermeabilização é gravada; com os dois, as duas linhas somam; cada botão mostra o preço do serviço.

### CT-096 — Preço por peça, variante e serviço
- **Critério:** "O preço de cada serviço marcado vem da linha da tabela com a **mesma peça, variante (lugares, tamanho) e serviço** [...] No sofá ou na poltrona **retrátil/reclinável**, o preço é o da mesma peça não retrátil **mais o acréscimo do retrátil** [...]; sem acréscimo cadastrado, vale o preço comum."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `calculo_test: linha da tabela por peça, variante, retrátil e serviço` · `calculo_test: sem linha, ou sem valor, fica sem valor; nunca outra variante` · `calculo_test: retrátil soma o acréscimo ao preço da mesma peça` · `seletor_de_pecas_test: preço troca com a variante; sem linha fica sem valor` · `atendimento_form_screen_test: serviço sem valor aparece no aviso do rodapé`
- **Pré-condições:** tabela com higienizar sofá 3 lugares (R$ 200), sofá 4 lugares sem linha, retrátil 3 lugares sem valor, acréscimo do retrátil 2 lugares (R$ 30) e sofá 2 lugares (R$ 170), colchão casal (R$ 150), tapete por m² (R$ 12).
- **Passos:**
  1. Procurar o preço de cada combinação (função pura).
  2. No seletor, marcar Higienizar num sofá de 3 lugares; passar a 4 lugares; voltar a 3 e ligar o retrátil.
- **Resultado esperado:** 3 lugares acha R$ 200; ao mudar a variante, o serviço marcado troca de preço; 4 lugares fica "sem valor" com o aviso; 3 lugares retrátil (acréscimo sem valor) fica nos R$ 200 do comum, com "retrátil" no nome; 2 lugares retrátil soma o acréscimo: R$ 170 + R$ 30 = R$ 200; colchão casal × 2 soma R$ 300; tapete 2 × 3 soma R$ 72.

### CT-097 — Rodapé fixo com total, detalhes e salvar
- **Critério:** "Um **rodapé fixo** mostra o total em destaque, a lista detalhada (serviço, legenda e valor de cada linha) e o botão de salvar; o valor segue sugestão, com \"Usar o calculado\" depois de sobrescrito."
- **Tipo:** Widget · **Situação:** implementado — `calculo_test: linhas do total com legenda e valor` · `atendimento_form_screen_test: rodapé fixo: total, detalhes e salvar sem rolar` · `atendimento_form_screen_test: valor mudado prevalece; usar o calculado volta ao total` · `atendimento_form_screen_test: sem serviço, valor mudado com vírgula; vazio grava sem valor` · `barra_do_sistema_test: formulário de atendimento termina acima da barra` · `barra_do_sistema_test: tela de peças e valor termina acima da barra`
- **Pré-condições:** tabela com higienizar sofá 3 lugares (R$ 200).
- **Passos:**
  1. Marcar o serviço; abrir os detalhes.
  2. Mudar o valor para 180; mudar os lugares; tocar em "Usar o calculado"; salvar.
- **Resultado esperado:** o rodapé fica à vista sem rolar e mostra "R$ 200,00"; os detalhes listam "Higienização sofá 3 lugares", a legenda e o valor; o valor mudado fica mesmo com o total mudando; "Usar o calculado" volta ao total, que é gravado.

### CT-098 — Deslocamento em bloco próprio; avulsos pelo quadro Outros
- **Critério:** "O **deslocamento** fica fora do quadro Outros, num bloco próprio, e **já vem incluído** quando ela abre Peças e valor de um atendimento ainda sem peças [...]; o valor, o da tabela, sobe e desce de **R$ 1 em R$ 1** com − / + e pode ser **digitado** tocando nele; um interruptor tira o deslocamento [...]. Os outros itens avulsos [...] entram pelo quadro **Outros**, cada um com a sua quantidade."
- **Tipo:** Widget · **Situação:** implementado — `seletor_de_pecas_test: deslocamento fora dos Outros, já incluído, de R$ 1 em R$ 1 ou digitado` · `seletor_de_pecas_test: sem o pedido, abre sem deslocamento e ele pode ser ligado`
- **Pré-condições:** tabela com "Deslocamento" (avulso, R$ 30) e "Remoção de mancha" (avulso, R$ 50).
- **Passos:**
  1. Abrir o seletor sem peças, pedindo o deslocamento incluído; abrir o quadro Outros.
  2. Tocar + duas vezes e − uma vez no deslocamento; tocar no valor e digitar 50.
  3. Tocar + duas vezes na Remoção de mancha; desligar o deslocamento.
  4. Abrir o seletor sem pedir o deslocamento incluído.
- **Resultado esperado:** o deslocamento já está no registro com R$ 30, fora do quadro Outros (que não o lista); vai a R$ 31 e depois R$ 50, marcado como ajustado sobre a tabela; a mancha soma 2 × R$ 50; desligado, o deslocamento sai do total. Sem o pedido, o seletor abre sem deslocamento e ele pode ser ligado no bloco. O atendimento grava peças "outro" com os serviços.

### CT-099 — Atendimento da versão anterior abre e salva sem perder
- **Critério:** "Atendimentos registrados antes desta interação abrem com as peças e os preços copiados, e salvar não perde nenhum serviço."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `atendimento_test: peça guarda variante e retrátil; serviço antigo reconhecido pelo nome` · `seletor_de_pecas_test: peças de antes abrem e voltam iguais` · `atendimento_form_screen_test: atendimento da versão anterior abre e salva os mesmos preços`
- **Pré-condições:** atendimento da #124: sofá sem variante com "Higienização sofá 3 lugares" copiado a R$ 180 e "Remoção de odor" sem valor; tapete 2 × 3.
- **Passos:**
  1. Ler a peça antiga (função pura).
  2. Abrir o atendimento e salvar sem mexer.
- **Resultado esperado:** a higienização é reconhecida como Higienizar, com R$ 180; a remoção de odor segue na peça; o update grava os mesmos serviços e preços.

### CT-100 — Tabela com peça, variante e serviço
- **Critério:** "Na tabela de preços, cada serviço informa a **peça**, a **variante** e o **serviço** [...] sem linhas de retrátil (ela cadastra o acréscimo quando quiser); a linha retrátil aparece e se edita como acréscimo ("+ R$"); a cortina é cobrada por folha."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `item_de_preco_test: colunas peca, variante, servico e retratil vão e voltam` · `item_de_preco_test: lista sugerida com peça, variante e serviço; sem linhas de retrátil` · `tabela_de_precos_screen_test: editor grava peça, variante, serviço e retrátil` · `tabela_de_precos_screen_test: retrátil aparece e se edita como acréscimo`
- **Pré-condições:** nenhuma.
- **Passos:**
  1. Ler e gravar um item com as colunas novas.
  2. Montar a lista sugerida.
  3. No editor da tabela, criar "Impermeabilização sofá 4 lugares" escolhendo peça, variante e serviço.
  4. Abrir a tabela com a linha "Higienização sofá 3 lugares retrátil" (R$ 30) e editá-la.
- **Resultado esperado:** as colunas `peca`, `variante`, `servico` e `retratil` vão e voltam; a lista sugerida traz higienizar e impermeabilizar com peça e variante, nenhuma linha de retrátil e a cortina por peça; o editor grava peça, variante e serviço escolhidos; a linha retrátil aparece como "+ R$ 30,00" e o editor pede o "Acréscimo do retrátil".

### CT-102 — Preço de um serviço ajustado só no registro
- **Critério:** "O **preço de cada serviço** marcado pode ser **ajustado só neste registro** (tecido especial, desconto, combinado), com uma **justificativa opcional**; o serviço e os detalhes do total mostram o valor ajustado ao lado do preço da tabela, e "Voltar ao da tabela" desfaz. A tabela não muda."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `atendimento_test: ajuste do serviço vai ao jsonb com o preço da tabela e a justificativa` · `calculo_test: linha ajustada mostra o preço da tabela e a justificativa` · `seletor_de_pecas_test: ajustar o preço de um serviço só neste registro, com justificativa` · `seletor_de_pecas_test: voltar ao preço da tabela desfaz o ajuste`
- **Pré-condições:** tabela com higienizar sofá 2 lugares (R$ 170) e "Deslocamento" (avulso, R$ 40).
- **Passos:**
  1. Marcar Higienizar no sofá de 2 lugares e tocar em "Ajustar" no serviço.
  2. Informar R$ 220 e a justificativa "tecido linho"; confirmar.
  3. Abrir os detalhes do total; salvar.
  4. Num outro registro, ajustar e depois "Voltar ao da tabela".
- **Resultado esperado:** o serviço mostra R$ 220,00 e "ajustado"; os detalhes trazem "tabela R$ 170,00 · tecido linho" e o total soma R$ 220; o jsonb grava o valor 220, o preço da tabela (170) e a justificativa; a tabela de preços não muda. "Voltar ao da tabela" volta a R$ 170 sem justificativa. Sem justificativa, o ajuste vale do mesmo jeito.

### CT-103 — Tabela dividida em produto, mão de obra e imprevisto
- **Critério:** "Cada item da tabela pertence a um **grupo**, como no app de referência: **produto**, **mão de obra** ou **imprevisto** (sem grupo informado, mão de obra). A tabela de preços aparece dividida nesses três grupos, e o editor escolhe o grupo. A lista inicial já traz os produtos (impermeabilizante do sofá por lugares, neutralizador de odor, tira-manchas, hidratante de couro) e os imprevistos (segunda lavagem, excesso de pelo, mofo, urina com odor), sem valor."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `item_de_preco_test: coluna categoria vai e volta; sem ela, mão de obra` · `item_de_preco_test: lista sugerida com produtos e imprevistos, sem valor` · `tabela_de_precos_screen_test: tabela dividida em produtos, mão de obra e imprevistos` · `tabela_de_precos_screen_test: editor grava o grupo escolhido`
- **Pré-condições:** nenhuma.
- **Passos:**
  1. Ler e gravar um item com a coluna `categoria`; ler um item sem ela.
  2. Montar a lista sugerida.
  3. Abrir a tabela com um produto, um serviço e um imprevisto; no editor, criar "Neutralizador de odor" escolhendo o grupo Produto.
- **Resultado esperado:** `categoria` vai e volta (`produto`, `mao_de_obra`, `imprevisto`); sem ela, o item é mão de obra. A lista sugerida traz o impermeabilizante do sofá de 2, 3, 4 lugares e de canto (produto ligado a impermeabilizar), os produtos avulsos e os imprevistos, todos sem valor. A tela mostra os títulos Produtos, Mão de obra e Imprevistos, cada item no seu grupo; o editor grava o grupo escolhido.

### CT-104 — Produto vem junto com o serviço da peça
- **Critério:** "Um **produto** da tabela com peça e serviço **vem junto com o serviço**: ao marcar o serviço na peça, entram a linha de mão de obra e os produtos da mesma peça e serviço (com a mesma variante, ou sem variante, que vale para todas). Ex.: impermeabilizar o sofá de 3 lugares traz a aplicação (mão de obra, R$ 90) e o impermeabilizante (produto, R$ 190), como na nota do app de referência; o botão do serviço mostra a soma, e cada linha tem o seu preço e o seu ajuste. O retrátil não muda o produto. Desmarcar o serviço tira os dois."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `calculo_test: produtos do serviço: mesma peça e serviço, variante igual ou nenhuma` · `seletor_de_pecas_test: produto vem junto com o serviço: botão soma, cada linha com preço e ajuste` · `seletor_de_pecas_test: produto sem variante vale para a peça toda (tapete por m²)`
- **Pré-condições:** tabela com impermeabilizar sofá 3 lugares (mão de obra, R$ 90) e 4 lugares (R$ 120); "Impermeabilizante sofá 3 lugares" (produto, R$ 190) e "Impermeabilizante sofá 4 lugares" (produto, R$ 250), ligados a impermeabilizar; impermeabilização de tapete (R$ 10/m²) e "Impermeabilizante de tapete" (produto, sem variante, R$ 5/m²).
- **Passos:**
  1. Procurar os produtos de cada combinação (função pura).
  2. No seletor, marcar Impermeabilizar num sofá de 3 lugares; passar a 4 lugares; ligar o retrátil; ajustar o preço do produto; salvar; reabrir; desmarcar.
  3. Num tapete 2 × 3, marcar Impermeabilizar.
- **Resultado esperado:** o sofá de 3 lugares traz a aplicação (R$ 90) e o impermeabilizante (R$ 190), e o botão mostra R$ 280,00; em 4 lugares, R$ 120 + R$ 250 = R$ 370,00; o retrátil não muda o produto; o produto ajustado mostra "ajustado"; a peça gravada leva o serviço e o produto, e reabrir não perde o produto; desmarcado, as duas linhas saem. No tapete, o produto sem variante vale: 6 m² × (R$ 10 + R$ 5) = R$ 90.

### CT-105 — Grupo de cada serviço no registro e no total
- **Critério:** "O registro grava o **grupo de cada serviço** (serviço gravado sem grupo conta como mão de obra), para a nota do orçamento (RF-017) separar produtos, mão de obra e imprevistos. Os avulsos do quadro Outros aparecem separados por grupo; o **deslocamento é mão de obra**. Os detalhes do rodapé mostram o **subtotal de cada grupo** com valor, antes das linhas."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `atendimento_test: grupo do serviço vai ao jsonb; sem a chave, mão de obra` · `calculo_test: soma por grupo: produto, mão de obra e imprevisto; sem grupo é mão de obra` · `seletor_de_pecas_test: avulsos do quadro Outros separados por grupo; deslocamento fora` · `seletor_de_pecas_test: detalhes do rodapé mostram o subtotal de cada grupo`
- **Pré-condições:** a tabela do CT-104 e os avulsos "Deslocamento" (mão de obra, R$ 20), "Remoção de mancha" (mão de obra, R$ 50), "Tira-manchas" (produto, R$ 15) e "Segunda lavagem" (imprevisto, R$ 60).
- **Passos:**
  1. Gravar e ler peças com serviços de cada grupo e um serviço antigo sem grupo; somar por grupo (função pura).
  2. No seletor, abrir o quadro Outros.
  3. Com impermeabilizar sofá 3 lugares, tira-manchas, segunda lavagem e o deslocamento, abrir os detalhes do rodapé.
- **Resultado esperado:** o jsonb leva `categoria` no produto e no imprevisto (a mão de obra fica sem a chave: é o padrão), e o serviço antigo é lido como mão de obra. O quadro Outros mostra os títulos Produtos, Mão de obra e Imprevistos com os avulsos de cada um; o deslocamento segue fora, no bloco próprio. Os detalhes mostram Produtos R$ 205,00, Mão de obra R$ 110,00 (aplicação R$ 90 + deslocamento R$ 20) e Imprevistos R$ 60,00, com o total de R$ 375,00.

## RF-014 — Estados de Conclusão do Atendimento

### CT-049 — Dois marcadores independentes
- **Critério:** "Cada atendimento tem dois marcadores **independentes**:
  *serviço feito* e *cliente pagou*, cada um podendo ser ligado e desligado."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `atendimento_test: lê feito e pago; ausentes valem falso` · `atendimento_test: toMap não leva feito nem pago` · `agenda_screen_test: marcar serviço feito não abre o formulário e não marca o pago` · `agenda_screen_test: desmarcar o pago desliga só ele`
- **Pré-condições:** um atendimento sem marca e outro com as duas.
- **Passos:**
  1. Ler uma linha do banco com e sem as colunas `feito` e `pago` (função pura).
  2. Na agenda, marcar "Feito" no primeiro; desmarcar "Pago" no segundo.
- **Resultado esperado:** colunas ausentes valem falso; marcar "Feito" grava só
  o feito e não liga o pago; desmarcar "Pago" grava só o pago e mantém o feito.

### CT-050 — Concluído somente com os dois marcados
- **Critério:** "Um atendimento é considerado **concluído** somente quando **os
  dois** estão marcados."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `atendimento_test: concluído só com os dois marcados` · `agenda_screen_test: cartão distingue nada marcado, um dos dois e concluído`
- **Pré-condições:** atendimentos nas quatro combinações de feito e pago.
- **Passos:**
  1. Consultar `concluido` em cada combinação (função pura).
  2. Renderizar a agenda.
- **Resultado esperado:** só o atendimento com feito e pago é concluído e exibe
  a indicação "Concluído".

### CT-051 — Três situações distinguíveis na agenda
- **Critério:** "A agenda distingue visualmente três situações: nada marcado, um
  dos dois marcado, e concluído."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: cartão distingue nada marcado, um dos dois e concluído`
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
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: marcar serviço feito não abre o formulário e não marca o pago` · `agenda_screen_test: falha ao marcar desfaz a marca e avisa`
- **Pré-condições:** um atendimento no dia.
- **Passos:**
  1. Tocar na marca "Feito" do cartão.
  2. Repetir com a gravação falhando.
- **Resultado esperado:** a marca muda no próprio cartão, sem abrir o
  formulário; se a gravação falha, a marca volta ao estado anterior e um aviso é
  exibido.

## RF-015 — Avisos no Celular

A regra de quais avisos existem e quando é a função pura `planejarAvisos`
(`lib/utils/avisos.dart`), testada com o "agora" injetado; a entrega ao
Android (`flutter_local_notifications`) só se verifica no aparelho (pilha manual).

### CT-060 — Resumo da véspera às 19h
- **Critério:** "Às 19h da véspera de um dia com atendimentos, o celular avisa quantos são no dia seguinte, por período, com os nomes dos clientes."
- **Tipo:** Unitário · **Situação:** implementado — `avisos_test: resumo da véspera às 19h com os períodos e os nomes` · `avisos_test: um atendimento só usa o singular e omite o período vazio`
- **Pré-condições:** atendimentos em 17/11 (dois de manhã, um à tarde); agora 16/11 às 10h.
- **Passos:**
  1. Planejar os avisos.
- **Resultado esperado:** há um aviso em 16/11 às 19h com o título "Amanhã: 3 atendimentos", o corpo com "2 de manhã, 1 à tarde" e os nomes, e o dia 17/11.

### CT-061 — Resumo do dia às 7h
- **Critério:** "Às 7h de um dia com atendimentos, o celular avisa quantos são hoje, por período, com os nomes dos clientes."
- **Tipo:** Unitário · **Situação:** implementado — `avisos_test: resumo do dia às 7h`
- **Pré-condições:** os mesmos atendimentos de 17/11.
- **Passos:**
  1. Planejar os avisos.
- **Resultado esperado:** há um aviso em 17/11 às 7h com o título "Hoje: 3 atendimentos" e o dia 17/11.

### CT-062 — Aviso 1 hora antes do atendimento com hora
- **Critério:** "Um atendimento com hora gera um aviso 1 hora antes, com o cliente, a hora e o local."
- **Tipo:** Unitário · **Situação:** implementado — `avisos_test: aviso 1 hora antes só para atendimento com hora` · `avisos_do_aparelho_test: o aviso é agendado no mesmo instante, qualquer que seja o fuso`
- **Pré-condições:** um atendimento em 17/11 às 14:00 com local, e um sem hora.
- **Passos:**
  1. Planejar os avisos.
- **Resultado esperado:** há um aviso em 17/11 às 13h com o nome, "14:00" e o local; o sem hora não gera aviso de hora.

### CT-063 — Lembrete de feito e não pago no terceiro dia
- **Critério:** "Um atendimento com serviço feito e sem pagamento gera um lembrete de cobrança às 10h do terceiro dia depois da data do atendimento; marcar o pago antes disso cancela o lembrete."
- **Tipo:** Unitário · **Situação:** implementado — `avisos_test: lembrete de cobrança só para feito e não pago, no terceiro dia às 10h`
- **Pré-condições:** atendimentos de 14/11: um feito e não pago, um feito e pago, um não feito.
- **Passos:**
  1. Planejar os avisos.
- **Resultado esperado:** só o feito e não pago gera aviso, em 17/11 às 10h, com o nome e o valor quando houver.

### CT-064 — Avisos acompanham a agenda e não ficam no passado
- **Critério:** "Os avisos acompanham a agenda: registrar, mudar a hora, marcar o pago ou excluir um atendimento refaz os avisos; avisos de horário que já passou não são agendados."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `avisos_test: avisos com horário que já passou não entram` · `agenda_screen_test: a agenda refaz os avisos a cada nova lista de atendimentos`
- **Pré-condições:** agora 16/11 às 20h; agenda com atendimentos.
- **Passos:**
  1. Planejar os avisos com horários já passados.
  2. Na agenda, a lista de atendimentos muda.
- **Resultado esperado:** nenhum aviso fica com horário no passado; a agenda substitui os avisos agendados a cada nova lista.

### CT-065 — Tocar no aviso abre o dia
- **Critério:** "Tocar no aviso abre a agenda no dia a que ele se refere."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: tocar num aviso abre o dia dele` · `agenda_screen_test: aberta por um aviso, a agenda começa no dia dele`
- **Pré-condições:** agenda aberta em outro dia.
- **Passos:**
  1. Tocar em um aviso do dia 20/11.
- **Resultado esperado:** a agenda seleciona 20/11 e mostra os atendimentos dele.

### CT-066 — Pedido de liberação da economia de bateria
- **Critério:** "Na primeira abertura, o app pede ao sistema, em um toque, para ficar fora da economia de bateria; se ela negar, só volta a pedir depois de 30 dias; se já estiver liberado, não pede."
- **Tipo:** Unitário + Manual (aparelho) · **Situação:** implementado — `bateria_test: pede a liberação quando ainda não foi liberada nem pedida` · `bateria_test: não pede se a bateria já está liberada` · `bateria_test: negado, não pede de novo antes de 30 dias` · `bateria_test: negado há mais de 30 dias, pede de novo`; o diálogo real, na pilha
- **Pré-condições:** uma liberação de bateria falsa e um armazenamento em memória.
- **Passos:**
  1. Abrir sem pedido anterior e sem liberação.
  2. Abrir com a bateria já liberada.
  3. Abrir 10 dias e depois 31 dias após um pedido negado.
- **Resultado esperado:** pede no passo 1 e grava a data do pedido; não pede
  no passo 2; no passo 3, não pede aos 10 dias e pede de novo aos 31.

## RNF-007 — Anotar sem internet

Os casos usam o `EspelhoLocal` (`lib/services/espelho_local.dart`) com um banco
falso, que pode estar "fora do ar", e um armazenamento em memória no lugar do
`shared_preferences` — o que permite simular fechar e reabrir o app.

### CT-053 — Sem rede, abre com os últimos dados guardados
- **Critério:** "Sem rede, a agenda e a lista de clientes abrem com os últimos
  dados guardados no aparelho, em vez de uma tela vazia."
- **Tipo:** Unitário · **Situação:** implementado — `espelho_local_test: guarda no aparelho o que chega do banco` · `espelho_local_test: sem conexão, abre com o que está guardado no aparelho`
- **Pré-condições:** uma leitura anterior com o banco no ar.
- **Passos:**
  1. Receber atendimentos e clientes do banco.
  2. Abrir de novo com o banco fora do ar.
- **Resultado esperado:** os dados recebidos ficam guardados; na segunda
  abertura, a stream emite os dados guardados, sem erro.

### CT-054 — Registro sem rede fica no aparelho e aparece aguardando envio
- **Critério:** "Um atendimento novo — e o cliente provisório criado com ele —
  registrado sem rede fica gravado no aparelho e aparece na agenda na hora com a
  marca "aguardando envio"."
- **Tipo:** Unitário + Widget · **Situação:** implementado — `espelho_local_test: registrar sem conexão guarda na fila e aparece como aguardando envio` · `espelho_local_test: cliente provisório sem conexão entra na fila antes do atendimento` · `agenda_screen_test: atendimento aguardando envio aparece marcado`
- **Pré-condições:** banco fora do ar.
- **Passos:**
  1. Registrar um cliente provisório e um atendimento para ele.
  2. Exibir a agenda com um atendimento pendente.
- **Resultado esperado:** os dois entram na fila (o cliente antes do
  atendimento) e são emitidos nas streams com a marca de pendente; o cartão
  mostra "aguardando envio".

### CT-055 — Envio automático ao voltar a conexão, sem duplicar
- **Critério:** "É enviado ao banco sozinho quando a conexão voltar, sem
  duplicar."
- **Tipo:** Unitário · **Situação:** implementado — `espelho_local_test: ao voltar a conexão envia a fila na ordem e esvazia` · `espelho_local_test: o id é gerado no app: o envio leva o id e reenviar não duplica` · `espelho_local_test: linha repetida pelo banco aparece uma vez só`
- **Pré-condições:** dois itens na fila.
- **Passos:**
  1. O banco volta e a stream recebe dados.
  2. Reenviar um item que o banco já tem.
- **Resultado esperado:** a fila é enviada na ordem em que foi gravada e
  esvaziada; cada envio leva o id gerado no app, e o reenvio não cria linha
  nova.

### CT-056 — Aviso de "sem conexão"; falha não vira lista vazia
- **Critério:** "A agenda e a lista de clientes exibem um aviso discreto de
  "sem conexão"; falha de conexão não aparece como lista vazia." (bug #47)
- **Tipo:** Unitário + Widget · **Situação:** implementado — `espelho_local_test: falha de conexão vira aviso, não erro na stream` · `agenda_screen_test: sem conexão mostra o aviso na agenda` · `home_screen_test: sem conexão mostra o aviso e não diz que não há clientes`
- **Pré-condições:** banco fora do ar.
- **Passos:**
  1. Abrir a stream com o banco fora do ar.
  2. Exibir a agenda e a lista de clientes sem conexão.
- **Resultado esperado:** a stream não emite erro e o estado de conexão passa a
  falso; as duas telas mostram o aviso, e a lista de clientes não diz "Nenhum
  cliente encontrado." por causa da falha.

### CT-057 — Nada se perde ao fechar e reabrir
- **Critério:** "Nada anotado sem rede se perde ao fechar e reabrir o app."
- **Tipo:** Unitário · **Situação:** implementado — `espelho_local_test: a fila sobrevive a fechar e reabrir o app`
- **Pré-condições:** um atendimento registrado sem rede.
- **Passos:**
  1. Descartar o `EspelhoLocal` e criar outro sobre o mesmo armazenamento.
- **Resultado esperado:** o atendimento continua na fila e é emitido como
  pendente.

### CT-058 — Item aguardando envio não se edita nem se marca
- **Critério:** "Um item ainda aguardando envio também não se edita nem se marca
  até ser enviado."
- **Tipo:** Widget · **Situação:** implementado — `agenda_screen_test: atendimento aguardando envio não abre o formulário nem marca` · `home_screen_test: cliente aguardando envio não abre a edição nem exclui`
- **Pré-condições:** um atendimento e um cliente pendentes.
- **Passos:**
  1. Tocar no cartão pendente e na marca "Feito".
  2. Na lista de clientes, tocar no cliente pendente e na lixeira.
- **Resultado esperado:** nada abre nem grava; um aviso explica que o item ainda
  está aguardando envio.

## RNF-008 — Identidade visual

### CT-059 — Ícone, nome e abertura com a marca
- **Critério:** "Na gaveta de apps, o ícone é o símbolo da marca sobre o
  azul-marinho, e o nome exibido é "MS Clean". Ao abrir, aparece o logo
  completo sobre o mesmo azul-marinho. Na web, a aba e o atalho usam o mesmo
  símbolo e o mesmo nome."
- **Tipo:** Unitário (guarda sobre os arquivos de plataforma) + Manual (aparelho)
  · **Situação:** implementado (guarda) — `marca_test: nome MS Clean no Android e na web` · `marca_test: ícone adaptativo com o símbolo sobre o azul-marinho` · `marca_test: abertura com o logo sobre o azul-marinho`; parte manual na pilha
- **Pré-condições:** ícones e abertura gerados a partir de `assets/marca/`.
- **Passos:**
  1. Ler o `AndroidManifest.xml`, o `web/manifest.json`, o `web/index.html` e
     os recursos gerados.
  2. No aparelho, instalar o app, olhar a gaveta e abrir o app.
- **Resultado esperado:** o nome é "MS Clean" nas três origens; o ícone
  adaptativo do Android usa o símbolo sobre o azul-marinho `#252C67`; a
  abertura usa o mesmo fundo; no aparelho, a gota com o sofá aparece na gaveta
  e o logo completo na abertura.

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

### CT-071 — Fim das telas acima da barra de navegação
- **Requisito:** RNF-001 — "Nenhum botão ou campo fica coberto pela barra de navegação do sistema: o fim de cada tela rolável termina acima dela."
- **Tipo:** Widget · **Situação:** implementado — `barra_do_sistema_test: formulário de atendimento termina acima da barra` · `barra_do_sistema_test: formulário de cliente termina acima da barra`
- **Pré-condições:** tela com uma barra de navegação do sistema simulada de 48 px na base (`MediaQuery.padding.bottom`).
- **Passos:**
  1. Abrir o formulário de atendimento e rolar até o fim.
  2. Abrir o formulário de cliente e rolar até o fim.
- **Resultado esperado:** o botão Salvar fica inteiro acima da barra.

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
| 2026-11-13 | 1.16 | Wilson Gorosthides | CT-049 a CT-052 passam a "implementado" com os testes da entrega do RF-014 (issue #79), em `atendimento_test` e `agenda_screen_test`. |
| 2026-11-16 | 1.17 | Wilson Gorosthides | Casos do RNF-007 ampliado (anotar sem internet, issue #94): CT-053 a CT-058 — abrir com os dados guardados, registro em fila com marca de aguardando envio, envio automático sem duplicar, aviso de sem conexão (bug #47), nada perdido ao reabrir, e item pendente sem edição nem marca. Todos "a implementar". |
| 2026-11-16 | 1.18 | Wilson Gorosthides | CT-053 a CT-058 passam a "implementado" com os testes da entrega do RNF-007 ampliado (issue #94): `espelho_local_test` (oito casos, banco falso e armazenamento em memória), mais os novos casos em `agenda_screen_test` e `home_screen_test`. |
| 2026-11-16 | 1.19 | Wilson Gorosthides | CT-059 do RNF-008 (identidade visual, issue #96): guarda sobre os arquivos de plataforma (nome, ícone adaptativo, cor da abertura) e verificação no aparelho. "A implementar". |
| 2026-11-16 | 1.20 | Wilson Gorosthides | CT-059 passa a "implementado" na guarda `marca_test` (issue #96); a verificação no aparelho vai para a pilha manual. |
| 2026-11-16 | 1.21 | Wilson Gorosthides | Casos do RF-015 (avisos no celular, issue #95): CT-060 a CT-065 — resumo da véspera e do dia, aviso uma hora antes, lembrete de feito e não pago, avisos que acompanham a agenda e toque que abre o dia. Todos "a implementar". |
| 2026-11-16 | 1.22 | Wilson Gorosthides | CT-060 a CT-065 passam a "implementado" com os testes da entrega do RF-015 (issue #95): `avisos_test` (seis casos da função pura `planejarAvisos`) e três casos novos em `agenda_screen_test` com o agendador falso; a chegada real dos avisos vai para a pilha manual. |
| 2026-11-16 | 1.23 | Wilson Gorosthides | CT-066 do RF-015: pedido de liberação da economia de bateria (issue #101). "A implementar". |
| 2026-11-16 | 1.24 | Wilson Gorosthides | CT-066 passa a "implementado" com `bateria_test` (issue #101). |
| 2026-11-16 | 1.25 | Wilson Gorosthides | CT-062 ganha o teste do instante do aviso em qualquer fuso (defeito achado no celular: aviso uma hora atrasado em aparelho com horário de Brasília). |
| 2026-11-16 | 1.26 | Wilson Gorosthides | CT-067 (trocar o dia na edição) e CT-068 (excluir com confirmação) do RF-005, issue #106. "A implementar". |
| 2026-11-16 | 1.27 | Wilson Gorosthides | CT-067 e CT-068 passam a "implementado" (issue #106). |
| 2026-11-17 | 1.28 | Wilson Gorosthides | CT-069 (busca por relevância) e CT-070 (busca sem acento) do RF-004, issue #113. "A implementar". |
| 2026-11-17 | 1.29 | Wilson Gorosthides | CT-069 e CT-070 passam a "implementado" (issue #113). |
| 2026-11-17 | 1.30 | Wilson Gorosthides | CT-071 (fim das telas acima da barra de navegação, RNF-001), issue #118. "A implementar". |
| 2026-11-17 | 1.31 | Wilson Gorosthides | CT-071 passa a "implementado" (issue #118). |
| 2026-11-17 | 1.32 | Wilson Gorosthides | CT-072 a CT-075 do novo RF-016 (cliente dos contatos do celular), issue #115. "A implementar". |
| 2026-11-17 | 1.33 | Wilson Gorosthides | CT-072 a CT-075 passam a "implementado" (issue #115). |
| 2026-11-17 | 1.34 | Wilson Gorosthides | CT-076 a CT-079 do RF-011 (histórico do cliente), issue #81. "A implementar". |
| 2026-11-17 | 1.35 | Wilson Gorosthides | CT-076 a CT-079 passam a "implementado" (issue #81). |
| 2026-11-17 | 1.36 | Wilson Gorosthides | CT-080 a CT-086 do RF-013, parte 1 (tabela de preços), issue #123. "A implementar". |
| 2026-11-17 | 1.37 | Wilson Gorosthides | CT-080 a CT-086 passam a "implementado" (issue #123). |
| 2026-11-17 | 1.38 | Wilson Gorosthides | CT-087 a CT-092 do RF-013, parte 2 (valor calculado no atendimento), issue #124. "A implementar". |
| 2026-11-17 | 1.39 | Wilson Gorosthides | CT-087 a CT-092 passam a "implementado" (issue #124). |
| 2026-11-17 | 1.40 | Wilson Gorosthides | CT-093 a CT-100 do seletor de peças (RF-013, issue #134). "A implementar". |
| 2026-11-17 | 1.41 | Wilson Gorosthides | CT-093 a CT-100 passam a "implementado" (issue #134); CT-043, CT-044 e CT-087 a CT-092 apontam para os testes do seletor e do rodapé que substituíram os da interação anterior. |
| 2026-11-17 | 1.42 | Wilson Gorosthides | CT-101 do RF-005: atendimento rápido, peças e valor em tela própria (issue #134). "A implementar". |
| 2026-11-17 | 1.43 | Wilson Gorosthides | CT-101 passa a "implementado"; CT-097 ganha o teste da tela Peças e valor acima da barra (issue #134). |
| 2026-11-18 | 1.44 | Wilson Gorosthides | Depois do teste no celular (#134): CT-096 (retrátil usa o preço comum), CT-098 (deslocamento liga/desliga) e CT-100 (lista sem retrátil) revistos; CT-102 novo (preço do serviço ajustado só no registro, com justificativa). "A implementar". |
| 2026-11-18 | 1.45 | Wilson Gorosthides | CT-096, CT-098, CT-100 e CT-102 passam a "implementado" (issue #134, ajustes depois do teste no celular). |
| 2026-11-19 | 1.46 | Wilson Gorosthides | Depois do segundo teste no celular (#134): CT-096 e CT-100 revistos, o retrátil passa a ser o preço comum mais um acréscimo. "A implementar". |
| 2026-11-19 | 1.47 | Wilson Gorosthides | CT-096 e CT-100 passam a "implementado" (retrátil como acréscimo, issue #134). |
| 2026-11-19 | 1.48 | Wilson Gorosthides | Depois do terceiro teste no celular (#134): CT-098 revisto, deslocamento em bloco próprio, já incluído, de R$ 1 em R$ 1 ou digitado. "A implementar". |
| 2026-11-19 | 1.49 | Wilson Gorosthides | CT-098 passa a "implementado" (deslocamento em bloco próprio, issue #134). |
| 2026-11-19 | 1.50 | Wilson Gorosthides | CT-103, CT-104 e CT-105 (issue #134): grupos da tabela (produto, mão de obra, imprevisto), produto junto com o serviço da peça e grupo de cada serviço no registro e no rodapé. "A implementar". |
| 2026-11-19 | 1.51 | Wilson Gorosthides | CT-103, CT-104 e CT-105 passam a "implementado" (grupos da tabela e produto junto com o serviço, issue #134). |
| 2026-11-19 | 1.52 | Wilson Gorosthides | CT-106 (issue #141): item avulso pelo nome no resumo das peças, e não "outro". "A implementar". |
| 2026-11-19 | 1.53 | Wilson Gorosthides | CT-106 passa a "implementado" (item avulso pelo nome no resumo, issue #141). |
| 2026-11-17 | 1.36 | Wilson Gorosthides | CT-055 ganha o teste da linha repetida pelo banco (bug #128: atendimento em dobro na agenda). |
