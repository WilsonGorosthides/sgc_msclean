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
4. **Verificação direcionada (quando há código).** O agente roda **apenas** os
   testes do(s) arquivo(s) da feature (`fvm flutter test test/<arquivo>`) para
   confirmar o red→green descrito na matriz. **Não** roda a suíte completa nem o
   `analyze` — esse é o gate do desenvolvedor (passo 5). Reverter o ruído das
   pastas de plataforma: `git checkout -- linux/ macos/ windows/`. Se o teste
   direcionado falhar quando deveria passar: diagnosticar e corrigir com um
   commit `fix:` adicional; se não resolver em poucas tentativas, parar e
   reportar ao desenvolvedor em vez de insistir ou pular a etapa.
5. **PARAR para revisão — com roteiro de verificação.** Apresentar ao
   desenvolvedor: lista de commits, resumo do diff e o que mudou em docs. Como o
   **gate final é do desenvolvedor**, entregar junto o **roteiro de verificação**
   que ele executa antes de autorizar o push:
   - **comandos:** `fvm flutter analyze` e `fvm flutter test` (suíte completa) —
     ambos devem ficar verdes;
   - **roteiro de teste manual da funcionalidade** (quando há comportamento
     observável a verificar): passos numerados, cada um mapeado ao(s) CT-ID(s)
     correspondentes e com o **resultado esperado** a observar. Esse roteiro
     alimenta a próxima Execução NNN de
     `docs/execucoes-de-testes-manuais.md`.

   **Não fazer push sem o "ok"** — a menos que a tarefa tenha autorizado
   explicitamente o push.
6. **Push + PR (após o ok do desenvolvedor).** Só após o desenvolvedor reportar
   **suíte completa verde + manuais ok**. Se ele devolver um log de falha, o
   agente diagnostica e corrige com um commit próprio (`fix:`/`docs:`) antes de
   retomar. Com o ok: push com upstream; PR com título `pr(<tipo>): ...`, corpo
   no template da GCS §6 e `Closes #N` fora de backticks. Acompanhar o check
   `analyze + test` até o verde (`gh pr checks --watch`) e reportar o link do PR
   com o status.

## O que NUNCA fazer

- Commitar/mergear direto na `main`, dar push antes da revisão, ou usar
  `--force`/amend em commits já revisados.
- Marcar a issue como resolvida por comentário — o fechamento é pelo `Closes #N`
  do PR (exceto issues pai/story, fechadas manualmente após as filhas).
- Inventar escopo: o PR entrega a issue pedida; achados novos viram issues novas.
