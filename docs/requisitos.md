# Documento de Requisitos de Software (DRS) - SGC para MSClean

## 1. Introdução

Este documento detalha os requisitos funcionais e não funcionais para o Sistema de Gestão de Clientes (SGC) da MSClean. Guia  das fases de design, desenvolvimento e teste.

## 2. Requisitos Funcionais (RFs)

### 2.1 Gestão de Clientes
* **RF-001 - Cadastro de Cliente:** O sistema deve permitir o cadastro de novos clientes.
    * **Dados:** Nome Completo, Endereço (completo), Telefone.
* **RF-002 - Edição de Cliente:** O usuário deve ser capaz de editar as informações de um cliente existente.
* **RF-003 - Visualização da Lista:** O sistema deve exibir uma lista de todos os clientes cadastrados.
* **RF-004 - Busca:** O sistema deve permitir a busca de clientes usando palavras-chave (ex: nome, endereço).

### 2.2 Gestão de Histórico
* **RF-005 - Adicionar Histórico de Serviço:** Para cada cliente, o usuário deve poder adicionar um registro de serviço.
    * **Dados:** Data, Descrição do Serviço, Valor do Serviço.
* **RF-006 - Adicionar Histórico de Pagamento:** Para cada cliente, o usuário deve poder adicionar um registro de pagamento.
    * **Dados:** Data, Valor Pago, Método de Pagamento (ex: Pix, Dinheiro).

### 2.3 Segurança
* **RF-007 - Autenticação de Usuário Único:** O sistema deve ter um mecanismo de login para o único usuário (a proprietária da empresa).

## 3. Requisitos Não Funcionais (RNFs)

* **RNF-001 - Usabilidade:** A interface do usuário deve ser simples, intuitiva e exigir o mínimo de treinamento para uso.
* **RNF-002 - Desempenho:** O sistema deve ter um tempo de resposta aceitável para um único usuário (inferior a 2 segundos em operações de busca e cadastro).
* **RNF-003 - Compatibilidade de Plataforma:** A aplicação deve ser totalmente funcional em dispositivos **Android** e em **navegadores web (desktop)**.
* **RNF-004 - Sincronização de Dados:** Os dados cadastrados em uma plataforma devem ser instantaneamente sincronizados e acessíveis na outra.
* **RNF-005 - Segurança:** Os dados do cliente devem ser armazenados de forma segura em um banco de dados online.

## 4. Histórias de Usuário (User Stories)

* **História 1: Adicionar um Cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** um botão para adicionar um novo cliente,
    * **Para que** eu possa registrar as informações de contato de forma organizada.
* **História 2: Encontrar um Cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** uma barra de busca na lista de clientes,
    * **Para que** eu possa encontrar rapidamente o cliente que preciso.
* **História 3: Registrar um Serviço**
    * **Como** proprietária da empresa,
    * **Eu quero** adicionar um histórico de serviço a um cliente,
    * **Para que** eu possa rastrear os trabalhos realizados.

## 5. Fluxo de Casos de Uso Principal

* **UC-001 - Gerenciar Clientes**
    1.  O usuário abre o aplicativo e faz login.
    2.  O sistema exibe a lista de clientes.
    3.  **Cenário A - Adicionar:** O usuário clica em "Adicionar Cliente", preenche o formulário e salva.
    4.  **Cenário B - Buscar:** O usuário digita na barra de busca. A lista é filtrada em tempo real.
    5.  **Cenário C - Detalhes:** O usuário clica em um cliente da lista para ver seus detalhes.

---

