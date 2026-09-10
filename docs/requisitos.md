# Documento de Requisitos de Software (DRS) - SGC para MSClean

## 1. Introdução

Este documento detalha os requisitos funcionais e não funcionais do Sistema de Gestão de Clientes (SGC) da MSClean. Serve de guia para as fases de design, desenvolvimento e teste.

Decisões históricas de escopo e priorização estão registradas em `docs/AUDITORIA_INICIAL.md`.

Cada requisito funcional é acompanhado de critérios de aceitação verificáveis
(bullets objetivos, passíveis de teste).

Cada RF com História de Usuário escrita (seção 4) pode ser rastreado no GitHub como
uma issue **Story** (label `story`) que agrega a(s) issue(s) `feat` de implementação
como sub-issues nativas — ver `docs/gerencia-de-configuracao.md` §7.

## 2. Requisitos Funcionais (RFs)

### 2.1 Gestão de Clientes

#### RF-001 - Cadastro de Cliente
O sistema deve permitir o cadastro de novos clientes.

* **Dados:** Nome, Endereço (estruturado: logradouro, número, bairro, complemento, ponto de referência), Telefone(s).
* **Critérios de aceitação:**
  - Nome e **ao menos um Telefone** são obrigatórios. Endereço é **opcional** (um cliente em potencial pode ser cadastrado antes de ter endereço).
  - Ao tentar salvar com Nome ou Telefone vazio (ou só com espaços em branco), o sistema bloqueia o salvamento e exibe mensagem indicando o(s) campo(s) pendente(s).
  - O **Endereço é estruturado** em campos: logradouro (rua/avenida), número, bairro, complemento (bloco, apto, torre) e ponto de referência. Todos os campos são opcionais. Não há campo de cidade: a área de atendimento é só Campo Grande - MS (a cidade entra como âncora fixa na consulta ao mapa; reavaliar se a área mudar).
  - Ao salvar **sem endereço** (nenhum campo do endereço preenchido), o sistema pede confirmação ("Cliente sem endereço. Deseja salvar mesmo assim?"); ao confirmar, grava; ao cancelar, permanece no formulário.
  - O cliente pode ter **um ou mais telefones**: o formulário permite adicionar e remover campos de telefone (mínimo um), e cada número é validado individualmente.
  - Cada Telefone aceita apenas dígitos, espaços e os símbolos `+ ( ) -`; outros caracteres são rejeitados na validação.
  - Cada Telefone deve conter no mínimo **8 dígitos**; apenas dígitos contam na verificação (espaços e os símbolos `+ ( ) -` são ignorados na contagem).
  - Após salvar com sucesso, o novo cliente aparece na lista sem necessidade de recarregar a tela (atualização em tempo real via stream).
  - Após salvar, o formulário é fechado e o usuário retorna à lista.

#### RF-002 - Edição de Cliente
O usuário deve ser capaz de editar as informações de um cliente existente.

* **Critérios de aceitação:**
  - O formulário de edição abre pré-preenchido com os dados atuais do cliente.
  - As mesmas validações do cadastro (RF-001) se aplicam: campos obrigatórios e formato de telefone.
  - Uma edição só é considerada salva após o usuário confirmar; nesse momento os dados são persistidos no banco e refletidos na lista imediatamente ao retornar do formulário.
  - Ao cancelar, nenhuma alteração é gravada e os dados originais do cliente permanecem intactos.

#### RF-003 - Visualização da Lista
O sistema deve exibir uma lista de todos os clientes cadastrados.

* **Critérios de aceitação:**
  - A lista é ordenada por Nome em ordem alfabética crescente (ordenação padrão).
  - Cada item exibe, no mínimo, Nome e um resumo do endereço (logradouro, número — bairro); quando o cliente não tem endereço, um texto discreto "Sem endereço" ocupa o lugar.
  - A lista reflete inserções, edições e exclusões em tempo real (stream), sem ação manual de atualização.
  - Quando não há nenhum cliente cadastrado, a tela exibe a mensagem "Nenhum cliente encontrado." em vez de uma lista vazia silenciosa.

#### RF-004 - Busca
O sistema deve permitir a busca de clientes por palavra-chave.

* **Critérios de aceitação:**
  - A busca filtra por **Nome** ou por **qualquer campo do Endereço** (logradouro, número, bairro, complemento, referência) — correspondência de substring.
  - A busca é **case-insensitive** (não diferencia maiúsculas de minúsculas).
  - A lista é filtrada em tempo real conforme o usuário digita, sem necessidade de botão "buscar".
  - Quando nenhum cliente corresponde ao termo, a tela exibe a mensagem "Nenhum cliente encontrado.".
  - Com o campo de busca vazio, todos os clientes são exibidos.

