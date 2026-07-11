# Matriz de Rastreabilidade — SGC para MSClean

> Liga cada RF do MVP ao seu **critério de aceitação** (copiado literalmente de
> `requisitos.md` §2) e ao **caso de teste** que o exercita. É o artefato que torna
> auditável a meta de cobertura do MVP: nenhum critério verificável fica descoberto.
>
> Vive em documento próprio porque muda a cada RF fechado (o caso de teste sai de
> "a definir" para o nome real), enquanto o `docs/plano-de-testes.md` é estável. O
> plano de testes (seção 7) referencia esta matriz; não a contém.

## Matriz RF ↔ Critério de aceitação ↔ Caso de teste

Casos de RFs ainda não implementados (RF-001, RF-002, RF-008) ficam **a definir**
até o teste ser escrito, na ordem "teste antes da feature".

| RF | Critério de aceitação (`requisitos.md` §2) | Caso de teste |
|---|---|---|
| RF-001 | Nome, Endereço e Telefone são campos obrigatórios. | `a definir` |
| RF-001 | Ao tentar salvar com qualquer campo obrigatório vazio (ou só com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem indicando o(s) campo(s) pendente(s). | `a definir` |
| RF-001 | O Telefone aceita apenas dígitos, espaços e os símbolos `+ ( ) -`; outros caracteres são rejeitados na validação. | `a definir` |
| RF-001 | Após salvar com sucesso, o novo cliente aparece na lista sem necessidade de recarregar a tela (atualização em tempo real via stream). | `a definir` |
| RF-001 | Após salvar, o formulário é fechado e o usuário retorna à lista. | `a definir` |
| RF-002 | O formulário de edição abre pré-preenchido com os dados atuais do cliente. | `a definir` |
| RF-002 | As mesmas validações do cadastro (RF-001) se aplicam: campos obrigatórios e formato de telefone. | `a definir` |
| RF-002 | Uma edição só é considerada salva após o usuário confirmar; nesse momento os dados são persistidos no banco e refletidos na lista em tempo real. | `a definir` |
| RF-002 | Ao cancelar, nenhuma alteração é gravada e os dados originais do cliente permanecem intactos. | `a definir` |
| RF-003 | A lista é ordenada por Nome em ordem alfabética crescente (ordenação padrão). | `home_screen_test: lista populada em ordem alfabética` |
| RF-003 | Cada item exibe, no mínimo, Nome e Endereço. | `home_screen_test: item exibe nome e endereço` |
| RF-003 | A lista reflete inserções, edições e exclusões em tempo real (stream), sem ação manual de atualização. | `home_screen_test: lista reage à emissão da stream` |
| RF-003 | Quando não há nenhum cliente cadastrado, a tela exibe a mensagem "Nenhum cliente encontrado." em vez de uma lista vazia silenciosa. | `home_screen_test: estado vazio exibe mensagem` |
| RF-004 | A busca filtra por **Nome** ou **Endereço** (correspondência de substring). | `supabase_service_test: filtro por nome ou endereço` |
| RF-004 | A busca é **case-insensitive** (não diferencia maiúsculas de minúsculas). | `supabase_service_test: filtro case-insensitive` |
| RF-004 | A lista é filtrada em tempo real conforme o usuário digita, sem necessidade de botão "buscar". | `home_screen_test: filtragem ao digitar na busca` |
| RF-004 | Quando nenhum cliente corresponde ao termo, a tela exibe a mensagem "Nenhum cliente encontrado.". | `home_screen_test: busca sem correspondência exibe mensagem` |
| RF-004 | Com o campo de busca vazio, todos os clientes são exibidos. | `home_screen_test: busca vazia exibe todos` |
| RF-008 | A exclusão exige confirmação explícita do usuário (diálogo "Confirmar exclusão?") antes de efetivar. | `a definir` |
| RF-008 | Ao cancelar a confirmação, o cliente **não** é removido e permanece na lista. | `a definir` |
| RF-008 | Ao confirmar, o cliente é removido do banco e desaparece da lista em tempo real. | `a definir` |
| RF-008 | Após a exclusão bem-sucedida, o sistema dá feedback visual (ex.: SnackBar "Cliente excluído"). | `a definir` |

Os nomes de caso de teste para RF-003 e RF-004 são o alvo pretendido da suíte; à
medida que os testes forem escritos, esta tabela é a fonte que confirma que nenhum
critério ficou descoberto.

## Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2026-07-11 | 1.0 | Wilson Gorosthides | Extração da matriz de rastreabilidade da seção 7 de `plano-de-testes.md` para documento próprio (RF do MVP ↔ critério de aceitação ↔ caso de teste). |
