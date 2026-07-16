# SGC para MSClean

> **Status:** 🚧 Em desenvolvimento — MVP em construção (listagem e busca prontas).

## 📝 Descrição do Projeto
O Sistema de Gestão de Clientes (SGC) para a MSClean é uma aplicação desenvolvida para resolver o desafio de gerenciamento manual de uma base de clientes em rápido crescimento. Centraliza as informações de contato dos clientes, permitindo que a proprietária da empresa tenha controle organizado e eficiente do seu negócio.

## 🎯 Objetivo de Negócio
Substituir o gerenciamento manual (WhatsApp, planilhas, etc.) por uma ferramenta digital simples e intuitiva, garantindo organização, agilidade e profissionalismo no dia a dia da MSClean.

## 🚀 Metodologia
Este projeto segue a metodologia **Ágil (Scrum Simplificado)**, permitindo entregas rápidas de funcionalidades e ajustes contínuos com base no feedback da proprietária.

## 📚 Documentação Técnica
A documentação detalhada do projeto vive na pasta [`docs/`](./docs):

- [`AUDITORIA_INICIAL.md`](./docs/AUDITORIA_INICIAL.md) — diagnóstico do estado real do projeto e decisões de escopo.
- [`requisitos.md`](./docs/requisitos.md) — requisitos funcionais e não funcionais (fonte da verdade).
- [`arquitetura.md`](./docs/arquitetura.md) — arquitetura, stack e decisões técnicas (fonte da verdade).
- [`plano-de-testes.md`](./docs/plano-de-testes.md) — estratégia de testes, níveis e fluxo de execução do MVP.
- [`matriz-rastreabilidade.md`](./docs/matriz-rastreabilidade.md) — matriz RF ↔ critério de aceitação ↔ caso de teste do MVP.
- [`casos-de-teste.md`](./docs/casos-de-teste.md) — casos de teste formais do MVP (CTs numerados com passos e resultado esperado).

## ✅ Status do MVP
- [x] Listagem de clientes
- [x] Busca por palavra-chave
- [x] Cadastro
- [ ] Edição
- [ ] Exclusão

## 📈 Roadmap
- **Fase 1 (MVP):** listagem, busca, cadastro, edição e exclusão de clientes.
- **Fase 2 (Pós-MVP):** histórico de serviços, histórico de pagamentos e autenticação de usuário (ver RF-005 a RF-007 em [`docs/requisitos.md`](./docs/requisitos.md)).
- **Fase 3:** melhorias futuras — busca server-side, filtros avançados e refinamentos da versão desktop.

## 📌 Requisitos do Sistema
O escopo cobre cadastro, edição, listagem, busca e exclusão de clientes (MVP), com históricos e autenticação previstos para o Pós-MVP. A especificação completa — requisitos funcionais, não funcionais e critérios de aceitação — está em [`docs/requisitos.md`](./docs/requisitos.md), que é a fonte da verdade.

## ⚙️ Arquitetura e Tecnologia
Arquitetura Cliente-Servidor com um BaaS (Backend as a Service):

* **Linguagem:** `Dart`
* **Framework:** `Flutter` (para Android e Web)
* **Backend & DB:** `Supabase` (PostgreSQL gerenciado, realtime e Row Level Security)

Detalhes de decisões técnicas, fluxo de dados e diagrama de componentes em [`docs/arquitetura.md`](./docs/arquitetura.md).

## 📁 Estrutura do Projeto
````
sgc_msclean/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── client_model.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   └── client_form_screen.dart
│   ├── services/
│   │   └── supabase_service.dart
│   └── utils/
│       └── validators.dart
├── test/
└── docs/
````

## 🛠️ Como Instalar e Executar
O Flutter é fixado via **[FVM](https://fvm.app/)** (`.fvmrc`: Flutter 3.35.0 / Dart 3.9.0). Use sempre `fvm flutter`.

```bash
dart pub global activate fvm            # instala o FVM
git clone https://github.com/seu-usuario/sgc_msclean.git
cd sgc_msclean
fvm use                                 # baixa a versão do .fvmrc
cp .env.example .env                    # preencha SUPABASE_URL e SUPABASE_ANON_KEY
fvm flutter pub get
fvm flutter run -d chrome
```

> **Pré-requisito:** um projeto **Supabase** com a tabela `clientes` e RLS configurados — schema em [`docs/arquitetura.md`](./docs/arquitetura.md).

## 📜 Licença
Este projeto está licenciado sob a licença [MIT](https://opensource.org/licenses/MIT).