#### RF-008 - Exclusão de Cliente
O sistema deve permitir excluir um cliente existente.

* **Critérios de aceitação:**
  - A exclusão exige confirmação explícita do usuário (diálogo "Confirmar exclusão?") antes de efetivar.
  - Ao cancelar a confirmação, o cliente **não** é removido e permanece na lista.
  - Ao confirmar, o cliente é removido do banco e desaparece da lista imediatamente após a confirmação.
  - Após a exclusão bem-sucedida, o sistema dá feedback visual (ex.: SnackBar "Cliente excluído").

#### RF-009 - Abrir Endereço no Mapa
O sistema deve permitir abrir o endereço de um cliente no Google Maps.

* **Critérios de aceitação:**
  - A partir de um cliente **com endereço**, uma ação (ícone de mapa no item da lista) abre o endereço no Google Maps.
  - A consulta ao mapa usa os campos de "chegar" (logradouro, número, bairro) com **Campo Grande - MS** como âncora fixa; complemento e ponto de referência não entram (atrapalham a geolocalização).
  - Quando o cliente **não tem endereço**, a ação não é exibida.

### 2.2 Agenda e Atendimentos

> **Origem.** Esta seção nasceu do levantamento de campo com a proprietária em
> 2026-09-10 — observação da agenda de papel em uso e entrevista sobre casos
> concretos. Três achados a orientam:
>
> 1. **A informação de um trabalho vive partida.** O valor e a negociação ficam na
>    conversa de WhatsApp (e, mais recentemente, no Instagram); a data, a hora e o
>    local ficam na agenda de papel. Uma linha típica do papel é
>    `Cristiane   11:30   altos da afonso pena`.
> 2. **O preço cobrado de um cliente recorrente não está em lugar recuperável.**
>    Descobri-lo exige reler conversas antigas — citado por ela como a maior perda
>    de tempo.
> 3. **O agendamento duplicado já aconteceu**, e a causa foi a *etapa de
>    transcrição*: o serviço foi combinado na conversa para ser passado ao papel
>    depois, e não foi. Qualquer solução que também exija "passar depois" reproduz
>    o mesmo defeito — daí o RNF-006.

#### RF-005 - Registrar Atendimento
O sistema deve permitir registrar um atendimento em uma data da agenda.

* **Dados:** Data, Hora, Cliente, Local (opcional), Valor (opcional), Observação (opcional).
* **Critérios de aceitação:**
  - O registro parte de um dia da agenda: a Data já vem preenchida com o dia selecionado.
  - **Cliente e Hora são obrigatórios**; Local, Valor e Observação são opcionais.
  - O Cliente pode ser escolhido entre os cadastrados **ou** informado por um nome ainda não cadastrado. Neste segundo caso o sistema cria um **cliente provisório** apenas com o nome — exceção deliberada ao RF-001, que exige ao menos um telefone. A exceção existe porque o registro precisa caber no momento em que o serviço é combinado; exigir telefone e endereço ali é o atrito que hoje empurra a anotação para depois.
  - O cliente provisório é sinalizado na lista de clientes até ser completado.
  - Quando o Cliente escolhido **já tem atendimento anterior**, os campos Valor e Observação vêm pré-preenchidos com os do atendimento mais recente daquele cliente, e podem ser alterados antes de salvar.
  - Quando o Cliente tem endereço cadastrado, o Local vem pré-preenchido com o resumo do endereço (mesmo resumo do RF-003), e pode ser alterado.
  - Ao salvar, o atendimento passa a constar no dia correspondente da agenda.
  - O valor é opcional porque nem todo atendimento tem preço definido no momento em que é marcado.

#### RF-010 - Agenda por Data
O sistema deve exibir os atendimentos organizados por dia, e abrir nessa visão.

* **Critérios de aceitação:**
  - Ao abrir o aplicativo, o sistema exibe a agenda posicionada no **dia de hoje**.
  - Os atendimentos do dia selecionado são listados em **ordem crescente de hora**.
  - O usuário navega para outros dias sem precisar digitar uma data.
  - Um dia sem atendimentos exibe a mensagem "Nenhum atendimento neste dia." em vez de uma lista vazia silenciosa (consistente com o RF-003).
  - Na navegação entre dias, os dias que possuem ao menos um atendimento são visualmente distinguíveis dos vazios.
  - A lista de clientes (RF-003) continua acessível, deixando de ser a tela inicial.

