# Registro de Execuções de Testes Manuais — SGC para MSClean

> Registra cada rodada de **testes manuais**: data, versão testada, ambiente,
> resultados e issues abertas. O plano define a estratégia, os casos o roteiro,
> a matriz a cobertura — este documento, a **execução**.
>
> Testes **automatizados** ficam de fora: o CI já registra cada execução
> (`analyze + test` por PR).

## Convenções

- Cada rodada é uma seção `Execução NNN`, em ordem cronológica.
- Toda rodada registra **data**, **objeto** (PR/commit testado), **ambiente**
  (`plano-de-testes.md` §2.1), **executor** e o resultado por passo, mapeado aos
  CT-IDs de `casos-de-teste.md` quando houver.
- **Resultados possíveis:**

| Resultado | Significado |
|---|---|
| Aprovado | Comportamento observado igual ao esperado. |
| Aprovado com ressalva | Critério atendido, mas a rodada revelou algo a tratar (vira issue). |
| Reprovado | Comportamento observado diferente do esperado (vira issue de bug). |
| Adiado | Passo não executado nesta rodada, com motivo e destino registrados. |

- Todo achado (reprovação ou ressalva) referencia a issue aberta a partir dele.
- Desde 2026-11-13 a verificação manual não é mais feita a cada PR: os passos
  de cada entrega acumulam na **Pilha de verificação manual** (seção abaixo) e
  são executados de uma vez antes da instalação do APK (`plano-de-testes.md`
  §5.2). Ao rodar a pilha, ela vira a próxima `Execução NNN` e a seção é
  esvaziada.
- Ocorrências de **ambiente** (ex.: backend fora do ar) também são registradas,
  mesmo quando não são defeito do app.

## Pilha de verificação manual (pendente)

