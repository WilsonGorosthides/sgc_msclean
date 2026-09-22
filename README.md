# SGC para MSClean

> **Status:** MVP em andamento. A gestão de clientes está entregue; a **agenda de atendimentos** está especificada e em validação com a proprietária. As duas fazem parte do MVP.
>
> **Protótipo navegável:** **[wilsongorosthides.github.io/sgc_msclean](https://wilsongorosthides.github.io/sgc_msclean/)** — o fluxo da agenda, clicável, com dados fictícios. Não é o aplicativo: existe para validar as decisões de requisito com a usuária real antes de escrever código.

## 📝 Descrição do Projeto
O SGC para a MSClean é o aplicativo que substitui a **agenda de papel** de uma empresa de higienização de estofados e tapetes. A proprietária anota cada atendimento num caderno — dia, cliente, endereço e as peças do serviço — enquanto o valor combinado fica espalhado em conversas de WhatsApp e Instagram.

O projeto nasceu como um cadastro de clientes. Um levantamento de campo em 2026-09-10 — entrevista somada à fotografia das páginas reais do caderno — mostrou que organizar contatos não era a dor: a dor é a **lacuna de transcrição** entre onde o preço é combinado e onde a data é anotada, e foi dessa lacuna que veio o agendamento duplicado relatado pela proprietária. O centro do produto passou a ser a **agenda por data**, com o cadastro de clientes servindo de apoio a ela. O registro completo está em [`docs/requisitos.md`](./docs/requisitos.md) §2.2.

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
- [`execucoes-de-testes-manuais.md`](./docs/execucoes-de-testes-manuais.md) — registro das rodadas de testes manuais (data, ambiente, resultados por CT e issues abertas).

## ✅ Status do MVP

**Gestão de clientes** — entregue

- [x] Listagem de clientes
- [x] Busca por palavra-chave
- [x] Cadastro
- [x] Edição
- [x] Exclusão

**Agenda de atendimentos** — especificada, ainda não implementada

- [ ] Agenda por data, abrindo no dia de hoje (RF-010)
- [ ] Registrar atendimento com período, cliente e peças do serviço (RF-005)
- [ ] Histórico do cliente: quanto foi cobrado e quando foi a última visita (RF-011)
- [ ] Aviso de conflito de horário (RF-012)
- [ ] Tabela de preços e cálculo por metragem (RF-013)
- [ ] Serviço feito e cliente pagou, como estados independentes (RF-014)

## 📈 Roadmap
- **Fase 1 — Clientes:** listagem, busca, cadastro, edição e exclusão. ✅
- **Fase 2 — Agenda:** os seis requisitos acima (RF-005 e RF-010 a RF-014). Prioridade definida pelo levantamento de campo com a proprietária em 2026-09-10 — ver "Origem" em [`docs/requisitos.md`](./docs/requisitos.md) §2.2. **As Fases 1 e 2 juntas formam o MVP.**
- **Fase 3:** autenticação de usuário (RF-007) — passa a ser necessária quando a agenda concentrar dados de atendimento, e não apenas contatos.
- **Fase 4:** histórico de pagamentos (RF-006, não priorizado) e melhorias — busca server-side, filtros avançados, refinamentos da versão desktop.

## 📌 Requisitos do Sistema
O MVP cobre duas frentes: a gestão de clientes (cadastro, edição, listagem, busca e exclusão — entregue) e a agenda de atendimentos por data (RF-005 e RF-010 a RF-014 — especificada). Histórico de pagamentos e autenticação ficam para depois do MVP. A especificação completa — requisitos funcionais, não funcionais e critérios de aceitação — está em [`docs/requisitos.md`](./docs/requisitos.md), que é a fonte da verdade.

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
git clone https://github.com/WilsonGorosthides/sgc_msclean.git
cd sgc_msclean
fvm use                                 # baixa a versão do .fvmrc
cp .env.example .env                    # preencha SUPABASE_URL e SUPABASE_ANON_KEY
fvm flutter pub get
fvm flutter run -d chrome
```

> **Pré-requisito:** um projeto **Supabase** com a tabela `clientes` e RLS configurados — schema em [`docs/arquitetura.md`](./docs/arquitetura.md).

## 📜 Licença
Este projeto está licenciado sob a licença MIT — ver [`LICENSE`](./LICENSE).