#### RF-011 - Consultar o Valor Cobrado de um Cliente
O sistema deve permitir consultar quanto foi cobrado de um cliente.

* **Critérios de aceitação:**
  - A partir de um cliente, o sistema exibe o **valor do atendimento mais recente** que tenha valor registrado, junto da data desse atendimento.
  - O sistema exibe o histórico dos valores anteriores daquele cliente, do mais recente para o mais antigo, com a data de cada um.
  - Quando o cliente não tem nenhum atendimento com valor registrado, o sistema exibe "Sem valor registrado" em vez de campo vazio ou zero.

#### RF-012 - Aviso de Conflito de Horário
O sistema deve avisar quando um atendimento é marcado em horário já ocupado.

* **Critérios de aceitação:**
  - Ao salvar um atendimento, se já existir outro no **mesmo dia** com horário a **menos de 1 hora** de distância, o sistema exibe um aviso antes de gravar.
  - O aviso identifica o atendimento conflitante por **cliente e hora**.
  - O aviso **não bloqueia**: a usuária pode confirmar mesmo assim (e o atendimento é gravado) ou voltar e ajustar o horário.
  - **Limitação assumida:** a duração do serviço não é modelada nesta versão, então o conflito é aproximado pela janela fixa de 1 hora. Se a janela se mostrar imprecisa no uso real, a decisão a rever é modelar a duração — não ajustar o número.

### 2.3 Pagamentos e Acesso

#### RF-006 - Adicionar Histórico de Pagamento
Para cada cliente, o usuário deve poder adicionar um registro de pagamento.

* **Dados:** Data, Valor Pago, Método de Pagamento (ex.: Pix, Dinheiro).
* **Nota de prioridade:** no levantamento de 2026-09-10 a proprietária declarou não
  fazer controle financeiro — tem noção do ganho líquido, sem exatidão, e **não pediu
  relatório**. Como o RF-005 já registra o valor por atendimento, o total por período
  passa a ser derivável sem esforço adicional. Este RF permanece especificado e **não
  priorizado** até que a necessidade apareça no uso.

#### RF-007 - Autenticação de Usuário Único
O sistema deve ter um mecanismo de login para o único usuário (a proprietária da empresa).

* **Nota:** A usuária é única no próprio dispositivo; o controle de acesso é exercido por RLS no Supabase (ver RNF-005).

## 3. Requisitos Não Funcionais (RNFs)

* **RNF-001 - Usabilidade:** Todas as ações principais (cadastrar, buscar, editar, excluir) devem ser alcançáveis em no máximo 2 toques a partir da tela inicial, sem necessidade de treinamento prévio.
* **RNF-002 - Desempenho:** Operações de busca, cadastro, edição e exclusão devem responder em menos de 2 segundos para uma base de até 500 clientes, em uso por um único usuário.
* **RNF-003 - Compatibilidade de Plataforma:** A aplicação deve compilar e funcionar a partir de um único código-fonte Flutter em **Android** e em **navegadores web (desktop)**.
* **RNF-004 - Sincronização de Dados:** Os dados gravados em uma plataforma devem aparecer na outra sem ação manual de atualização, por meio da stream em tempo real do Supabase (latência típica inferior a 2 segundos).
* **RNF-005 - Segurança:** O acesso ao banco deve ser controlado por **Row Level Security (RLS)** no Supabase; no cliente expõe-se apenas a `anonKey` pública. As credenciais (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) são carregadas de um arquivo `.env` fora do controle de versão, e um `.env.example` documenta as chaves esperadas.
* **RNF-006 - Velocidade de Registro:** Registrar um atendimento para um cliente que já tem atendimento anterior deve ser possível em **no máximo 4 toques** a partir da agenda, sem digitação além da escolha do cliente e do horário. Motivo: o registro compete com anotar uma linha no papel; se for mais lento, a anotação volta para o papel — e é justamente o adiamento da anotação que causou o agendamento duplicado.
* **RNF-007 - Tolerância a Conexão Fraca:** Um atendimento registrado **não pode ser perdido** quando a rede está lenta ou falha. A gravação é confirmada ao usuário localmente e sincronizada quando a conexão permitir; a interface não fica bloqueada aguardando a rede. Motivo: a proprietária registra atendimentos no carro e na casa dos clientes, onde o sinal às vezes é fraco (levantamento de 2026-09-10). O sinal é **fraco, não ausente** — o que exige resiliência na escrita, não uma arquitetura offline-first.

