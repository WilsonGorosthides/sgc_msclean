# Matriz de Rastreabilidade — SGC para MSClean

> Liga cada RF do MVP ao seu **critério de aceitação** (copiado literalmente de
> `requisitos.md` §2) e ao **caso de teste** que o exercita. É o artefato que torna
> auditável a meta de cobertura do MVP: nenhum critério verificável fica descoberto.
> Cada caso é identificado por um **CT-ID**, detalhado (pré-condições, passos,
> resultado esperado) em `docs/casos-de-teste.md`.
>
> Vive em documento próprio porque muda a cada RF fechado (o caso de teste sai de
> "a definir" para o nome real), enquanto o `docs/plano-de-testes.md` é estável. O
> plano de testes (seção 7) referencia esta matriz; não a contém.

## Matriz RF ↔ Critério de aceitação ↔ Caso de teste

Casos de RFs ainda não implementados (RF-001, RF-002, RF-008) ficam **a definir**
até o teste ser escrito, na ordem "teste antes da feature".

| RF | Critério de aceitação (`requisitos.md` §2) | Caso de teste |
|---|---|---|
| RF-001 | Nome, Endereço e Telefone são campos obrigatórios. | CT-001 — `client_form_screen_test: exige nome, endereço e telefone` |
| RF-001 | Ao tentar salvar com qualquer campo obrigatório vazio (ou só com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem indicando o(s) campo(s) pendente(s). | CT-002 — `client_form_screen_test: bloqueia salvar com campo vazio ou só espaços` |
| RF-001 | O Telefone aceita apenas dígitos, espaços e os símbolos `+ ( ) -`; outros caracteres são rejeitados na validação. | CT-003 — `validadores: telefone rejeita caracteres inválidos` · `client_form_screen_test: telefone rejeita caracteres inválidos` |
| RF-001 | Após salvar com sucesso, o novo cliente aparece na lista sem necessidade de recarregar a tela (atualização em tempo real via stream). | CT-004 — `home_screen_test: cliente salvo aparece na lista via stream` |
| RF-001 | Após salvar, o formulário é fechado e o usuário retorna à lista. | CT-005 — `client_form_screen_test: salvar fecha o formulário` |
| RF-002 | O formulário de edição abre pré-preenchido com os dados atuais do cliente. | CT-006 — a implementar |
| RF-002 | As mesmas validações do cadastro (RF-001) se aplicam: campos obrigatórios e formato de telefone. | CT-007 — a implementar |
| RF-002 | Uma edição só é considerada salva após o usuário confirmar; nesse momento os dados são persistidos no banco e refletidos na lista em tempo real. | CT-008 — a implementar |
| RF-002 | Ao cancelar, nenhuma alteração é gravada e os dados originais do cliente permanecem intactos. | CT-009 — a implementar |
| RF-003 | A lista é ordenada por Nome em ordem alfabética crescente (ordenação padrão). | CT-010 — `home_screen_test: lista populada em ordem alfabética` · `supabase_service_test: ordena por nome em ordem alfabética crescente` |
| RF-003 | Cada item exibe, no mínimo, Nome e Endereço. | CT-011 — `home_screen_test: item exibe nome e endereço` |
| RF-003 | A lista reflete inserções, edições e exclusões em tempo real (stream), sem ação manual de atualização. | CT-012 — `home_screen_test: lista reage à emissão da stream` |
| RF-003 | Quando não há nenhum cliente cadastrado, a tela exibe a mensagem "Nenhum cliente encontrado." em vez de uma lista vazia silenciosa. | CT-013 — `home_screen_test: estado vazio exibe mensagem` |
| RF-004 | A busca filtra por **Nome** ou **Endereço** (correspondência de substring). | CT-014 — `supabase_service_test: filtro por nome ou endereço` |
| RF-004 | A busca é **case-insensitive** (não diferencia maiúsculas de minúsculas). | CT-015 — `supabase_service_test: filtro case-insensitive` |
| RF-004 | A lista é filtrada em tempo real conforme o usuário digita, sem necessidade de botão "buscar". | CT-016 — `home_screen_test: filtragem ao digitar na busca` |
| RF-004 | Quando nenhum cliente corresponde ao termo, a tela exibe a mensagem "Nenhum cliente encontrado.". | CT-017 — `home_screen_test: busca sem correspondência exibe mensagem` |
| RF-004 | Com o campo de busca vazio, todos os clientes são exibidos. | CT-018 — `home_screen_test: busca vazia exibe todos` |
| RF-008 | A exclusão exige confirmação explícita do usuário (diálogo "Confirmar exclusão?") antes de efetivar. | CT-019 — a implementar |
| RF-008 | Ao cancelar a confirmação, o cliente **não** é removido e permanece na lista. | CT-020 — a implementar |
| RF-008 | Ao confirmar, o cliente é removido do banco e desaparece da lista em tempo real. | CT-021 — a implementar |
| RF-008 | Após a exclusão bem-sucedida, o sistema dá feedback visual (ex.: SnackBar "Cliente excluído"). | CT-022 — a implementar |

Os casos de teste de RF-003 e RF-004 estão **implementados e passando** — vivem em
`test/unit/supabase_service_test.dart` e `test/widget/home_screen_test.dart`, com
os nomes exatos desta tabela (issue #28). À medida que os demais RFs forem
desenvolvidos, esta tabela é a fonte que confirma que nenhum critério ficou
descoberto.

## Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2026-07-11 | 1.0 | Wilson Gorosthides | Extração da matriz de rastreabilidade da seção 7 de `plano-de-testes.md` para documento próprio (RF do MVP ↔ critério de aceitação ↔ caso de teste). |
| 2026-07-13 | 1.1 | Wilson Gorosthides | Casos de teste de RF-003 e RF-004 confirmados: deixam de ser alvo pretendido e passam a existir na suíte (`test/unit/`, `test/widget/`), implementados na issue #28. |
| 2026-07-13 | 1.2 | Wilson Gorosthides | Adiciona `supabase_service_test: ordena por nome em ordem alfabética crescente` ao critério de ordenação do RF-003 — o caso de widget cobre a renderização; este cobre a ordenação pedida ao Supabase (bug da issue #39). |
| 2026-07-15 | 1.3 | Wilson Gorosthides | Coluna "Caso de teste" passa a referenciar os CT-IDs de `docs/casos-de-teste.md` (CT-001 a CT-022): "a definir" vira "CT-NNN — a implementar" e os testes existentes ganham o prefixo do seu CT. |
| 2026-07-15 | 1.4 | Wilson Gorosthides | CT-001 a CT-005 confirmados com os nomes reais dos testes da suíte (RF-001 implementado, issue #25). |
