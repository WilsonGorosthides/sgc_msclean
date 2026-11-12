# Regras do projeto — SGC para MSClean

App Flutter + Supabase: a **agenda virtual** da MSClean (higienização de
estofados e tapetes). O produto é o controle diário, semanal e mensal de
clientes e serviços — a agenda é a tela que abre com o app. Cadastro de
clientes, tabela de preços e histórico existem para **apoiar a agenda**
(orçamento e consulta); na dúvida de prioridade ou de navegação, a agenda vence.
Usuária única: a proprietária. Desenvolvedor solo.

## Fontes da verdade (ler antes de mudar qualquer coisa)

- Produto: `docs/requisitos.md` e `docs/arquitetura.md`.
- Visual: `lib/theme/` (fonte canônica dos tokens) e `docs/design-system.md`
  (vista dela).
- Protótipo navegável da agenda: `index.html` na branch `gh-pages`
  (`git show origin/gh-pages:index.html`). Referência de fluxo e layout das
  telas da agenda; em caso de divergência, vale o `docs/requisitos.md`.
- Processo: `docs/gerencia-de-configuracao.md` (GCS) — branches, commits, PRs, DoD.
- Testes: `docs/plano-de-testes.md`, `docs/casos-de-teste.md`,
  `docs/matriz-rastreabilidade.md`, `docs/execucoes-de-testes-manuais.md`.

## Regras de trabalho

- **Nunca commitar direto na `main`** (protegida por ruleset). Branch
  `<tipo>/<descricao-curta>` em kebab-case PT-BR, a partir da `main` atualizada (GCS §4).
- **Commits**: Conventional Commits em PT-BR, **sem acentos** na mensagem, um
  commit por passo lógico (GCS §5).
- **Teste-antes**: commit do teste vermelho separado do commit da implementação
  verde (plano de testes §9). Os CTs de `docs/casos-de-teste.md` são o roteiro.
- **RF ainda sem CT**: o primeiro commit do PR é `docs:` com os CTs do RF em
  `docs/casos-de-teste.md` e as linhas na matriz ("a implementar"), antes do
  `test:` vermelho.
- **Sem cor literal nas telas**: `lib/screens/` usa o tema ou `AppColors`; a
  guarda `test/unit/design_system_test.dart` reprova `Color(0x...)` e `Colors.*`.
  Espaçamento e raio saem de `AppSpacing`/`AppRadius`.
- **Schema do banco é aplicado pelo desenvolvedor**: não há pasta de migrations
  e o agente não altera o Supabase. Toda mudança de schema ou de RLS vai como
  SQL no corpo do PR e em `docs/arquitetura.md` §4; o desenvolvedor roda no
  painel antes da verificação manual.
- **Gate local antes do push (do desenvolvedor)**: a suíte completa
  (`fvm flutter test`) e o `fvm flutter analyze` são executados pelo
  **desenvolvedor** antes de autorizar o push; o agente roda apenas testes
  **direcionados** ao(s) arquivo(s) da feature durante o desenvolvimento, para
  verificar o red→green. Usar sempre `fvm flutter`, nunca `flutter` direto.
- **Parar antes do push** e aguardar a revisão humana do desenvolvedor, salvo
  instrução explícita em contrário na tarefa.
- **PR**: título `pr(<tipo>): ...`, corpo no template da GCS §6, `Closes #N` fora
  de backticks. Merge por merge commit; branch deletada depois.
- **Docs sincronizados** no mesmo PR + linha nova no Histórico de Versões de cada
  doc tocado (GCS §8).
- **Credenciais**: nunca ler ou expor valores do `.env` (gitignored); o
  `.env.example` (valores fictícios) é o versionado.

## Pegadinhas recorrentes

- `fvm flutter pub get`/`test` reescreve arquivos gerados em `linux/`, `macos/` e
  `windows/` (ruído de EOL). Antes de commitar: `git checkout -- linux/ macos/ windows/`.
- O projeto Supabase (plano gratuito) **pausa após cerca de uma semana sem
  uso**; a retomada é manual, pelo painel. Se o app não carregar dados depois de
  um período parado, conferir isso antes de procurar bug no código.
- Commits `test:` vermelhos quebram a build de propósito — é o rastro do
  teste-antes no histórico (plano de testes §9), não descuido. Se um dia um
  `git bisect` cair num commit vermelho, usar `git bisect skip` e seguir a busca.