## 4. Histórias de Usuário (User Stories)

* **História 1: Adicionar um Cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** um botão para adicionar um novo cliente,
    * **Para que** eu possa registrar as informações de contato de forma organizada.
* **História 2: Encontrar um Cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** uma barra de busca na lista de clientes,
    * **Para que** eu possa encontrar rapidamente o cliente que preciso.
* **História 3: Editar dados de um cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** corrigir informações desatualizadas de um cliente,
    * **Para que** meus contatos estejam sempre certos.
* **História 4: Excluir um cliente**
    * **Como** proprietária da empresa,
    * **Eu quero** remover clientes que não atendo mais,
    * **Para que** minha lista permaneça limpa e relevante.
* **História 5: Registrar um atendimento no dia**
    * **Como** proprietária da empresa,
    * **Eu quero** registrar o atendimento no dia em que ele acontece, no momento em que combino com a cliente,
    * **Para que** nada se perca entre a conversa e a agenda.
* **História 6: Ver o meu dia**
    * **Como** proprietária da empresa,
    * **Eu quero** abrir o aplicativo e já ver os atendimentos de hoje,
    * **Para que** eu saiba para onde vou sem precisar consultar o caderno.
* **História 7: Lembrar quanto eu cobro**
    * **Como** proprietária da empresa,
    * **Eu quero** ver quanto cobrei de uma cliente da última vez,
    * **Para que** eu não perca tempo procurando o valor em conversas antigas.
* **História 8: Não marcar duas clientes no mesmo horário**
    * **Como** proprietária da empresa,
    * **Eu quero** ser avisada quando já tenho algo marcado naquele horário,
    * **Para que** eu não agende duas clientes ao mesmo tempo, como já aconteceu.

## 5. Fluxo de Casos de Uso Principal

* **UC-001 - Gerenciar Clientes**
    1.  A partir da agenda (UC-002), o usuário acessa a lista de clientes.
    2.  O sistema exibe a lista de clientes (ordenada por nome).
    3.  **Cenário A - Adicionar:** O usuário clica em "Adicionar Cliente", preenche o formulário e salva. O cliente aparece na lista em tempo real.
    4.  **Cenário B - Buscar:** O usuário digita na barra de busca. A lista é filtrada em tempo real por nome ou endereço.
    5.  **Cenário C - Editar:** O usuário toca em um cliente da lista; o sistema abre o formulário pré-preenchido com os dados atuais. O usuário ajusta os campos necessários e confirma. A alteração aparece na lista em tempo real.
    6.  **Cenário D - Excluir:** O usuário aciona a opção de excluir um cliente; o sistema solicita confirmação explícita. Ao confirmar, o cliente é removido do banco e desaparece da lista em tempo real, com feedback visual ao usuário.
    7.  **Cenário E - Abrir no mapa:** A partir de um cliente com endereço, o usuário toca no ícone de mapa; o sistema abre o endereço no Google Maps na localização.

* **UC-002 - Gerenciar a Agenda**
    1.  O usuário abre o aplicativo.
    2.  O sistema exibe a agenda posicionada no dia de hoje, com os atendimentos em ordem de hora.
    3.  **Cenário A - Registrar:** O usuário seleciona o dia, aciona a opção de adicionar e escolhe o cliente. Se o cliente já tem atendimento anterior, valor e observação vêm pré-preenchidos, e o local vem do endereço cadastrado. O usuário confirma e o atendimento passa a constar no dia.
    4.  **Cenário B - Cliente novo:** No mesmo formulário, o usuário informa um nome ainda não cadastrado; o sistema cria um cliente provisório com esse nome e segue com o registro.
    5.  **Cenário C - Navegar entre dias:** O usuário avança ou retrocede o dia; a agenda mostra os atendimentos daquele dia, ou a mensagem de dia vazio.
    6.  **Cenário D - Conflito de horário:** Ao salvar em horário próximo a outro atendimento do mesmo dia, o sistema avisa identificando o conflito; o usuário confirma mesmo assim ou volta e ajusta.
    7.  **Cenário E - Consultar valor:** A partir de um cliente, o usuário vê o último valor cobrado, com a data, e o histórico dos valores anteriores.

## 6. Histórico de Versões