Passos ainda não executados, por entrega, na ordem em que foram mergeadas.
Rodar tudo antes de instalar o APK (issue #23).

**Antes de instalar:** o identificador do app mudou para `br.com.msclean.agenda`
(PR da preparação do APK). Um APK antigo (`com.example.sgc_msclean`) aparece
como **outro app**: desinstalar o antigo primeiro, para não ficarem dois ícones.
Conferir também que o APK novo abre a agenda **com dados** (a permissão de
internet passou a valer no release).

### SQL a aplicar (antes dos passos)

Seletor de peças (#134), no SQL Editor do painel do Supabase. O SQL da tabela
`precos` (#123) já foi aplicado (confirmado em 2026-11-17).

```sql
-- 1. colunas novas, todas opcionais (linha sem peça = item avulso)
alter table public.precos
  add column peca     text check (peca in ('sofa', 'tapete', 'poltrona', 'cortina', 'colchao', 'cadeira')),
  add column variante text,
  add column servico  text check (servico in ('higienizar', 'impermeabilizar')),
  add column retratil boolean not null default false;

-- 2. linhas já gravadas pela lista sugerida: preencher pelo nome
update public.precos set servico = 'higienizar'      where nome ilike 'higieniza%';
update public.precos set servico = 'impermeabilizar' where nome ilike 'impermeabiliza%';
update public.precos set peca = 'sofa', variante = '2'     where nome ilike '%sofá 2 lugares%';
update public.precos set peca = 'sofa', variante = '3'     where nome ilike '%sofá 3 lugares%';
update public.precos set peca = 'sofa', variante = '4'     where nome ilike '%sofá 4 lugares%';
update public.precos set peca = 'sofa', variante = 'canto' where nome ilike '%sofá de canto%';
update public.precos set peca = 'poltrona' where nome ilike '%poltrona%';
update public.precos set peca = 'cadeira'  where nome ilike '%cadeira%';
update public.precos set peca = 'tapete'   where nome ilike '%tapete%';
-- cortina passa a ser por folha (decisão de 2026-11-17)
update public.precos set peca = 'cortina', unidade = 'peca' where nome ilike '%cortina%';
update public.precos set peca = 'colchao', variante = 'solteiro' where nome ilike '%colchão solteiro%';
update public.precos set peca = 'colchao', variante = 'casal'    where nome ilike '%colchão casal%';
update public.precos set peca = 'colchao', variante = 'queen'    where nome ilike '%colchão queen%';
update public.precos set peca = 'colchao', variante = 'king'     where nome ilike '%colchão king%';
update public.precos set retratil = true where nome ilike '%retrátil%';
-- sem peça é avulso: não tem serviço de peça
update public.precos set servico = null where peca is null;

-- 3. linhas de retrátil, sem valor (ela define depois), só se a tabela já
--    foi começada e ainda não tem nenhuma; tabela vazia usa a lista sugerida
insert into public.precos (nome, unidade, valor, ordem, peca, variante, servico, retratil)
select v.nome, 'peca', null,
       (select coalesce(max(ordem), -1) from public.precos) + v.n,
       v.peca, v.variante, v.servico, true
from (values
  (1,  'Higienização sofá 2 lugares retrátil',      'sofa',     '2',     'higienizar'),
  (2,  'Higienização sofá 3 lugares retrátil',      'sofa',     '3',     'higienizar'),
  (3,  'Higienização sofá 4 lugares retrátil',      'sofa',     '4',     'higienizar'),
  (4,  'Higienização sofá de canto retrátil',       'sofa',     'canto', 'higienizar'),
  (5,  'Higienização poltrona retrátil',            'poltrona', null,    'higienizar'),
  (6,  'Impermeabilização sofá 2 lugares retrátil', 'sofa',     '2',     'impermeabilizar'),
  (7,  'Impermeabilização sofá 3 lugares retrátil', 'sofa',     '3',     'impermeabilizar'),
  (8,  'Impermeabilização sofá 4 lugares retrátil', 'sofa',     '4',     'impermeabilizar'),
  (9,  'Impermeabilização sofá de canto retrátil',  'sofa',     'canto', 'impermeabilizar'),
  (10, 'Impermeabilização poltrona retrátil',       'poltrona', null,    'impermeabilizar')
) as v(n, nome, peca, variante, servico)
where exists (select 1 from public.precos)
  and not exists (select 1 from public.precos where retratil);
```

### #123 — Tabela de preços editável (RF-013, parte 1)

Testes manuais gravam no banco real (o mesmo do celular): usar serviços com
"TESTE" no nome e apagá-los no fim. Se a proprietária já tiver começado a
tabela de verdade, pular o passo 2.

1. Na agenda, tocar no ícone de etiqueta (Tabela de preços). **Esperado:** abre
   "Tabela de preços" com a dica de serviços independentes e combo no topo.
   (CT-081, CT-084)
2. Com a tabela vazia, tocar em "Começar com a lista sugerida". **Esperado:** a
   lista aparece, com higienização e impermeabilização em linhas separadas,
   tapete e cortina "por m²", o resto "por peça", todos "sem valor"; o botão
   some. (CT-084, CT-085)
3. Tocar em "+", salvar sem nome (avisa "Informe o nome"); depois "TESTE
   Impermeabilização poltrona", por peça, valor `90,50`, Salvar. **Esperado:**
   aparece no fim da lista com "R$ 90,50". (CT-082)
4. Tocar no serviço TESTE, mudar para "por m²", apagar o valor e salvar.
   **Esperado:** "por m²" e "sem valor". (CT-082)
5. Sem internet, fechar e reabrir o app e a tabela. **Esperado:** a tabela
   aparece (guardada no aparelho) com o aviso de sem conexão. Com a internet de
   volta, tocar na lixeira do TESTE, Cancelar (fica) e depois Remover.
   **Esperado:** "Serviço removido" e a linha sai. (CT-086, CT-083)

### #124 — Valor do atendimento calculado pela tabela (RF-013, parte 2)

Antes: a tabela tem "Higienização sofá 3 lugares" e "Impermeabilização sofá 3
lugares" com valor, "Higienização de tapete" com valor do m² e um serviço sem
valor (ex.: "Remoção de odor"). Usar o cliente "TESTE" num dia passado e
excluir o atendimento no fim.

1. Novo atendimento, peça sofá. **Esperado:** só os serviços de sofá aparecem
   como opção. Marcar só a impermeabilização: "Total calculado" mostra o valor
   dela e o campo Valor acompanha. Marcar também a higienização: o total soma
   os dois. Mudar a quantidade para 2: o total dobra. (CT-087, CT-089, CT-090)
2. Adicionar uma peça tapete, marcar a higienização por m² e informar 8 × 4,5.
   **Esperado:** antes das medidas, aviso "Falta medida"; depois, o tapete
   soma 36 × o valor do m². (CT-088)
3. Adicionar uma peça "outro" e marcar o serviço sem valor. **Esperado:**
   aviso "Sem valor na tabela" com o nome dele; o total não muda. (CT-090)
4. Digitar outro valor no campo Valor (desconto). **Esperado:** o valor
   digitado fica, mesmo mudando peças; aparece "Usar o calculado", que volta ao
   total. Salvar com o valor digitado. (CT-091)
5. Na tabela de preços, mudar o valor da higienização de sofá; abrir o
   atendimento salvo. **Esperado:** os serviços e o Valor seguem com os preços
   do dia do registro. Excluir o atendimento TESTE e voltar a tabela ao valor
   de antes. (CT-092)

### #134 — Seletor de peças e serviços (RF-013) · **PR de interface, sem merge antes do ok**

Antes: SQL acima aplicado (confirmado pelo desenvolvedor em 2026-11-17; o
bloco "SQL a aplicar" sai da pilha quando a execução registrar). Testes gravam no banco real: cliente "TESTE", dia
passado, e excluir o atendimento no fim.

1. Tabela de preços: abrir "Higienização sofá 3 lugares". **Esperado:** peça
   Sofá, 3 lugares e Higienizar marcados. A lista tem as linhas de retrátil
   "sem valor" e a cortina "por peça". (CT-100)
2. Novo atendimento: o formulário é curto (sem quadros nem rodapé de total) e
   salva só com cliente e período. Tocar na linha "Adicionar peças e valor":
   abre "Peças e valor", com os quadros na ordem Sofá, Tapete, Poltrona, Cortina,
   Colchão, Cadeira, Outros. Tocar Sofá duas vezes e Poltrona uma. **Esperado:**
   selos ×2 e ×1; "Sofá 1" e "Sofá 2". No Sofá 1, − / + nos lugares (2 → 3 → 4
   → canto), ligar retrátil; tirar o Sofá 2 pelo ×. (CT-093, CT-094)
3. Tapete: + na largura e no comprimento até 2 × 3. **Esperado:** "6 m²" a
   cada toque. Colchão: Casal + duas vezes (selo ×2). Cortina e cadeira: − / +.
   Nenhum teclado aparece. (CT-094, CT-101)
4. No sofá de 3 lugares, marcar só Impermeabilizar; depois os dois. Passar a
   4 lugares, depois voltar e ligar o retrátil. **Esperado:** cada botão mostra
   o preço; os dois somam; sem linha ou sem valor, "sem valor" e o aviso no
   rodapé. Outros: + no Deslocamento soma no total. (CT-095, CT-096, CT-098)
5. Rodapé: total sempre à vista; abrir os detalhes (serviço, conta e valor);
   "Mudar valor" para outro número; mudar uma quantidade; "Usar o calculado";
   "Pronto" (ou a seta): o resumo mostra as peças e o valor; salvar. Abrir
   um atendimento salvo antes desta versão e salvar sem mexer.
   **Esperado:** abre com os serviços e preços de antes, e nada some. Excluir
   os atendimentos TESTE. (CT-097, CT-099, CT-101)

## Execução 001 — Verificação manual do RF-001 (pré-merge do PR #44)

- **Data:** 2026-07-16
- **Objeto:** PR #44 (`feat/rf-001-cadastro-cliente`) — RF-001 Cadastro de
  Cliente, antes do merge na `main`.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  **real** do MVP — alternativa prevista em `plano-de-testes.md` §2.1 (o
  dispositivo da cliente não estava acessível).
- **Executor:** Wilson Gorosthides.
- **Roteiro:** ad-hoc de 10 passos montado para a validação do PR (anterior à
  execução formal do CT-023, que depende de RF-002 e RF-008). Os passos foram
  mapeados a posteriori aos CT-IDs correspondentes.

### Ocorrência de ambiente (antes da rodada)

Na primeira tentativa de salvar um cliente, o app exibiu o SnackBar genérico
"Erro ao salvar. Tente novamente.". Diagnóstico via REST (curl direto na API do
Supabase): o DNS do projeto não resolvia — o projeto estava **pausado** pelo
free tier do Supabase (inatividade). **Não era defeito do app.** Após o resume
pelo painel, tabela `clientes`, RLS e policy foram verificados intactos via REST
(GET 200, POST 201, DELETE 204) e a rodada prosseguiu.

Aprendizados que viraram rastro:

- O estado "lista vazia" pode mascarar erro de conexão ("Nenhum cliente
  encontrado." aparece mesmo com o backend fora) → **issue #47** (bug).
- Restaurar o ambiente do zero depende de conhecimento não documentado →
  reforça a urgência do guia de deploy (**issue #21**).

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Estado vazio: "Nenhum cliente encontrado." com a tabela vazia | CT-013 | Aprovado |
| 2 | Caminho feliz: salvar fecha o formulário e o cliente aparece na lista sem recarga | CT-004, CT-005 | Aprovado |
| 3 | Campos obrigatórios: salvar com tudo vazio bloqueia e aponta os três campos | CT-001 | Aprovado |
| 4 | Só espaços no telefone: salvamento bloqueado apontando o campo | CT-002 | Aprovado |
| 5 | Telefone inválido: `12#34` rejeitado com a mensagem de formato | CT-003 | Aprovado com ressalva |
| 6 | Ordem alfabética com inserção em tempo real (novo cliente "B" entra entre "A" e "C") | CT-010, CT-012 | Aprovado |
| 7 | Busca: filtra ao digitar, mensagem sem correspondência, limpar restaura | CT-014–CT-018 | Aprovado |
| 8 | Realtime na direção contrária: exclusão pelo painel do Supabase some da lista sem F5 | CT-012 | Aprovado |
| 9 | Erro de rede: salvar offline exibe SnackBar e mantém o formulário aberto | — | Adiado |
| 10 | Limpeza dos dados de teste | — | Concluída |

Notas por passo:

- **Passo 5 (ressalva):** o critério do RF-001 restringe apenas os *caracteres*
  do telefone — por isso, removido o `#`, o valor `1234` (4 dígitos) foi salvo.
  Comportamento **conforme o requisito atual**, mas a rodada expôs que o
  critério não impede telefone curto demais → **issue #48** (mudança de
  requisito, decisão pendente: mínimo de dígitos).
- **Passo 8:** houve dificuldade inicial para localizar a tabela no painel do
  Supabase (projeto recém-restaurado da pausa); o passo foi concluído junto com
  a limpeza (passo 10) — a exclusão pelo painel refletiu na lista do app em
  tempo real, como esperado.
- **Passo 9 (adiado):** ficará para verificação em dispositivo físico (alternar
  Wi-Fi no desktop é menos representativo). O comportamento já é coberto pelo
  teste automatizado `client_form_screen_test: falha ao salvar exibe erro e
  mantém o formulário aberto` (nota do CT-005).

### Achados adicionais (fora do escopo do RF-001)

- Tocar em um cliente da lista não abre nenhuma tela — **esperado**: edição
  (RF-002) e exclusão pelo app (RF-008) ainda não existem; são os próximos RFs
  (issues #26/#33 e a story de exclusão).

### Veredicto

**PR #44 validado**: os critérios de aceitação do RF-001 se confirmaram no
ambiente real; nenhum defeito de código encontrado (a única falha observada foi
a ocorrência de ambiente, diagnosticada e resolvida). Merge realizado em
2026-07-16; achados rastreados nas issues #47 e #48.

## Execução 002 — Verificação manual do RF-002 (pré-merge do PR #55)

- **Data:** 2026-07-18 e 2026-07-19 (duas rodadas).
- **Objeto:** PR #55 (`feat/edicao-de-cliente`) — RF-002 Edição de Cliente,
  antes do merge; inclui regressão do critério novo do telefone (CT-024,
  PR #54, já mergeado).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP.
- **Executor:** o desenvolvedor.

### Rodada 1 (2026-07-18)

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| A1–A5 | Telefone: `1234`/`192` bloqueados; 8 dígitos e formatado aceitos; `12#34` rejeitado | CT-024, CT-003 | Aprovado |
| B6 | Toque no cliente abre o formulário pré-preenchido | CT-006 | Aprovado |
| B7 | Validações do cadastro valem na edição | CT-007 | Aprovado |
| B8 | Edição refletida na lista em tempo real | CT-008 | **Reprovado** |
| B9 | Cancelar (voltar) não grava nada | CT-009 | Aprovado com ressalva |
| C10 | Regressão: cadastro, busca, estado vazio | CT-004, CT-014–018 | Aprovado |

- **CT-008 (reprovado):** o banco atualizava (confirmado no painel e via F5),
  mas a lista aberta não refletia; reabrir o cliente mostrava o dado antigo.
- **CT-009 (ressalva):** não há botão "Cancelar" dedicado — o voltar é o
  mecanismo de cancelamento, o que atende o critério; registrado como
  observação de conformidade.

### Diagnóstico do CT-008 (entre as rodadas)

Investigação em camadas, nesta ordem: **(1)** publication do servidor ok
(`pg_publication`: insert/update/delete todos `true`); **(2)** F5 sempre
trazia o dado novo — escrita íntegra, problema só na entrega do evento;
**(3)** upgrade do `supabase_flutter` 2.12→2.16 sem efeito (revertido);
**(4)** defeito real de arquitetura corrigido — a Home recriava a assinatura
realtime a cada rebuild (churn por tecla na busca); a assinatura única
resolveu a lista vazia na abertura, mas não o UPDATE; **(5)** teste puro
(edição pelo painel com o app parado) provou que o evento UPDATE **não
chega** ao app. Conclusão: limitação do projeto Supabase atual — **issue
#57**. Critério do RF-002 **renegociado** (`requisitos.md` 2.4): reflexo
"imediatamente ao retornar do formulário" (a Home renova a stream no
retorno), em vez de "em tempo real".

### Rodada 2 (2026-07-19, pós-renegociação)

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Telefone editado aparece ao reabrir o cliente após salvar | CT-008 | Aprovado |
| 2 | Cliente novo aparece na lista ao voltar do cadastro | CT-004 | Aprovado |
| 3 | Voltar sem salvar mantém a lista intacta | CT-009 | Aprovado |
| 4 | Busca filtra e restaura normalmente | CT-014–018 | Aprovado |

### Veredicto

**PR #55 validado** contra o critério renegociado: todos os CTs do RF-002
aprovados na rodada 2; o achado da rodada 1 virou correção de arquitetura
(assinatura única), mudança de requisito documentada e a issue #57 para
restaurar o realtime pleno no futuro.

## Execução 003 — Verificação manual do RF-008 (pré-merge do PR de exclusão)

- **Data:** 2026-07-20.
- **Objeto:** branch `feat/exclusao-de-cliente` — RF-008 Exclusão de Cliente,
  antes do merge.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP.
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Lixeira abre o diálogo "Confirmar exclusão?"; nada removido antes | CT-019 | Aprovado |
| 2 | Cancelar mantém o cliente na lista | CT-020 | Aprovado |
| 3 | Confirmar remove do banco e some da lista imediatamente | CT-021 | Aprovado |
| 4 | SnackBar "Cliente excluído" após a exclusão | CT-022 | Aprovado |
| 5 | Toque na linha (não na lixeira) abre a edição | Regressão RF-002 | Aprovado |
| 6 | Cadastro e busca seguem funcionando | Regressão | Aprovado |

- **Ponto de atenção do passo 3:** o reflexo da exclusão foi imediato,
  garantido pela renovação local da stream após a ação (critério renegociado,
  `requisitos.md` 2.5). Diferente do UPDATE do RF-002, o DELETE nativo do
  realtime **não** foi testado isoladamente aqui — a renovação foi adotada por
  consistência e robustez, sem presumir que o DELETE falhe (contexto na
  issue #57).

### Veredicto

**RF-008 validado** em rodada única: os quatro critérios aprovados, sem
regressão no cadastro, edição e busca. Com esta feature, o MVP fica completo
(5/5).

## Execução 004 — Verificação manual do endereço opcional (pré-merge, #61)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/endereco-opcional` — endereço opcional com aviso
  (RF-001, `requisitos.md` 2.6), antes do merge.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`).
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Salvar vazio aponta Nome e Telefone, não Endereço | CT-001 | Aprovado |
| 2 | Salvar sem endereço abre o aviso de confirmação | CT-025 | Aprovado |
| 3 | Confirmar ("Salvar mesmo assim") grava e fecha | CT-025 | Aprovado |
| 4 | Cliente sem endereço mostra "Sem endereço" na lista | #61 | Aprovado |
| 5 | Cancelar o aviso não grava e mantém o formulário | CT-025 | Aprovado |
| 6 | Cadastro completo (com endereço) salva sem diálogo | Regressão | Aprovado |

### Veredicto

**#61 validado** em rodada única, suíte automatizada verde. Endereço passa a
opcional com confirmação, sem regressão no cadastro completo.

## Execução 005 — Verificação manual dos múltiplos telefones (pré-merge, #62)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/multiplos-telefones` — um ou mais telefones por
  cliente (RF-001, `requisitos.md` 2.7), antes do merge. Inclui a **migração
  do Supabase** (`telefone` text → `telefones` text[]).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP (após a migração aplicada no SQL Editor).
- **Executor:** o desenvolvedor.

### Migração (pré-teste)

`ALTER TABLE` aplicado no SQL Editor: adiciona `telefones text[]`, copia os
valores de `telefone` para a lista, zera nulos e remove a coluna antiga. O
aviso de operação destrutiva (do `drop column`) foi confirmado após verificar
que os números tinham sido copiados. Migração concluída com sucesso.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Cadastro com um telefone | RF-001 | Aprovado |
| 2 | Cadastro com dois telefones grava o array no banco | CT-026 | Aprovado |
| 3 | Edição vem com os telefones pré-preenchidos | CT-006 | Aprovado |
| 4 | Remover um telefone na edição persiste o restante | CT-026 | Aprovado |
| 5 | Segundo telefone inválido bloqueia o salvamento | CT-026 | Aprovado |
| 6 | Endereço opcional, busca e exclusão sem regressão | Regressão | Aprovado |

### Veredicto

**#62 validado**, suíte automatizada verde e migração do Supabase aplicada. O
app passa a aceitar um ou mais telefones por cliente. Com esta entrega, as duas
mudanças de requisito de preparação para os dados reais (#61 e #62) estão
concluídas.

## Execução 006 — Verificação manual do endereço estruturado (pré-merge, #65)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/endereco-estruturado` — endereço estruturado
  (RF-001/003/004, `requisitos.md` 2.8), antes do merge. Inclui a **migração do
  Supabase** (`endereco` text → jsonb).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP (após a migração aplicada no SQL Editor).
- **Executor:** o desenvolvedor.

### Migração (pré-teste)

`ALTER TABLE` aplicado no SQL Editor: cria `endereco_novo jsonb`, copia o texto
antigo para a chave `logradouro`, zera nulos como `{}`, remove a coluna `text`
e renomeia. Concluída com sucesso. Uma tentativa acidental de reexecutar a
migração acusou `invalid input syntax for type json` no `endereco <> ''` — o
próprio erro confirmou que a coluna já era jsonb (migração já aplicada); a
coluna `endereco_novo` recriada pela reexecução foi removida com
`drop column if exists`. Sem campos de CEP/cidade: a área de atendimento é só
Campo Grande - MS (âncora fixa na consulta ao mapa).

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Cadastro com os campos estruturados grava o objeto jsonb no banco | CT-027 | Aprovado |
| 2 | A lista mostra o resumo (logradouro, número - bairro) | CT-011 | Aprovado |
| 3 | Salvar sem nenhum campo: aviso, confirmar grava, "Sem endereço" na lista | CT-025, CT-011 | Aprovado |
| 4 | Edição vem com os campos pré-preenchidos e reflete ao voltar | CT-006, CT-008 | Aprovado |
| 5 | Busca encontra por bairro/rua, além do nome | CT-014 | Aprovado |
| 6 | Múltiplos telefones e exclusão sem regressão | Regressão | Aprovado |

### Veredicto

**#65 validado**, suíte automatizada verde e migração do Supabase aplicada
(text → jsonb). O endereço passa a ser estruturado (logradouro, número, bairro,
complemento, referência), preparando o resumo na lista, a busca por qualquer
campo e a abertura no mapa (#66).

## Execução 007 — Verificação manual do abrir no Google Maps (pré-merge, #66)

- **Data:** 2026-07-21.
- **Objeto:** branch `feat/abrir-endereco-no-maps` — RF-009 abrir o endereço no
  Google Maps (`requisitos.md` 2.9), antes do merge. Sem mudança de schema
  (nenhuma migração).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP.
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Cliente com endereço mostra o ícone de mapa; tocar abre o Google Maps na localização | CT-028 | Aprovado |
| 2 | Cliente sem endereço não mostra o ícone de mapa | CT-028 | Aprovado |
| 3 | Regressão: toque na linha abre a edição; a lixeira exclui — o ícone de mapa convive com eles | Regressão | Aprovado |

### Veredicto

**#66 validado** em rodada única, suíte automatizada verde. A partir de um
cliente com endereço, um toque abre o Google Maps na localização; sem endereço,
o ícone não aparece. Fecha o par de entregas do endereço estruturado (#65) + o
mapa (#66).

## Execução 008 — Verificação manual da agenda como tela inicial (pré-merge, #75)

- **Data:** 2026-11-13.
- **Objeto:** branch `feat/agenda-por-data-tela-inicial` — RF-010 agenda por
  data, com as visões de dia, semana e mês (`requisitos.md` 3.2), antes do
  merge. Com mudança de schema: criação da tabela `atendimentos` (RLS e
  publicação de realtime — SQL em `arquitetura.md` §4), aplicada pelo
  desenvolvedor no painel antes da rodada, mais um seed de oito atendimentos
  de exemplo inserido pelo SQL Editor (o app ainda não os cria; isso é o
  RF-005).
- **Ambiente:** web desktop (`fvm flutter run -d chrome`), contra o Supabase
  real do MVP. A verificação no celular da proprietária fica para a instalação
  do APK (issue #23).
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | O app abre na agenda, em "Hoje", com a data por extenso e só os atendimentos de hoje | CT-029 | Aprovado |
| 2 | Manhã antes da Tarde; na manhã, 08:00, 10:00 e depois os sem hora na ordem de registro | CT-030 | Aprovado |
| 3 | Cartão com hora ou "sem hora", local, resumo das peças e valor em reais | CT-030 | Aprovado |
| 4 | Cabeçalho de cada período com a quantidade (Manhã 4, Tarde 1) | CT-031 | Aprovado |
| 5 | Tocar em amanhã na faixa da semana troca o dia, sem campo de data | CT-032 | Aprovado |
| 6 | Dia vazio exibe "Nenhum atendimento neste dia." e nenhum período | CT-033 | Aprovado |
| 7 | Na faixa, só os dias com atendimento exibem a quantidade | CT-034 | Aprovado |
| 8 | Faixa de domingo a sábado; setas avançam e retrocedem a semana com as quantidades | CT-035 | Aprovado |
| 9 | Um toque abre o mês em calendário com a quantidade por dia; setas trocam o mês | CT-036 | Aprovado |
| 10 | Tocar num dia do mês seleciona, volta à visão do dia e mostra a semana dele | CT-037 | Aprovado |
| 11 | Hoje tem marca própria na semana e no mês; o atalho de voltar a hoje só aparece fora de hoje | CT-038 | Aprovado |
| 12 | Ícone de pessoas abre "MSClean - Clientes"; voltar retorna ao mesmo dia | CT-039 | Aprovado |
| 13 | Regressão: cadastrar, editar e excluir cliente pela lista | CT-004, CT-008, CT-021 | Aprovado |
| 14 | Atendimento inserido pelo painel com o app aberto aparece na agenda (realtime) | RF-010 | Aprovado |

### Veredicto

**#75 validado** em rodada única, suíte automatizada verde. A agenda passa a
ser a tela inicial: o dia agrupado por período, a semana sempre à vista e o mês
a um toque, com a lista de clientes acessível a partir dela. Decisões aceitas
na revisão: semana de domingo a sábado (a confirmar com a proprietária no uso
real), FK `cliente_id` com `on delete cascade`, tabela sem
feito/pago/observação (entram no RF-014 e no RF-005) e mês como alternância na
mesma tela.

## Execução 009 — Verificação manual do registro de atendimento (pós-merge, #77)

- **Data:** 2026-11-13.
- **Objeto:** PR #89 (issue #77) — RF-005 enxuto, registrar e editar atendimento
  a partir do dia da agenda (`requisitos.md` §2.2). Sem mudança de schema. A
  rodada foi feita antes do merge; o registro entra depois dele.
- **Ambiente:** web desktop (`fvm flutter run -d chrome`) e celular físico
  (SM A505GT, Android 11, `fvm flutter run -d`), contra o Supabase real do MVP.
- **Executor:** o desenvolvedor.

### Resultados

| Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|
| 1 | Novo atendimento abre com a data do dia selecionado, sem campo de data | CT-040 | Aprovado |
| 2 | Salvar sem cliente e sem período não grava e aponta os dois campos | CT-041 | Aprovado |
| 3 | Cliente com endereço, período Tarde, peças (tapete com medidas e sofá) e valor `180,50`; o Local vem do endereço; o cartão aparece na Tarde do mesmo dia | CT-043, CT-044, CT-047, CT-048 | Aprovado |
| 4 | Tocar no cartão abre a edição; a hora alterada atualiza o mesmo atendimento, sem duplicar | CT-042 | Aprovado |
| 5 | "Anotar só o nome" cria o cliente provisório, o atendimento aparece na Manhã e a lista de clientes mostra o selo "provisório" | CT-045, CT-046 | Aprovado |

### Ocorrências
- A hora abreviada (`8`, `830`, `1430`) passou a ser completada para `HH:MM`
  durante a rodada, por sugestão do desenvolvedor, e o botão foi renomeado para
  "Salvar atendimento" para não ser confundido com a marca de serviço feito
  (RF-014); ambos já estavam no PR.
- No celular, a primeira abertura veio sem dados por falta de rede do aparelho
  (nenhuma rede ativa); o app mostrou "Nenhum cliente encontrado." porque a
  falha de conexão não é distinguida de lista vazia — bug já registrado (#47).
  Com a rede restabelecida, os dados apareceram.
- Achados fora de escopo, abertos como issues: #87 (a seleção acompanha o mesmo
  dia da semana ao trocar a semana pela seta) e #88 (abrir o Local no Google
  Maps a partir do cartão).

### Veredicto

**#77 validado** em rodada única, no Chrome e no celular, com a suíte
automatizada verde. A proprietária já consegue registrar e editar atendimentos
pelo próprio app.

## Execução 010 — Pilha: troca de semana e marcas de feito e pago (pós-merge, #87 e #79)

- **Data:** 2026-11-16.
- **Objeto:** os dois primeiros blocos da pilha de verificação manual — fix #87
  (PR #92, seleção ao trocar a semana pela seta) e RF-014 (issue #79, PR #93,
  marcas de serviço feito e cliente pagou). Rodada com o SQL do RF-014 já
  aplicado no painel.
- **Ambiente:** celular físico, contra o Supabase real do MVP.
- **Executor:** o desenvolvedor (resultado informado em 2026-11-16).

### Resultados

| Bloco | Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|---|
| #87 | 1 | De um sábado, a seta de próxima semana seleciona o domingo da semana seguinte | CT-035 | Aprovado |
| #87 | 2 | Voltando à semana de hoje, a seleção vai para hoje e o título volta a "Hoje" | CT-035, CT-038 | Aprovado |
| #79 | 1 | "Feito" marca na hora, sem abrir o formulário; "Pago" segue vazio | CT-049, CT-052 | Aprovado |
| #79 | 2 | Com "Pago" também, o cartão fica verde claro e mostra "Concluído" | CT-050, CT-051 | Aprovado |
| #79 | 3 | Desmarcar "Pago" apaga só ele e tira o "Concluído" | CT-049 | Aprovado |
| #79 | 4 | As marcas persistem ao fechar e reabrir o app | CT-049 | Aprovado |
| #79 | 5 | Editar a hora pelo formulário não perde as marcas | CT-042, CT-049 | Aprovado |

### Ocorrências
- A proprietária viu as marcas na demonstração de 2026-11-16 e aprovou.

### Veredicto
**Aprovado.** Os dois blocos saem da pilha; seguem pendentes os blocos de
#94, #96 e #95.

## Execução 011 — Pilha: offline, marca, avisos e trocar o dia ou excluir (pós-merge, #94, #96, #95 e #106)

- **Data:** 2026-11-16.
- **Objeto:** os quatro blocos restantes da pilha — anotar sem internet (#94,
  PR #97), ícone, nome e abertura com a marca (#96, PR #98), avisos no celular
  (#95, PR #99, com o pedido de bateria #101 e o fix do fuso #105) e trocar o
  dia e excluir atendimento (#106, PR #107). Sem SQL.
- **Ambiente:** celular físico com Android 11, APK gerado da `main`, contra o
  Supabase real do MVP; o passo web do #96 no Chrome do computador.
- **Executor:** o desenvolvedor (resultado informado em 2026-11-16).

### Resultados

| Bloco | Passo | O que verificou | CT(s) | Resultado |
|---|---|---|---|---|
| #94 | 1 | Sem rede, agenda e clientes abrem do aparelho com a faixa "Sem conexão" | CT-053, CT-056 | Aprovado |
| #94 | 2 | Atendimento com cliente novo registrado sem rede, com o selo "aguardando envio" | CT-054 | Aprovado |
| #94 | 3 | Cartão pendente não abre nem marca; mostra o aviso | CT-058 | Aprovado |
| #94 | 4 | O pendente sobrevive a fechar e reabrir sem rede | CT-057 | Aprovado |
| #94 | 5 | Com a rede de volta, o selo some e o registro chega uma vez só ao banco | CT-055 | Aprovado |
| #96 | 1 | Ícone da gota sobre o azul-marinho e nome "MS Clean" na gaveta | CT-059 | Aprovado |
| #96 | 2 | Abertura azul-marinho com a marca, sem tela branca | CT-059 | Aprovado |
| #96 | 3 | "MS Clean" na troca de tarefas | CT-059 | Aprovado |
| #96 | 4 | Na web, aba com a gota e abertura com o logo | CT-059 | Aprovado |
| #95 | 1 | Pedido de bateria na primeira abertura (no Android 11 não há pedido de notificação) | CT-066 | Aprovado |
| #95 | 2 | Aviso "Em 1 hora" chega com hora, local e o ícone da gota | CT-062 | Aprovado |
| #95 | 3 | Tocar no aviso abre a agenda no dia do atendimento | CT-065 | Aprovado |
| #95 | 4 | Resumos da véspera (19h) e do dia (7h) | CT-060, CT-061 | Aprovado |
| #95 | 5 | Mudar a hora reagenda o aviso | CT-064 | Aprovado |
| #106 | 1 | A data da edição abre o calendário em português | CT-067 | Aprovado |
| #106 | 2 | Trocar o dia leva o atendimento e a agenda ao dia novo | CT-067 | Aprovado |
| #106 | 3 | Em "Novo atendimento", a data não abre o calendário | CT-067, CT-040 | Aprovado |
| #106 | 4 | Cancelar a exclusão mantém o atendimento | CT-068 | Aprovado |
| #106 | 5 | Confirmar a exclusão tira o cartão e o aviso dele | CT-068, CT-064 | Aprovado |

### Ocorrências
- Na primeira tentativa do #95, o aviso de "1 hora antes" não chegou. Causa: o
  horário era remontado no fuso fixo de Campo Grande (UTC-4) e, num aparelho
  em UTC-3, o aviso saía uma hora depois. Corrigido no PR #105; com o APK novo,
  o aviso chegou.
- O pedido de notificação não apareceu no Android 11: esperado, ele só existe
  a partir do Android 13.

### Veredicto
**Aprovado.** Os quatro blocos saem da pilha, que fica vazia antes da
preparação do APK de release (#23).

## Execução 012 — Pilha: APK de release assinado com a chave própria (pós-merge, #109)

- **Data:** 2026-11-16.
- **Objeto:** assinatura do release com a keystore do desenvolvedor (#109, PR
  #110). Sem SQL.
- **Ambiente:** computador do desenvolvedor (build) e celular Realme RMX3941
  com Android 16, instalação por cabo USB (`adb install`), contra o Supabase
  real do MVP.
- **Executor:** o agente (passo 1, ao validar o PR, e as instalações por
  `adb`) e o desenvolvedor (conferência no celular, informada em 2026-11-16).

### Resultados

| Passo | O que verificou | Resultado |
|---|---|---|
| 1 | Sem `android/key.properties`, o build de release falha com a mensagem "Falta android/key.properties..." | Aprovado |
| 2 | Com a keystore e o `key.properties`, sai o `app-release.apk` assinado pela chave do desenvolvedor (`apksigner verify`); nem a chave nem o `key.properties` aparecem no `git status` | Aprovado |
| 3 | Instalado num aparelho sem o app: abre a agenda com dados, ícone e nome "MS Clean"; pede notificação (Android 16) e bateria | Aprovado |
| 4 | APK gerado de novo e instalado **por cima** (`adb install -r`): aceito como atualização, dados mantidos, sem pedir permissões de novo | Aprovado |

### Ocorrências
- O `keytool` em português pergunta "Está correto? [não]" e não aceita `y`;
  a resposta é `sim`, ou passar `-dname` no comando (`docs/arquitetura.md` §12).
- Primeira rodada num Android 13+: o pedido de notificação, que não existe no
  Android 11 da Execução 011, apareceu e foi aceito.

### Veredicto
**Aprovado.** O caminho de atualização do app da usuária está provado: cada
versão nova, assinada com a mesma chave, instala por cima sem perder dados.

## Execução 013 — Pilha: histórico, contatos, Salvar acima da barra e busca (pós-merge, #81, #115, #118, #113)

- **Data:** 2026-11-17.
- **Objeto:** os quatro blocos da pilha — histórico do cliente (#81, PR
  #121), cliente dos contatos do celular (#115, PR #120), Salvar acima da
  barra de navegação (#118) e busca por relevância e sem acento (#113). Sem
  SQL.
- **Ambiente:** APK de release instalado por cima (`adb install -r`) no
  celular do desenvolvedor, Realme RMX3941 com Android 16, contra o Supabase
  real do MVP. O #118 foi escrito para o Samsung A25 da usuária e rodou no
  celular do desenvolvedor.
- **Executor:** o desenvolvedor (resultado informado em 2026-11-17: "todos os
  testes passaram"); o agente instalou o APK e capturou as telas por `adb`.

### Resultados

| Bloco | Passos | Resultado |
|---|---|---|
| #81 — histórico do cliente | 1 a 5 (CT-076 a CT-079) | Aprovado |
| #115 — cliente dos contatos | 1 a 5 (CT-072 a CT-074, CT-055) | Aprovado |
| #118 — Salvar acima da barra | 1 a 3 (CT-071) | Aprovado |
| #113 — busca | 1 a 4 (CT-069, CT-070) | Aprovado |

### Ocorrências
- **Bug #128:** um atendimento recém-registrado apareceu **duas vezes** na
  agenda; reabrir o app desfazia, trocar de tela às vezes não. Causa: a
  stream do Supabase entrega a linha em dobro quando o INSERT do realtime
  chega depois da leitura inicial. Corrigido no espelho (uma linha por id),
  com passo novo na pilha.
- **Achado de uso (#129):** o desenvolvedor procurou o histórico na tela do
  atendimento, não na do cliente. Vira resumo do histórico na escolha do
  cliente do atendimento.
- Os testes gravaram dados no banco real (o mesmo do celular da usuária):
  registros de teste nomeados "TESTE" e apagados no fim. Um projeto Supabase
  separado para teste fica como recomendação.

### Veredicto
**Aprovado**, com o bug #128 corrigido no PR seguinte.

## Execução 014 — Pilha: atendimento novo em dobro na agenda (pós-merge, #128)

- **Data:** 2026-11-17.
- **Objeto:** correção do atendimento recém-registrado em dobro na agenda
  (#128, PR #130). Sem SQL.
- **Ambiente:** APK de release instalado por cima (`adb install -r`) no
  celular do desenvolvedor, Realme RMX3941 com Android 16, contra o Supabase
  real do MVP, com rede.
- **Executor:** o desenvolvedor (resultado informado em 2026-11-17: "passou
  tudo"); o agente gerou e instalou o APK.

### Resultados

| Passo | O que verificou | Resultado |
|---|---|---|
| 1 | Atendimento de teste registrado e volta à agenda, três vezes: cada um aparece uma vez só, contagem do dia e do período certa | Aprovado |
| 2 | Fechar e reabrir o app: nada some nem duplica; clientes "TESTE" apagados no fim, com os atendimentos | Aprovado |

### Veredicto
**Aprovado.** Pilha vazia.

## Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2026-07-17 | 1.0 | Wilson Gorosthides | Criação do registro de execuções de testes manuais, com as convenções de registro e a Execução 001 (RF-001, pré-merge do PR #44) — issue #49. |
| 2026-07-19 | 1.1 | Wilson Gorosthides | Execução 002 (RF-002, pré-merge do PR #55): duas rodadas, com o diagnóstico do CT-008 (realtime UPDATE não entregue, issue #57), a renegociação do critério (`requisitos.md` 2.4) e a aprovação final. |
| 2026-07-20 | 1.2 | Wilson Gorosthides | Execução 003 (RF-008, pré-merge do PR de exclusão): rodada única, quatro CTs aprovados, sem regressão; reflexo da exclusão imediato via renovação da stream (`requisitos.md` 2.5). MVP completo. |
| 2026-07-21 | 1.3 | Wilson Gorosthides | Execução 004 (endereço opcional, pré-merge #61): rodada única, CT-001/CT-025 aprovados, sem regressão. |
| 2026-07-21 | 1.4 | Wilson Gorosthides | Execução 005 (múltiplos telefones, pré-merge #62): rodada única com a migração do Supabase (`telefone`→`telefones` text[]); CT-006/CT-026 aprovados, sem regressão. |
| 2026-07-21 | 1.5 | Wilson Gorosthides | Execução 006 (endereço estruturado, pré-merge #65): rodada única com a migração do Supabase (`endereco` text → jsonb); CT-027/CT-011/CT-025/CT-006/CT-008/CT-014 aprovados, sem regressão. |
| 2026-07-21 | 1.6 | Wilson Gorosthides | Execução 007 (abrir no Google Maps, pré-merge #66): rodada única, sem migração; CT-028 aprovado, sem regressão em edição e exclusão. |
| 2026-11-13 | 1.7 | Wilson Gorosthides | Execução 008 (agenda como tela inicial, pré-merge #75): rodada única no Chrome, com a criação da tabela `atendimentos` no Supabase; CT-029 a CT-039 aprovados, sem regressão no cadastro de clientes. |
| 2026-11-13 | 1.8 | Wilson Gorosthides | Execução 009 (registro de atendimento, #77, PR #89): rodada única no Chrome e no celular; CT-040 a CT-048 aprovados, sem migração. Registra a falha de rede do celular na primeira abertura (bug #47) e os achados #87 e #88. |
| 2026-11-13 | 1.9 | Wilson Gorosthides | Nova seção "Pilha de verificação manual (pendente)" e convenção correspondente: os passos manuais de cada entrega acumulam ali e são executados de uma vez antes do APK (replanejamento do fluxo; `plano-de-testes.md` 1.8). |
| 2026-11-13 | 1.10 | Wilson Gorosthides | Pilha: entram os passos do fix #87 (seleção ao trocar a semana). |
| 2026-11-13 | 1.11 | Wilson Gorosthides | Pilha: entram o SQL e os passos do RF-014 (#79, marcas de feito e pago). |
| 2026-11-16 | 1.12 | Wilson Gorosthides | Pilha: entram os passos do anotar sem internet (#94, RNF-007), sem SQL. |
| 2026-11-16 | 1.13 | Wilson Gorosthides | Pilha: entram os passos da identidade visual (#96, RNF-008), sem SQL. |
| 2026-11-16 | 1.14 | Wilson Gorosthides | Pilha: entram os passos dos avisos no celular (#95, RF-015), sem SQL. |
| 2026-11-16 | 1.15 | Wilson Gorosthides | Pilha: aviso de desinstalar o app antigo (identificador novo `br.com.msclean.agenda`) e de conferir a internet no APK de release (#23). |
| 2026-11-16 | 1.16 | Wilson Gorosthides | Pilha: SQL do RF-014 confirmado como aplicado; sai o bloco "SQL a aplicar". |
| 2026-11-16 | 1.17 | Wilson Gorosthides | Execução 010: blocos #87 e #79 da pilha aprovados no celular; saem da pilha. |
| 2026-11-16 | 1.18 | Wilson Gorosthides | Pilha: o passo 1 dos avisos (#95) passa a conferir também o pedido de bateria (#101). |
| 2026-11-16 | 1.19 | Wilson Gorosthides | Pilha: o pedido de notificação só aparece no Android 13+ (no 11 do desenvolvedor veio só o de bateria); passo dos avisos a repetir com o fix do fuso. |
| 2026-11-16 | 1.20 | Wilson Gorosthides | Pilha: entram os passos de trocar o dia e excluir atendimento (#106), sem SQL. |
| 2026-11-16 | 1.21 | Wilson Gorosthides | Execução 011: blocos #94, #96, #95 e #106 da pilha aprovados no celular (Android 11), com a ocorrência do fuso corrigida no PR #105; a pilha fica vazia. |
| 2026-11-16 | 1.22 | Wilson Gorosthides | Pilha: entram os passos do APK de release assinado com a chave própria (#109), sem SQL. |
| 2026-11-17 | 1.23 | Wilson Gorosthides | Execução 012: APK de release com a chave própria aprovado no celular (Android 16), incluindo a atualização por cima; a pilha fica vazia. |
| 2026-11-17 | 1.24 | Wilson Gorosthides | Pilha: entram os passos da busca por relevância e sem acento (#113), sem SQL. |
| 2026-11-17 | 1.25 | Wilson Gorosthides | Pilha: entram os passos do Salvar acima da barra de navegação (#118), sem SQL. |
| 2026-11-17 | 1.26 | Wilson Gorosthides | Pilha: entram os passos do cliente dos contatos do celular (#115), sem SQL. |
| 2026-11-17 | 1.27 | Wilson Gorosthides | Pilha: entram os passos do histórico do cliente (#81). |
| 2026-11-17 | 1.28 | Wilson Gorosthides | Execução 013 (pilha #81, #115, #118, #113: aprovada; bug #128 e achado #129); a pilha passa a ter só o passo do #128. |
| 2026-11-17 | 1.29 | Wilson Gorosthides | Execução 014 (#128: atendimento em dobro corrigido, aprovado); pilha vazia. |
| 2026-11-17 | 1.30 | Wilson Gorosthides | Pilha: SQL da tabela `precos` e os passos da tabela de preços (#123, RF-013 parte 1). |
| 2026-11-17 | 1.31 | Wilson Gorosthides | Pilha: SQL da `precos` (#123) confirmado como aplicado; entram os passos do valor calculado (#124, RF-013 parte 2). |
| 2026-11-17 | 1.32 | Wilson Gorosthides | Pilha: SQL das colunas de peça, variante, serviço e retrátil em `precos` e os passos do seletor de peças (#134, PR de interface). |
| 2026-11-17 | 1.33 | Wilson Gorosthides | Pilha #134: atendimento rápido, peças e valor na tela própria (CT-101); SQL das colunas de `precos` confirmado como aplicado. |
