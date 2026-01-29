# Documento de Arquitetura e Decisões Técnicas - SGC para MSClean

## 1. Introdução
Este documento detalha a arquitetura de software e as decisões técnicas para o desenvolvimento do SGC da MSClean, focando em velocidade de entrega e manipulação de dados.

## 2. Visão Geral da Arquitetura
O sistema utiliza o modelo **Cliente-Servidor (BaaS)**. O front-end Flutter comunica-se diretamente com o Supabase, eliminando a necessidade de um backend intermediário customizado.

* **Front-end:** App Flutter para Android e Web.
* **Backend (BaaS):** Supabase, provendo banco de dados relacional e autenticação.

**Fluxo de Dados:**
````
[App Flutter] <==> [Supabase API] <==> [PostgreSQL Database]

````
## 3. Stack de Tecnologia
- **Linguagem:** **Dart**.
- **Framework:** **Flutter**. Escolhido pela agilidade e consistência visual entre Android e Web.
- **Backend/Banco:** **Supabase**. Escolhido pela facilidade de inserção massiva de dados via SQL/Dashboard e estrutura relacional (PostgreSQL).

## 4. Estrutura do Banco de Dados (PostgreSQL)
O banco será organizado em tabelas relacionais:

* **Tabela `clientes`:**
    - `id` (uuid, PK)
    - `nome` (text)
    - `endereco` (text)
    - `telefone` (text)
* **Tabela `registros`:**
    - `id` (uuid, PK)
    - `cliente_id` (uuid, FK)
    - `tipo` (text: 'Serviço' ou 'Pagamento')
    - `descricao` (text)
    - `valor` (numeric)
    - `data` (timestamp)

## 5. Estrutura de Diretórios
A organização do código seguirá o padrão:
````

sgc_msclean/
├── lib/
│   ├── main.dart
│   ├── core/             # Cores (Dark Theme) e constantes da API
│   ├── models/           # ClientModel e RecordModel
│   ├── services/         # Lógica do Supabase (Substitui repositories)
│   ├── screens/          # Subpastas: home, details, form
│   └── widgets/          # Componentes reutilizáveis (Ex: CustomTextField)
├── docs/                 # Documentação (DRS e Arquitetura)
└── test/

````

## 6. Ambiente de Desenvolvimento
- Flutter SDK.
- VS Code / Android Studio.
- Projeto configurado no Supabase Dashboard.