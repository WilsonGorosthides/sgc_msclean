# Documento de Requisitos de Software (DRS) - SGC para MSClean

## 1. Introdução

Este documento detalha os requisitos funcionais e não funcionais do Sistema de Gestão de Clientes (SGC) da MSClean. Serve de guia para as fases de design, desenvolvimento e teste.

O escopo aqui descrito reflete o **MVP** confirmado na auditoria inicial (ver `docs/AUDITORIA_INICIAL.md`): listagem, busca, cadastro, edição e exclusão de clientes. Requisitos fora do MVP — históricos de serviço/pagamento e autenticação — foram movidos para a seção **6. Requisitos Pós-MVP**, com o motivo registrado.

Cada requisito funcional é marcado com **[MVP]** ou **[Pós-MVP]** e acompanhado de critérios de aceitação verificáveis (bullets objetivos, passíveis de teste).

Cada História de Usuário (seção 4) corresponde 1:1 a um RF do MVP e é rastreada no
GitHub como uma issue **Story** (label `story`), unidade de planejamento que agrega
a(s) issue(s) `feat` de implementação como sub-issues nativas — ver
`docs/gerencia-de-configuracao.md` §7.

## 2. Requisitos Funcionais (RFs)

### 2.1 Gestão de Clientes

#### RF-001 - Cadastro de Cliente **[MVP]**
O sistema deve permitir o cadastro de novos clientes.

