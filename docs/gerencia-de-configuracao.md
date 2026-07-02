# Gerência de Configuração — SGC para MSClean

> Define como o código, a documentação e os artefatos deste projeto são versionados,
> alterados, revisados e liberados. Cobre o **processo**; requisitos e arquitetura do
> **produto** ficam em `docs/requisitos.md` e `docs/arquitetura.md`.

## 1. Objetivo

Manter toda mudança rastreável, revisável e reversível, com código e documentação
sincronizados. Quando a execução no repositório é feita por ferramentas de IA (ex.:
Claude Code), passa por revisão humana.

## 2. Itens de Configuração (o que é versionado)

São controlados por versão neste repositório:

- **Código-fonte** do app Flutter em `app/sgc_msclean/`.
- **Documentação** em `docs/` (`requisitos.md`, `arquitetura.md`, `AUDITORIA_INICIAL.md`) e este documento.
- **Arquivos de configuração do repositório**: `.gitignore`, `.gitattributes`, `pubspec.yaml`/`pubspec.lock`.
- **Templates** de Pull Request e de issues (em `.github/`).

**Não** são versionados: segredos e credenciais (`.env`, chaves do Supabase),
artefatos de build (`build/`, `.dart_tool/`) e arquivos locais de IDE.

**Nome de arquivo de doc:** kebab-case minúsculo (ex.: `gerencia-de-configuracao.md`).
O legado `AUDITORIA_INICIAL.md` será padronizado nesse formato.

## 3. Repositório

- **Origem:** https://github.com/WilsonGorosthides/sgc_msclean
- **Branch principal:** `main` — sempre estável e liberável; ninguém commita direto nela.
- **Estrutura:**

```
sgc_msclean/
├── app/sgc_msclean/   ← aplicação Flutter
├── docs/              ← documentação técnica e de processo
├── .gitattributes     ← normalização de fim de linha (LF)
└── README.md
```

## 4. Estratégia de Branches

Fluxo **GitHub Flow** (trunk-based): uma `main` sempre liberável e branches curtas
integradas por PR. Toda mudança nasce em uma branch dedicada, criada a partir da
`main` atualizada.

- **Formato:** `<tipo>/<descricao-curta>` em kebab-case e PT-BR.
- **Tipos:** `feat`, `fix`, `refactor`, `docs`, `chore`, `test`.
- **Exemplos:** `feat/rf-001-cadastro-cliente`, `docs/adiciona-gerencia-configuracao`, `chore/normaliza-fim-de-linha`.

## 5. Padrão de Commits

Estilo Conventional Commits, em PT-BR, no presente:

```
<tipo>(<escopo opcional>): <descrição no presente>
```

- **Tipos:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`.
- **Granularidade:** um commit por passo lógico (ex.: o teste em um commit, a implementação em outro).
- **Exemplos:** `test: adiciona testes do RF-001 cadastro`, `feat(cadastro): implementa formulário de cliente`, `chore: adiciona .gitattributes`.

## 6. Pull Requests

- **PR coeso.** Cada PR agrupa mudanças que fazem sentido juntas — uma tarefa ou mais, quando relacionadas. Não misturar mudanças sem relação no mesmo PR.
- **Título:** `pr(<tipo>): descrição breve`.
- **Template do corpo:**

```
## Descrição
[o que foi feito e por quê]

**Principais mudanças:**
- item
- item

## Observações
[opcional]
```

- **Vínculo com issue.** Quando houver issue relacionada, o PR a referencia (ex.: `Closes #7`).
- **Merge:** merge commit — preserva os commits granulares da [§5](#5-padrão-de-commits) na `main`. A branch é deletada após o merge.

## 7. Gestão de Issues e Labels

O backlog conhecido vive como issues no GitHub. Labels em uso:

| Label | Significado |
|---|---|
| `infra` | Infraestrutura e configuração |
| `security` | Segurança |
| `tech-debt` | Dívida técnica registrada |
| `refactor` | Refatoração de código |
| `process` | Processo e metodologia |
| `documentation` | Documentação |
| `bug` | Defeito reportado |

Dívidas técnicas são **registradas como issues**.

## 8. Sincronização Documentação ↔ Código (Princípio nº 1)

Documentação e código devem refletir um ao outro. Regras:

- A documentação é atualizada **antes** de iniciar uma feature, não depois.
- Toda mudança de código declara quais seções de `requisitos.md` e/ou
  `arquitetura.md` mudam junto — ou afirma "nenhuma doc muda", justificando.
- Todo documento técnico tocado ganha uma linha nova na sua tabela de
  **Histórico de Versões**.

## 9. Definição de Pronto (DoD)

Aplica-se a uma feature completa, não a tarefas isoladas. Hoje a unidade é o RF de
`requisitos.md`, onde ficam seus critérios de aceitação (CAs); quando os requisitos
migrarem para Histórias de Usuário (HU), a unidade passa a ser a HU. Uma feature só
é "pronta" quando reúne **todos** os itens:

- [ ] CAs atendidos no código.
- [ ] CAs cobertos por testes que passam (`flutter test`).
- [ ] `flutter analyze` sem erros.
- [ ] Código seguindo as convenções do projeto.
- [ ] Documentação sincronizada (requisitos/arquitetura, quando aplicável).
- [ ] Linha adicionada ao Histórico de Versões do(s) doc(s) tocado(s).
- [ ] Sem código de depuração (ex.: `print()`) no que foi alterado.
- [ ] PR aberto seguindo a [§6](#6-pull-requests).

## 10. Configuração Sensível e Ambiente

- **Credenciais** (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) vivem em `.env`, carregado
  via `flutter_dotenv`. O `.env` está no `.gitignore` — não vai para o repositório.
- Um `.env.example` (sem valores reais) documenta as chaves necessárias.
- **Segurança do backend:** as regras de acesso ao banco são feitas via Row Level
  Security (RLS) no Supabase. Configuração e verificação do RLS são rastreadas em issue própria.

## 11. Ferramentas

Detalhes e justificativas da stack ficam em `arquitetura.md`. Resumo operacional:

- **Linguagem/Framework:** Dart + Flutter (Android e Web).
- **Backend:** Supabase (PostgreSQL gerenciado, realtime, RLS).
- **Controle de versão:** Git + GitHub.
- **Testes:** `flutter_test` (unitário, widget, integração).

## 12. Releases e Versionamento

Versões seguem **Versionamento Semântico** (SemVer) — formato `MAIOR.MENOR.CORREÇÃO`
(ex.: `v1.0.0`), como tag de git na `main`. Enquanto o MVP não fecha, não há tag; a
primeira será `v1.0.0` (MVP completo). A tag é criada manualmente a partir da `main`
liberável.

Isto versiona o **produto**. A versão de cada **documento** é independente e segue a
tabela de Histórico de Versões do próprio doc (1.0, 1.1, ...).

## Histórico de Versões

| Versão | Data | Autor | Mudança |
|---|---|---|---|
| 1.0 | 2026-07-01 | Wilson Gorosthides | Criação do documento de gerência de configuração. |
| 1.1 | 2026-07-02 | Wilson Gorosthides | Adiciona templates de PR e bug; registra label bug. |
