# Documento de Requisitos de Software (DRS) - SGC para MSClean

## 1. Introdução

Este documento detalha os requisitos funcionais e não funcionais do Sistema de Gestão de Clientes (SGC) da MSClean. Serve de guia para as fases de design, desenvolvimento e teste.

Decisões históricas de escopo e priorização estão registradas em `docs/AUDITORIA_INICIAL.md`.

Cada requisito funcional é acompanhado de critérios de aceitação verificáveis
(bullets objetivos, passíveis de teste).

Cada RF com História de Usuário escrita (seção 4) pode ser rastreado no GitHub como
uma issue **Story** (label `story`) que agrega a(s) issue(s) `feat` de implementação
como sub-issues nativas — ver `docs/gerencia-de-configuracao.md` §7.

## 2. Requisitos Funcionais (RFs)

### 2.1 Gestão de Clientes

#### RF-001 - Cadastro de Cliente
O sistema deve permitir o cadastro de novos clientes.

* **Dados:** Nome, Endereço (estruturado: logradouro, número, bairro, complemento, ponto de referência), Telefone(s).
* **Critérios de aceitação:**
  - Nome e **ao menos um Telefone** são obrigatórios. Endereço é **opcional** (um cliente em potencial pode ser cadastrado antes de ter endereço).
  - Ao tentar salvar com Nome ou Telefone vazio (ou só com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem indicando o(s) campo(s) pendente(s).
  - O **Endereço é estruturado** em campos: logradouro (rua/avenida), número, bairro, complemento (bloco, apto, torre) e ponto de referência. Todos os campos são opcionais. Não há campo de cidade: a área de atendimento é só Campo Grande - MS (a cidade entra como âncora fixa na consulta ao mapa; reavaliar se a área mudar).
  - Ao salvar **sem endereço** (nenhum campo do endereço preenchido), o sistema pede confirmação ("Cliente sem endereço. Deseja salvar mesmo assim?"); ao confirmar, grava; ao cancelar, permanece no formulário.
  - O cliente pode ter **um ou mais telefones**: o formulário permite adicionar e remover campos de telefone (mínimo um), e cada número é validado individualmente.
  - Cada Telefone aceita apenas dígitos, espaços e os símbolos `+ ( ) -`; outros caracteres são rejeitados na validação.
  - Cada Telefone deve conter no mínimo **8 dígitos**; apenas dígitos contam na verificação (espaços e os símbolos `+ ( ) -` são ignorados na contagem).
  - Após salvar com sucesso, o novo cliente aparece na lista sem necessidade de recarregar a tela (atualização em tempo real via stream).
  - Após salvar, o formulário é fechado e o usuário retorna à lista.

#### RF-002 - Edição de Cliente
O usuário deve ser capaz de editar as informações de um cliente existente.

* **Critérios de aceitação:**
  - O formulário de edição abre pré-preenchido com os dados atuais do cliente.
  - As mesmas validações do cadastro (RF-001) se aplicam: campos obrigatórios e formato de telefone.
  - Uma edição só é considerada salva após o usuário confirmar; nesse momento os dados são persistidos no banco e refletidos na lista imediatamente ao retornar do formulário.
  - Ao cancelar, nenhuma alteração é gravada e os dados originais do cliente permanecem intactos.

#### RF-003 - Visualização da Lista
O sistema deve exibir uma lista de todos os clientes cadastrados.

* **Critérios de aceitação:**
  - A lista é ordenada por Nome em ordem alfabética crescente (ordenação padrão).
  - Cada item exibe, no mínimo, Nome e um resumo do endereço (logradouro, número — bairro); quando o cliente não tem endereço, um texto discreto "Sem endereço" ocupa o lugar.
  - A lista reflete inserções, edições e exclusões em tempo real (stream), sem ação manual de atualização.
  - Quando não há nenhum cliente cadastrado, a tela exibe a mensagem "Nenhum cliente encontrado." em vez de uma lista vazia silenciosa.

#### RF-004 - Busca
O sistema deve permitir a busca de clientes por palavra-chave.

* **Critérios de aceitação:**
  - A busca filtra por **Nome** ou por **qualquer campo do Endereço** (logradouro, número, bairro, complemento, referência) — correspondência de substring.
  - A busca é **case-insensitive** (não diferencia maiúsculas de minúsculas).
  - A lista é filtrada em tempo real conforme o usuário digita, sem necessidade de botão "buscar".
  - Quando nenhum cliente corresponde ao termo, a tela exibe a mensagem "Nenhum cliente encontrado.".
  - Com o campo de busca vazio, todos os clientes são exibidos.

#### RF-008 - Exclusão de Cliente
O sistema deve permitir excluir um cliente existente.

* **Critérios de aceitação:**
  - A exclusão exige confirmação explícita do usuário (diálogo "Confirmar exclusão?") antes de efetivar.
  - Ao cancelar a confirmação, o cliente **não** é removido e permanece na lista.
  - Ao confirmar, o cliente é removido do banco e desaparece da lista imediatamente após a confirmação.
  - Após a exclusão bem-sucedida, o sistema dá feedback visual (ex.: SnackBar "Cliente excluído").

#### RF-009 - Abrir Endereço no Mapa
O sistema deve permitir abrir o endereço de um cliente no Google Maps.

* **Critérios de aceitação:**
  - A partir de um cliente **com endereço**, uma ação (ícone de mapa no item da lista) abre o endereço no Google Maps.
  - A consulta ao mapa usa os campos de "chegar" (logradouro, número, bairro) com **Campo Grande - MS** como âncora fixa; complemento e ponto de referência não entram (atrapalham a geolocalização).
  - Quando o cliente **não tem endereço**, a ação não é exibida.

#### RF-005 - Adicionar Histórico de Serviço
Para cada cliente, o usuário deve poder adicionar um registro de serviço.

* **Dados:** Data, Descrição do Serviço, Valor do Serviço.

#### RF-006 - Adicionar Histórico de Pagamento
Para cada cliente, o usuário deve poder adicionar um registro de pagamento.

* **Dados:** Data, Valor Pago, Método de Pagamento (ex.: Pix, Dinheiro).

#### RF-007 - Autenticação de Usuário Único
O sistema deve ter um mecanismo de login para o único usuário (a proprietária da empresa).

* **Nota:** A usuária é única no próprio dispositivo; o controle de acesso é exercido por RLS no Supabase (ver RNF-005).

## 3. Requisitos Não Funcionais (RNFs)

* **RNF-001 - Usabilidade:** Todas as ações principais (cadastrar, buscar, editar, excluir) devem ser alcançáveis em no máximo 2 toques a partir da tela inicial, sem necessidade de treinamento prévio.
* **RNF-002 - Desempenho:** Operações de busca, cadastro, edição e exclusão devem responder em menos de 2 segundos para uma base de até 500 clientes, em uso por um único usuário.
* **RNF-003 - Compatibilidade de Plataforma:** A aplicação deve compilar e funcionar a partir de um único código-fonte Flutter em **Android** e em **navegadores web (desktop)**.
* **RNF-004 - Sincronização de Dados:** Os dados gravados em uma plataforma devem aparecer na outra sem ação manual de atualização, por meio da stream em tempo real do Supabase (latência típica inferior a 2 segundos).
* **RNF-005 - Segurança:** O acesso ao banco deve ser controlado por **Row Level Security (RLS)** no Supabase; no cliente expõe-se apenas a `anonKey` pública. As credenciais (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) são carregadas de um arquivo `.env` fora do controle de versão, e um `.env.example` documenta as chaves esperadas.

## 4. Histórias de Usuário (User Stories)

* **História 1: Adicionar um Cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** um botão para adicionar um novo cliente,
    * **Para que** eu possa registrar as informações de contato de forma organizada.
* **História 2: Encontrar um Cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** uma barra de busca na lista de clientes,
    * **Para que** eu possa encontrar rapidamente o cliente que preciso.
* **História 3: Editar dados de um cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** corrigir informações desatualizadas de um cliente,
    * **Para que** meus contatos estejam sempre certos.
* **História 4: Excluir um cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** remover clientes que não atendo mais,
    * **Para que** minha lista permaneça limpa e relevante.
* **História 5: Registrar um Serviço**
    * **Como** proprietária da empresa,
    * **Eu quero** adicionar um histórico de serviço a um cliente,
    * **Para que** eu possa rastrear os trabalhos realizados.

## 5. Fluxo de Casos de Uso Principal

* **UC-001 - Gerenciar Clientes**
    1.  O usuário abre o aplicativo.
    2.  O sistema exibe a lista de clientes (ordenada por nome).
    3.  **Cenário A - Adicionar:** O usuário clica em "Adicionar Cliente", preenche o formulário e salva. O cliente aparece na lista em tempo real.
    4.  **Cenário B - Buscar:** O usuário digita na barra de busca. A lista é filtrada em tempo real por nome ou endereço.
    5.  **Cenário C - Editar:** O usuário toca em um cliente da lista; o sistema abre o formulário pré-preenchido com os dados atuais. O usuário ajusta os campos necessários e confirma. A alteração aparece na lista em tempo real.
    6.  **Cenário D - Excluir:** O usuário aciona a opção de excluir um cliente; o sistema solicita confirmação explícita. Ao confirmar, o cliente é removido do banco e desaparece da lista em tempo real, com feedback visual ao usuário.
    7.  **Cenário E - Abrir no mapa:** A partir de um cliente com endereço, o usuário toca no ícone de mapa; o sistema abre o endereço no Google Maps na localização.

## 6. Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2025-09-11 | 1.0 | Wilson Gorosthides | Versão inicial dos requisitos. |
| 2026-06-27 | 2.0 | Wilson Gorosthides | Sincronização com a auditoria inicial: stack Supabase, escopo MVP (RF-001 a RF-004 + RF-008), critérios de aceitação verificáveis, RNFs tornados verificáveis, remoção do login do UC-001, RF-005/006/007 e História "Registrar um Serviço" movidos para Pós-MVP; novas histórias de editar e excluir cliente. |
| 2026-06-27 | 2.1 | Wilson Gorosthides | Ajustes no UC-001: remove o Cenário C - Detalhes (não implementado, apenas `print` no código), adiciona Cenário C - Editar e Cenário D - Excluir. |
| 2026-07-03 | 2.2 | Wilson Gorosthides | Adiciona nota em §1 ligando RF → História de Usuário → issue Story e um pointer geral para `docs/AUDITORIA_INICIAL.md`; remove a distinção MVP/Pós-MVP (RF-005/006/007 incorporados à seção 2, História 5 à seção 4, sem tags de status), preservando em RF-007 a nota técnica sobre RLS/RNF-005; Histórico de Versões renumerado de §7 para §6. |
| 2026-07-18 | 2.3 | Wilson Gorosthides | Novo critério de aceitação no RF-001: telefone com no mínimo 8 dígitos, contando apenas dígitos (decisão de requisito da issue #48; piso pode subir para 10 após a importação da agenda real, #23). |
| 2026-07-19 | 2.4 | Wilson Gorosthides | RF-002: critério de reflexo da edição renegociado de "em tempo real" para "imediatamente ao retornar do formulário" — os eventos UPDATE do realtime não são entregues pelo projeto Supabase atual (diagnóstico e caminho de restauração na issue #57). |
| 2026-07-20 | 2.5 | Wilson Gorosthides | RF-008: critério de reflexo da exclusão renegociado de "em tempo real" para "imediatamente após a confirmação" — por consistência com o RF-002 e por robustez, a lista é renovada após a exclusão, independentemente de o evento DELETE nativo do realtime ser entregue (não presumido como quebrado; contexto na issue #57). |
| 2026-07-21 | 2.6 | Wilson Gorosthides | RF-001: Endereço passa a ser **opcional** (com aviso de confirmação ao salvar vazio) — um cliente em potencial pode ser cadastrado sem endereço; preparação para a importação da agenda real (issue #61). |
| 2026-07-21 | 2.7 | Wilson Gorosthides | RF-001: cliente passa a ter **um ou mais telefones** (mínimo um), com campos adicionáveis/removíveis no formulário e validação por número — realidade da agenda real (issue #62). |
| 2026-07-21 | 2.9 | Wilson Gorosthides | Novo **RF-009** — abrir o endereço do cliente no Google Maps (ícone de mapa no item, só quando há endereço; consulta pelos campos de chegar com Campo Grande - MS como âncora); Cenário E no UC-001 (issue #66). |
| 2026-07-21 | 2.8 | Wilson Gorosthides | Endereço passa a ser **estruturado** (logradouro, número, bairro, complemento, ponto de referência), todos opcionais — RF-001 (dados e aviso por endereço vazio), RF-003 (item exibe resumo) e RF-004 (busca por qualquer campo do endereço). Sem campos de CEP e cidade (decisão de simplicidade: na prática não seriam preenchidos; a área de atendimento é só Campo Grande - MS, âncora fixa na consulta ao mapa). Modela casa/apartamento/condomínio e prepara a abertura no mapa (issue #65). Requer migração no Supabase (`endereco` text → jsonb). |