* **Dados:** Nome, Endereço, Telefone.
* **Critérios de aceitação:**
  - Nome, Endereço e Telefone são campos obrigatórios.
  - Ao tentar salvar com qualquer campo obrigatório vazio (ou só com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem indicando o(s) campo(s) pendente(s).
  - O Telefone aceita apenas dígitos, espaços e os símbolos `+ ( ) -`; outros caracteres são rejeitados na validação.
  - Após salvar com sucesso, o novo cliente aparece na lista sem necessidade de recarregar a tela (atualização em tempo real via stream).
  - Após salvar, o formulário é fechado e o usuário retorna à lista.

#### RF-002 - Edição de Cliente **[MVP]**
O usuário deve ser capaz de editar as informações de um cliente existente.

* **Critérios de aceitação:**
  - O formulário de edição abre pré-preenchido com os dados atuais do cliente.
  - As mesmas validações do cadastro (RF-001) se aplicam: campos obrigatórios e formato de telefone.
  - Uma edição só é considerada salva após o usuário confirmar; nesse momento os dados são persistidos no banco e refletidos na lista em tempo real.
  - Ao cancelar, nenhuma alteração é gravada e os dados originais do cliente permanecem intactos.

#### RF-003 - Visualização da Lista **[MVP]**
O sistema deve exibir uma lista de todos os clientes cadastrados.

* **Critérios de aceitação:**
  - A lista é ordenada por Nome em ordem alfabética crescente (ordenação padrão).
  - Cada item exibe, no mínimo, Nome e Endereço.
  - A lista reflete inserções, edições e exclusões em tempo real (stream), sem ação manual de atualização.
  - Quando não há nenhum cliente cadastrado, a tela exibe a mensagem "Nenhum cliente encontrado." em vez de uma lista vazia silenciosa.

#### RF-004 - Busca **[MVP]**
O sistema deve permitir a busca de clientes por palavra-chave.

* **Critérios de aceitação:**
  - A busca filtra por **Nome** ou **Endereço** (correspondência de substring).
  - A busca é **case-insensitive** (não diferencia maiúsculas de minúsculas).
  - A lista é filtrada em tempo real conforme o usuário digita, sem necessidade de botão "buscar".
  - Quando nenhum cliente corresponde ao termo, a tela exibe a mensagem "Nenhum cliente encontrado.".
  - Com o campo de busca vazio, todos os clientes são exibidos.

#### RF-008 - Exclusão de Cliente **[MVP]**
O sistema deve permitir excluir um cliente existente.

* **Critérios de aceitação:**
  - A exclusão exige confirmação explícita do usuário (diálogo "Confirmar exclusão?") antes de efetivar.
  - Ao cancelar a confirmação, o cliente **não** é removido e permanece na lista.
  - Ao confirmar, o cliente é removido do banco e desaparece da lista em tempo real.
  - Após a exclusão bem-sucedida, o sistema dá feedback visual (ex.: SnackBar "Cliente excluído").

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

## 5. Fluxo de Casos de Uso Principal

* **UC-001 - Gerenciar Clientes**
    1.  O usuário abre o aplicativo.
    2.  O sistema exibe a lista de clientes (ordenada por nome).
    3.  **Cenário A - Adicionar:** O usuário clica em "Adicionar Cliente", preenche o formulário e salva. O cliente aparece na lista em tempo real.
    4.  **Cenário B - Buscar:** O usuário digita na barra de busca. A lista é filtrada em tempo real por nome ou endereço.
    5.  **Cenário C - Editar:** O usuário toca em um cliente da lista; o sistema abre o formulário pré-preenchido com os dados atuais. O usuário ajusta os campos necessários e confirma. A alteração aparece na lista em tempo real.
    6.  **Cenário D - Excluir:** O usuário aciona a opção de excluir um cliente; o sistema solicita confirmação explícita. Ao confirmar, o cliente é removido do banco e desaparece da lista em tempo real, com feedback visual ao usuário.

## 6. Requisitos Pós-MVP

Os requisitos abaixo foram **movidos para o pós-MVP por decisão de escopo registrada em `docs/AUDITORIA_INICIAL.md`** (seção 5 — Decisões Tomadas). Permanecem aqui como referência de roadmap, mas estão fora do MVP atual.

#### RF-005 - Adicionar Histórico de Serviço **[Pós-MVP]**
Para cada cliente, o usuário deve poder adicionar um registro de serviço.

* **Dados:** Data, Descrição do Serviço, Valor do Serviço.
* **Nota:** Movido para pós-MVP por decisão de escopo registrada em `docs/AUDITORIA_INICIAL.md`.

#### RF-006 - Adicionar Histórico de Pagamento **[Pós-MVP]**
Para cada cliente, o usuário deve poder adicionar um registro de pagamento.

* **Dados:** Data, Valor Pago, Método de Pagamento (ex.: Pix, Dinheiro).
* **Nota:** Movido para pós-MVP por decisão de escopo registrada em `docs/AUDITORIA_INICIAL.md`.

#### RF-007 - Autenticação de Usuário Único **[Pós-MVP]**
O sistema deve ter um mecanismo de login para o único usuário (a proprietária da empresa).

* **Nota:** Movido para pós-MVP por decisão de escopo registrada em `docs/AUDITORIA_INICIAL.md`. No MVP, a usuária é única no próprio dispositivo e o controle de segurança é exercido por RLS no Supabase (ver RNF-005).

### História de Usuário Pós-MVP

* **História 5: Registrar um Serviço** *(Pós-MVP)*
    * **Como** proprietária da empresa,
    * **Eu quero** adicionar um histórico de serviço a um cliente,
    * **Para que** eu possa rastrear os trabalhos realizados.
    * **Nota:** Movida para pós-MVP por decisão de escopo registrada em `docs/AUDITORIA_INICIAL.md`.

## 7. Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2025-09-11 | 1.0 | Wilson Gorosthides | Versão inicial dos requisitos. |
| 2026-06-27 | 2.0 | Wilson Gorosthides | Sincronização com a auditoria inicial: stack Supabase, escopo MVP (RF-001 a RF-004 + RF-008), critérios de aceitação verificáveis, RNFs tornados verificáveis, remoção do login do UC-001, RF-005/006/007 e História "Registrar um Serviço" movidos para Pós-MVP; novas histórias de editar e excluir cliente. |
| 2026-06-27 | 2.1 | Wilson Gorosthides | Ajustes no UC-001: remove o Cenário C - Detalhes (não implementado, apenas `print` no código), adiciona Cenário C - Editar e Cenário D - Excluir. |
| 2026-07-03 | 2.2 | Wilson Gorosthides | Adiciona nota em §1 ligando RF → História de Usuário → issue Story no rastreamento do GitHub. |
