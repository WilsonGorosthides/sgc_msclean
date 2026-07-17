# Regras do projeto — SGC para MSClean

App Flutter + Supabase de gestão de clientes da MSClean (empresa de limpeza).
Usuária única: a proprietária. Desenvolvedor solo.

## Fontes da verdade (ler antes de mudar qualquer coisa)

- Produto: `docs/requisitos.md` e `docs/arquitetura.md`.
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
- **Gate local antes de qualquer push**: `fvm flutter test` e
  `fvm flutter analyze` verdes. Usar sempre `fvm flutter`, nunca `flutter` direto.
- **Parar antes do push** e aguardar a revisão humana do desenvolvedor, salvo
  instrução explícita em contrário na tarefa.
- **PR**: título `pr(<tipo>): ...`, corpo no template da GCS §6, `Closes #N` fora
  de backticks. Merge por merge commit; branch deletada depois.
- **Docs sincronizados** no mesmo PR + linha nova no Histórico de Versões de cada
  doc tocado (GCS §8).
- **Credenciais**: nunca ler ou expor valores do `.env` (gitignored); o
  `.env.example` (valores fictícios) é o versionado.

## Pegadinha recorrente

`fvm flutter pub get`/`test` reescreve arquivos gerados em `linux/`, `macos/` e
`windows/` (ruído de EOL). Antes de commitar: `git checkout -- linux/ macos/ windows/`.
