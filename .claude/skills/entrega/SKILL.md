---
name: entrega
description: Fluxo GCS completo de entrega de uma issue - branch, teste-antes, commits granulares, parada para revisao humana, push + PR com CI verde. Uso - /entrega <numero-da-issue>
---

# Entrega de uma issue (fluxo GCS)

Executa a entrega completa de uma issue seguindo `docs/gerencia-de-configuracao.md`
e `docs/plano-de-testes.md` §9. Regras de commit e código valem conforme o
`CLAUDE.md` da raiz — não repetidas aqui.

## Entrada

Número da issue (ex.: `/entrega 26`). Sem número, perguntar qual issue entregar.

## Passos

1. **Entender a issue.** `gh issue view <N>` (corpo e comentários). Se for RF:
   localizar os critérios de aceitação em `docs/requisitos.md` §2 e os CT-IDs
   correspondentes em `docs/matriz-rastreabilidade.md` e `docs/casos-de-teste.md`
   — eles são o roteiro dos testes. Resumir o plano de entrega em 3–5 linhas para
   o desenvolvedor antes de começar.
2. **Branch.** `main` atualizada (`git checkout main && git pull`) → branch
   `<tipo>/<descricao-curta>` (GCS §4).
3. **Teste-antes (quando há código).** Commit(s) `test:` com a suíte **vermelha**
   descrevendo o comportamento esperado (nomes dos testes = nomes da matriz);
   depois commit(s) `feat:`/`fix:` da implementação até o **verde**. Docs
   sincronizados (GCS §8) em commits `docs:` próprios, incluindo a linha no
   Histórico de Versões de cada doc tocado e a atualização da matriz
   ("a implementar" → nome real do teste).
4. **Gate local.** `fvm flutter test` e `fvm flutter analyze` verdes. Reverter o
   ruído das pastas de plataforma: `git checkout -- linux/ macos/ windows/`.
   Se falhar: diagnosticar o erro e corrigir com um commit `fix:` adicional
   antes de seguir; se não resolver em poucas tentativas, parar e reportar o
   erro ao desenvolvedor em vez de insistir ou pular a etapa.
5. **PARAR para revisão.** Apresentar ao desenvolvedor: lista de commits, resumo
   do diff e o que mudou em docs. **Não fazer push sem o "ok"** — a menos que a
   tarefa tenha autorizado explicitamente o push.
6. **Push + PR (após o ok).** Push com upstream; PR com título `pr(<tipo>): ...`,
   corpo no template da GCS §6 e `Closes #N` fora de backticks. Acompanhar o
   check `analyze + test` até o verde (`gh pr checks --watch`) e reportar o link
   do PR com o status.

## O que NUNCA fazer

- Commitar/mergear direto na `main`, dar push antes da revisão, ou usar
  `--force`/amend em commits já revisados.
- Marcar a issue como resolvida por comentário — o fechamento é pelo `Closes #N`
  do PR (exceto issues pai/story, fechadas manualmente após as filhas).
- Inventar escopo: o PR entrega a issue pedida; achados novos viram issues novas.