| Data | Versão | Autor | Descrição da mudança |
|---|---|---|---|
| 2025-09-11 | 1.0 | Wilson Gorosthides | Versão inicial dos requisitos. |
| 2026-06-27 | 2.0 | Wilson Gorosthides | Sincronização com a auditoria inicial: stack Supabase, escopo MVP (RF-001 a RF-004 + RF-008), critérios de aceitação verificáveis, RNFs tornados verificáveis, remoção do login do UC-001, RF-005/006/007 e História "Registrar um Serviço" movidos para Pós-MVP; novas histórias de editar e excluir cliente. |
| 2026-06-27 | 2.1 | Wilson Gorosthides | Ajustes no UC-001: remove o Cenário C - Detalhes (não implementado, apenas `print` no código), adiciona Cenário C - Editar e Cenário D - Excluir. |
| 2026-07-03 | 2.2 | Wilson Gorosthides | Adiciona nota em §1 ligando RF → História de Usuário → issue Story e um pointer geral para `docs/AUDITORIA_INICIAL.md`; remove a distinção MVP/Pós-MVP (RF-005/006/007 incorporados à seção 2, História 5 à seção 4, sem tags de status), preservando em RF-007 a nota técnica sobre RLS/RNF-005; Histórico de Versões renumerado de §7 para §6. |
| 2026-07-18 | 2.3 | Wilson Gorosthides | Novo critério de aceitação no RF-001: telefone com no mínimo 8 dígitos, contando apenas dígitos (decisão de requisito da issue #48; piso pode subir para 10 após a importação da agenda real, #23). |
| 2026-07-19 | 2.4 | Wilson Gorosthides | RF-002: critério de reflexo da edição renegociado de "em tempo real" para "imediatamente ao retornar do formulário" — os eventos UPDATE do realtime não são entregues pelo projeto Supabase atual (diagnóstico e caminho de restauração na issue #57). |
| 2026-07-20 | 2.5 | Wilson Gorosthides | RF-008: critério de reflexo da exclusão renegociado de "em tempo real" para "imediatamente após a confirmação" — por consistência com o RF-002 e por robustez, a lista é renovada após a exclusão, independentemente de o evento DELETE nativo do realtime ser entregue (não presumido como quebrado; contexto na issue #57). |
| 2026-07-21 | 2.6 | Wilson Gorosthides | RF-001: Endereço passa a ser **opcional** (com aviso de confirmação ao salvar vazio) — um cliente em potencial pode ser cadastrado sem endereço; preparação para a importação da agenda real (issue #61). |
| 2026-07-21 | 2.7 | Wilson Gorosthides | RF-001: cliente passa a ter **um ou mais telefones** (mínimo um), com campos adicionáveis/removíveis no formulário e validação por número — realidade da agenda real (issue #62). |
| 2026-07-21 | 2.9 | Wilson Gorosthides | Novo **RF-009** — abrir o endereço do cliente no Google Maps (ícone de mapa no item, só quando há endereço; consulta pelos campos de chegar com Campo Grande - MS como âncora); Cenário E no UC-001 (issue #66). |
| 2026-09-10 | 3.0 | Wilson Gorosthides | **A agenda por data passa a ser o centro do produto**, a partir do levantamento de campo com a proprietária (§2.2, "Origem"). Seção 2 reorganizada em 2.1 Gestão de Clientes, 2.2 Agenda e Atendimentos e 2.3 Pagamentos e Acesso. RF-005 reescrito de "histórico de serviço por cliente" para "registrar atendimento em uma data", com pré-preenchimento a partir do atendimento anterior e criação de cliente provisório (exceção declarada ao RF-001). Novos RF-010 (agenda por data como tela inicial), RF-011 (consultar o valor cobrado) e RF-012 (aviso de conflito de horário). Novos RNF-006 (teto de toques para registrar) e RNF-007 (tolerância a conexão fraca). História 5 reescrita e novas Histórias 6, 7 e 8; novo UC-002 e UC-001 deixa de iniciar no aplicativo. RF-006 marcado como não priorizado (a proprietária não faz controle financeiro e não pediu relatório). |
| 2026-07-21 | 2.8 | Wilson Gorosthides | Endereço passa a ser **estruturado** (logradouro, número, bairro, complemento, ponto de referência), todos opcionais — RF-001 (dados e aviso por endereço vazio), RF-003 (item exibe resumo) e RF-004 (busca por qualquer campo do endereço). Sem campos de CEP e cidade (decisão de simplicidade: na prática não seriam preenchidos; a área de atendimento é só Campo Grande - MS, âncora fixa na consulta ao mapa). Modela casa/apartamento/condomínio e prepara a abertura no mapa (issue #65). Requer migração no Supabase (`endereco` text → jsonb). |
