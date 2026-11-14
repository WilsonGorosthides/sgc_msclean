---
name: entrega
description: Fluxo GCS completo de entrega de uma issue - branch, teste-antes, commits granulares, push + PR, merge com CI verde e passos manuais na pilha. Uso - /entrega <numero-da-issue>
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
   — eles são o roteiro dos testes. **Se o RF ainda não tem CTs** (caso dos RFs
   da agenda), escrevê-los é o primeiro passo da entrega: ver passo 3. Em tela
   da agenda, conferir também o protótipo (`git show origin/gh-pages:index.html`)
   e os tokens de `lib/theme/`. Resumir o plano de entrega em 3–5 linhas para o
   desenvolvedor antes de começar.
2. **Branch.** `main` atualizada (`git checkout main && git pull`) → branch
   `<tipo>/<descricao-curta>` (GCS §4).
3. **Teste-antes (quando há código).** Quando o RF não tem CTs, abrir com um
   commit `docs:` que cria os CTs em `docs/casos-de-teste.md` e as linhas na
   matriz ("CT-NNN — a implementar"). Depois, commit(s) `test:` com a suíte **vermelha**
   descrevendo o comportamento esperado (nomes dos testes = nomes da matriz);
   depois commit(s) `feat:`/`fix:` da implementação até o **verde**. Docs
   sincronizados (GCS §8) em commits `docs:` próprios, incluindo a linha no
   Histórico de Versões de cada doc tocado e a atualização da matriz
   ("a implementar" → nome real do teste).
4. **Verificação direcionada (quando há código).** O agente roda **apenas** os
   testes do(s) arquivo(s) da feature (`fvm flutter test test/<arquivo>`) para
   confirmar o red→green descrito na matriz. **Não** roda a suíte completa nem o
   `analyze` — esse é o papel do CI (passo 6). Reverter o ruído das
   pastas de plataforma: `git checkout -- linux/ macos/ windows/`. Se o teste
   direcionado falhar quando deveria passar: diagnosticar e corrigir com um
   commit `fix:` adicional; se não resolver em poucas tentativas, parar e
   reportar ao desenvolvedor em vez de insistir ou pular a etapa.
5. **Pilha de verificação manual.** Não há parada para revisão. Quando a
   entrega tem comportamento observável, acrescentar à seção "Pilha de
   verificação manual" de `docs/execucoes-de-testes-manuais.md` (commit `docs:`
   do próprio PR) um bloco com a issue, o PR e 3 a 5 passos do fluxo novo, cada
   um com o resultado esperado e o(s) CT-ID(s). Se a entrega muda schema ou RLS,
   o SQL vai no corpo do PR, em `docs/arquitetura.md` §4 e no topo da pilha
   ("SQL a aplicar"), pronto para colar — o agente não altera o banco.
6. **Push + PR + merge.** Push com upstream; PR com título `pr(<tipo>): ...`,
   corpo no template da GCS §6 e `Closes #N` fora de backticks. Acompanhar o
   check `analyze + test` (`gh pr checks --watch`). Verde: `gh pr merge --merge
   --delete-branch`, atualizar a `main` local, fechar a story pai se todas as
   filhas fecharam, e reportar em poucas linhas o que entrou, o link do PR e
   qualquer SQL pendente. Vermelho: diagnosticar e corrigir com commit próprio;
   se não resolver em poucas tentativas, parar e reportar.

## O que NUNCA fazer

- Commitar/mergear direto na `main`, mergear com o CI vermelho ou pendente, ou
  usar `--force`/amend em commits já enviados.
- Marcar a issue como resolvida por comentário — o fechamento é pelo `Closes #N`
  do PR (exceto issues pai/story, fechadas manualmente após as filhas).
- Inventar escopo: o PR entrega a issue pedida; achados novos viram issues novas.
