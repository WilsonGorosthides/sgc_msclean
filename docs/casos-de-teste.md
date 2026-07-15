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
  rastreabilidade; CT-023 é o caso manual de RNF-001.
- Critérios de aceitação são copiados literalmente da matriz.
- Nos CTs automatizados, os "passos" descrevem o que o teste executa; nos
  manuais, o que a pessoa executa.
- CTs automatizados rodam com `fvm flutter test`; os manuais seguem a ordem de
  preferência do `plano-de-testes.md` §2.1 (dispositivo físico da cliente;
  emulador Android/chrome como alternativa).

## RF-001 — Cadastro de Cliente

### CT-001 — Campos obrigatórios do cadastro
- **Critério:** "Nome, Endereço e Telefone são campos obrigatórios."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** formulário de cadastro aberto.
- **Passos:**
  1. Acionar o salvar sem preencher nenhum campo.
- **Resultado esperado:** nenhum dado é enviado ao banco; os três campos são
  apontados como pendentes.

### CT-002 — Bloqueio de salvamento com campo vazio ou só espaços
- **Critério:** "Ao tentar salvar com qualquer campo obrigatório vazio (ou só
  com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem
  indicando o(s) campo(s) pendente(s)."
- **Tipo:** Widget · **Situação:** a implementar
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
- **Tipo:** Unitário (função de validação pura) + Widget · **Situação:** a implementar
- **Pré-condições:** função de validação disponível / formulário aberto.
- **Passos:**
  1. Validar entradas aceitas: `"11 91234-5678"`, `"+55 (11) 91234-5678"`.
  2. Validar entradas rejeitadas: `"11 91234-5678a"`, `"tel: 1234"`, `"12#34"`.
- **Resultado esperado:** as entradas do passo 1 passam; as do passo 2 são
  rejeitadas com mensagem de formato inválido, bloqueando o salvamento.

### CT-004 — Cliente salvo aparece na lista em tempo real
- **Critério:** "Após salvar com sucesso, o novo cliente aparece na lista sem
  necessidade de recarregar a tela (atualização em tempo real via stream)."
- **Tipo:** Widget · **Situação:** a implementar
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

### CT-005 — Formulário fecha após salvar
- **Critério:** "Após salvar, o formulário é fechado e o usuário retorna à
  lista."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** formulário de cadastro aberto com dados válidos.
- **Passos:**
  1. Acionar o salvar com os três campos válidos.
- **Resultado esperado:** o formulário é fechado e a tela da lista volta a ser
  exibida.

## RF-002 — Edição de Cliente

### CT-006 — Formulário de edição pré-preenchido
- **Critério:** "O formulário de edição abre pré-preenchido com os dados
  atuais do cliente."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** cliente existente na lista.
- **Passos:**
  1. Abrir a edição de um cliente da lista.
- **Resultado esperado:** os campos Nome, Endereço e Telefone exibem os
  valores atuais do cliente.

### CT-007 — Edição aplica as validações do cadastro
- **Critério:** "As mesmas validações do cadastro (RF-001) se aplicam: campos
  obrigatórios e formato de telefone."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** formulário de edição aberto e pré-preenchido.
- **Passos:**
  1. Apagar o Nome (deixar vazio) e acionar o salvar.
  2. Restaurar o Nome, inserir caractere inválido no Telefone e acionar o
     salvar.
- **Resultado esperado:** ambos os salvamentos são bloqueados com as mesmas
  mensagens de validação do cadastro (CT-001 a CT-003).

### CT-008 — Edição persiste só após confirmar
- **Critério:** "Uma edição só é considerada salva após o usuário confirmar;
  nesse momento os dados são persistidos no banco e refletidos na lista em
  tempo real."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** formulário de edição aberto e pré-preenchido.
- **Passos:**
  1. Alterar o Endereço.
  2. Confirmar o salvamento.
- **Resultado esperado:** o método de atualização do service é chamado com os
  novos dados apenas na confirmação, e a lista reflete a alteração em tempo
  real (via stream).

### CT-009 — Cancelar edição não grava nada
- **Critério:** "Ao cancelar, nenhuma alteração é gravada e os dados originais
  do cliente permanecem intactos."
- **Tipo:** Widget · **Situação:** a implementar
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
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** cliente existente na lista.
- **Passos:**
  1. Acionar a exclusão de um cliente.
- **Resultado esperado:** um diálogo de confirmação é exibido; nada é removido
  antes da resposta.

### CT-020 — Cancelar confirmação não remove
- **Critério:** "Ao cancelar a confirmação, o cliente **não** é removido e
  permanece na lista."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** diálogo de confirmação de exclusão aberto.
- **Passos:**
  1. Cancelar o diálogo.
- **Resultado esperado:** nenhuma chamada de exclusão ao service; o cliente
  permanece na lista.

### CT-021 — Confirmar remove em tempo real
- **Critério:** "Ao confirmar, o cliente é removido do banco e desaparece da
  lista em tempo real."
- **Tipo:** Widget · **Situação:** a implementar
- **Pré-condições:** diálogo de confirmação de exclusão aberto.
- **Passos:**
  1. Confirmar o diálogo.
  2. Simular a emissão da stream sem o cliente excluído.
- **Resultado esperado:** o método de exclusão do service é chamado com o
  cliente correto; o item desaparece da lista sem ação manual.

### CT-022 — Feedback visual após excluir
- **Critério:** "Após a exclusão bem-sucedida, o sistema dá feedback visual
  (ex.: SnackBar \"Cliente excluído\")."
- **Tipo:** Widget · **Situação:** a implementar
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
