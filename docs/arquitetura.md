# Documento de Arquitetura e Decisões Técnicas - SGC para MSClean

## 1. Introdução
Este documento detalha a arquitetura de software, a stack de tecnologia (conjunto de tecnologias) e as decisões técnicas tomadas para o desenvolvimento do Sistema de Gestão de Clientes (SGC) da MSClean.

## 2. Visão Geral da Arquitetura
O sistema será construído seguindo um modelo **Cliente-Servidor (Backend as a Service)**. A arquitetura se baseia em um front-end multi-plataforma que se comunica com um serviço de backend gerenciado, eliminando a necessidade de construir um servidor customizado.

* **Front-end (Cliente):** Um aplicativo Flutter que roda em Android e na Web.
* **Backend (BaaS):** O Firebase, responsável pela autenticação, banco de dados em tempo real e hospedagem.

**Fluxo de Dados:**
````
[Aplicativo Android / Web] <==> [Firebase] <==> [Firestore Database]

````
## 3. Stack de Tecnologia
-   **Linguagem de Programação:** **Dart**. Por ser a linguagem oficial do Flutter, oferece alta performance e um ecossistema robusto.
-   **Framework Front-end:** **Flutter**. Escolhido por sua capacidade de compilar para múltiplas plataformas a partir de um único código-fonte, acelerando o desenvolvimento e garantindo consistência.
-   **Backend / Banco de Dados:** **Google Firebase**. Utilizado como um BaaS (Backend as a Service) para gerenciar:
    -   **Firestore:** Banco de dados NoSQL flexível e escalável, com suporte nativo para sincronização em tempo real.
    -   **Firebase Authentication:** Para o gerenciamento seguro do login do único usuário.

## 4. Estrutura do Banco de Dados (Firestore)
O banco de dados será organizado em coleções (`collections`).

* **Coleção:** `clientes`
* **Documento:** Cada cliente será um documento único.
* **Campos do Documento (baseado no `client_model.dart`):**
    -   `nomeCompleto` (String)
    -   `endereco` (String)
    -   `telefone` (String)
    -   `historicoServicos` (Array de objetos `Servico`)
    -   `historicoPagamentos` (Array de objetos `Pagamento`)

## 5. Estrutura de Diretórios do Projeto
A organização do código seguirá o padrão:
````

sgc_msclean/
├── lib/
│   ├── main.dart
│   ├── models/           # Classes de dados (ex: Cliente)
│   ├── repositories/     # Lógica de acesso ao banco de dados
│   └── screens/          # Telas da aplicação (UI)
├── docs/                 # Documentação do projeto (este arquivo, requisitos, etc.)
└── test/                 # Testes unitários

````

## 6. Ambiente de Desenvolvimento
Os seguintes softwares são necessários para iniciar o desenvolvimento:
-   Flutter SDK
-   Editor de Código (Visual Studio Code ou Android Studio)
-   Conta no Google Firebase para configurar o projeto.