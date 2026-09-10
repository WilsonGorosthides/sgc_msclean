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
> 2026-09-10: entrevista sobre casos concretos e **fotografia de quatro páginas da
> agenda de papel em uso**. As fotos não são versionadas — contêm nome e endereço
> de clientes reais. O que segue é o formato observado, com dados fictícios.
>
> **O que uma página tem, de fato:**
>
> ```
> [hora?]  Nome do cliente                    ✓
>          Rua Tal 570 — Bairro Tal
>          (ou: Condomínio Tal / Torre Tal / Apto 302)
>          tapete 8 x 4,5 · poltrona · 6 folhas de cortina
> ─────────────────────────  (linha separando o próximo do mesmo dia)
> ```
>
> Cinco achados orientam os requisitos desta seção:
>
> 1. **O serviço é uma lista de peças, não um texto.** As páginas trazem `tapete`,
>    `poltrona`, `cortina`, `sofá`, e o tapete vem com **medida** (`8 x 4,5`). O
>    negócio é higienização de estofados e tapetes, cobrada por peça e por metragem
>    — não faxina por hora.
> 2. **A proprietária cobra por metro quadrado**, e o valor do metro **precisa ser
>    editável por ela**. Daí o RF-013: uma tabela de preços que ela mantém, e um
>    valor calculado que ela pode sobrescrever.
> 3. **Ela não anota horário.** Divide o dia em **períodos** (manhã/tarde), avalia
>    a rota mais próxima e acerta o horário exato na conversa ("primeiro horário",
>    "depois das 9"). Hora existe, mas como refinamento — nunca como obrigação.
> 4. **A informação de um trabalho vive partida.** Valor e negociação ficam na
>    conversa de WhatsApp (e, agora, no Instagram); data, local e peças ficam no
>    papel. Descobrir quanto se cobra de um cliente recorrente exige reler conversas
>    antigas — citado por ela como a maior perda de tempo. O segundo dado mais
>    consultado é **quando foi a última visita**, porque o serviço é periódico.
>    Ambos no RF-011.
> 5. **O agendamento duplicado já aconteceu**, e a causa foi a *etapa de
>    transcrição*: o serviço foi combinado na conversa para ser passado ao papel
>    depois, e não foi. Qualquer solução que também exija "passar depois" reproduz
>    o mesmo defeito — daí o RNF-006.
>
> As marcas de conferido (✓ e riscos) ao lado das linhas registram **dois estados
> distintos** — serviço feito e cliente pagou —, e um não vale pelo outro. Daí o
> RF-014.

#### RF-005 - Registrar Atendimento
O sistema deve permitir registrar um atendimento em uma data da agenda.

* **Dados:** Data, **Período** (manhã/tarde), Hora (opcional), Cliente, Local (opcional), **Peças do serviço**, Valor, Observação (opcional).
* **Critérios de aceitação:**
  - O registro parte de um dia da agenda: a Data já vem preenchida com o dia selecionado.
  - **Cliente e Período são obrigatórios.** **Hora é opcional** — a proprietária organiza o dia por período e acerta o horário exato na conversa, conforme a rota; exigir hora no registro obrigaria a inventar um dado que ela não tem no momento.
  - Quando informada, a Hora pode ser alterada depois sem refazer o atendimento.
  - As **Peças do serviço** são uma lista: cada peça tem **tipo** (tapete, sofá, poltrona, cortina, colchão, outro), **quantidade** e, quando o tipo é medido por metragem, **largura e comprimento**. Uma peça sem medida é registrada apenas por quantidade.
  - O **Valor** é calculado a partir das peças e da tabela de preços (RF-013) e **pode ser sobrescrito** pela proprietária antes de salvar.
  - O Cliente pode ser escolhido entre os cadastrados **ou** informado por um nome ainda não cadastrado. Neste segundo caso o sistema cria um **cliente provisório** apenas com o nome — exceção deliberada ao RF-001, que exige ao menos um telefone. A exceção existe porque o registro precisa caber no momento em que o serviço é combinado; exigir telefone e endereço ali é o atrito que hoje empurra a anotação para depois.
  - O cliente provisório é sinalizado na lista de clientes até ser completado.
  - Quando o Cliente escolhido **já tem atendimento anterior**, as Peças e a Observação vêm pré-preenchidas com as do atendimento mais recente daquele cliente, e podem ser alteradas antes de salvar.
  - Quando o Cliente tem endereço cadastrado, o Local vem pré-preenchido com o resumo do endereço (mesmo resumo do RF-003), e pode ser alterado.
  - Ao salvar, o atendimento passa a constar no dia e no período correspondentes da agenda.

#### RF-010 - Agenda por Data
O sistema deve exibir os atendimentos organizados por dia, e abrir nessa visão.

* **Critérios de aceitação:**
  - Ao abrir o aplicativo, o sistema exibe a agenda posicionada no **dia de hoje**.
  - Os atendimentos do dia selecionado são agrupados por **período** (manhã, depois tarde) e, dentro do período, ordenados por hora quando houver — os sem hora aparecem depois dos com hora, na ordem em que foram registrados.
  - Cada período exibe **quantos atendimentos tem**, para que a carga do dia seja visível antes de aceitar mais um.
  - O usuário navega para outros dias sem precisar digitar uma data.
  - Um dia sem atendimentos exibe a mensagem "Nenhum atendimento neste dia." em vez de uma lista vazia silenciosa (consistente com o RF-003).
  - Na navegação entre dias, os dias que possuem ao menos um atendimento são visualmente distinguíveis dos vazios.
  - A lista de clientes (RF-003) continua acessível, deixando de ser a tela inicial.

#### RF-011 - Consultar o Histórico de um Cliente
O sistema deve permitir consultar, para um cliente, **quanto foi cobrado** e **quando foi a última visita**.

> São as duas informações que a proprietária mais procura, e hoje ambas custam caro:
> o valor está enterrado em conversas de WhatsApp, e a data exige folhear o caderno.
> O serviço é periódico — saber quando revisitar é o que gera o próximo trabalho.

* **Critérios de aceitação:**
  - A partir de um cliente, o sistema exibe a **data do atendimento mais recente** e **há quanto tempo** ele foi (ex.: "há 3 meses").
  - O sistema exibe o **valor do atendimento mais recente** que tenha valor registrado, junto da data desse atendimento e das peças que o compuseram.
  - O sistema exibe o histórico dos atendimentos anteriores daquele cliente, do mais recente para o mais antigo, com data, peças e valor de cada um.
  - Quando o cliente não tem nenhum atendimento registrado, o sistema exibe "Nenhum atendimento registrado" em vez de campos vazios ou zero.

#### RF-012 - Aviso de Conflito de Horário
O sistema deve avisar quando um atendimento é marcado em horário já ocupado.

* **Critérios de aceitação:**
  - O aviso só se aplica quando **os dois atendimentos têm hora informada** — sem hora não há conflito a detectar, e inventar um seria alarme falso.
  - Ao salvar um atendimento **com hora**, se já existir outro no mesmo dia **com hora** a menos de 1 hora de distância, o sistema exibe um aviso antes de gravar.
  - O aviso identifica o atendimento conflitante por **cliente e hora**.
  - O aviso **não bloqueia**: a usuária pode confirmar mesmo assim (e o atendimento é gravado) ou voltar e ajustar o horário.
  - **Limitação assumida:** a duração do serviço não é modelada nesta versão, então o conflito é aproximado pela janela fixa de 1 hora. Se a janela se mostrar imprecisa no uso real, a decisão a rever é modelar a duração — não ajustar o número.
  - Para os atendimentos **sem hora**, a proteção contra excesso não é o aviso, e sim a contagem por período exibida no RF-010: a carga do dia fica visível antes de aceitar mais um.

#### RF-013 - Tabela de Preços e Cálculo por Metragem
O sistema deve calcular o valor de um atendimento a partir das peças, usando uma tabela de preços que a proprietária mantém.

* **Critérios de aceitação:**
  - A proprietária pode **editar a tabela de preços**: para cada tipo de peça, a unidade de cobrança (**metro quadrado** ou **peça**) e o valor correspondente.
  - Para peças cobradas por metro quadrado, o sistema calcula a área a partir de largura × comprimento e multiplica pelo valor do metro (ex.: `8 × 4,5 = 36 m²`).
  - Para peças cobradas por peça, o sistema multiplica o valor pela quantidade.
  - O valor total do atendimento é a soma das peças, exibido enquanto elas são informadas.
  - O valor calculado é **sugestão, não imposição**: a proprietária pode sobrescrevê-lo no atendimento (desconto, combinado diferente) sem alterar a tabela.
  - Alterar a tabela de preços **não altera** o valor de atendimentos já registrados.

#### RF-014 - Estados de Conclusão do Atendimento
Um atendimento tem dois estados independentes: **serviço feito** e **cliente pagou**.

> Na agenda de papel, esses estados aparecem como marcas de conferido ao lado da
> linha. A proprietária foi explícita: um não vale pelo outro — não adianta o
> cliente ter pago se o serviço ainda não foi feito, nem o contrário.

* **Critérios de aceitação:**
  - Cada atendimento tem dois marcadores **independentes**: *serviço feito* e *cliente pagou*, cada um podendo ser ligado e desligado.
  - Um atendimento é considerado **concluído** somente quando **os dois** estão marcados.
  - A agenda distingue visualmente três situações: nada marcado, um dos dois marcado, e concluído.
  - Marcar ou desmarcar não exige abrir o formulário de edição do atendimento.

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
* **RNF-006 - Velocidade de Registro:** Registrar um atendimento para um cliente que já tem atendimento anterior deve ser possível em **no máximo 4 toques** a partir da agenda — dia, cliente, período e confirmar —, sem digitação, aproveitando as peças e o valor do atendimento anterior. Motivo: o registro compete com anotar uma linha no papel; se for mais lento, a anotação volta para o papel — e é justamente o adiamento da anotação que causou o agendamento duplicado.
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
* **História 7: Lembrar quanto eu cobro e quando estive lá**
    * **Como** proprietária da empresa,
    * **Eu quero** ver quanto cobrei de uma cliente da última vez e há quanto tempo foi,
    * **Para que** eu não perca tempo procurando em conversas antigas e saiba quando voltar.
* **História 9: Calcular o preço na hora**
    * **Como** proprietária da empresa,
    * **Eu quero** informar as peças e as medidas e ver o valor sair pronto,
    * **Para que** eu passe o orçamento na conversa sem fazer conta no papel.
* **História 10: Saber o que já fechou**
    * **Como** proprietária da empresa,
    * **Eu quero** marcar separadamente que o serviço foi feito e que a cliente pagou,
    * **Para que** eu não confunda trabalho entregue com dinheiro recebido.
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
    3.  **Cenário A - Registrar:** O usuário seleciona o dia, aciona a opção de adicionar, escolhe o cliente e o período. Se o cliente já tem atendimento anterior, as peças, o valor e a observação vêm pré-preenchidos, e o local vem do endereço cadastrado. O usuário confirma e o atendimento passa a constar no dia, dentro do período.
    4.  **Cenário B - Cliente novo:** No mesmo formulário, o usuário informa um nome ainda não cadastrado; o sistema cria um cliente provisório com esse nome e segue com o registro.
    5.  **Cenário C - Navegar entre dias:** O usuário avança ou retrocede o dia; a agenda mostra os atendimentos daquele dia, ou a mensagem de dia vazio.
    6.  **Cenário D - Conflito de horário:** Ao salvar em horário próximo a outro atendimento do mesmo dia, o sistema avisa identificando o conflito; o usuário confirma mesmo assim ou volta e ajusta.
    7.  **Cenário E - Consultar histórico:** A partir de um cliente, o usuário vê há quanto tempo foi a última visita, o último valor cobrado com as peças que o compuseram, e o histórico dos atendimentos anteriores.
    8.  **Cenário F - Orçar pelas peças:** Ao informar as peças e as medidas, o sistema calcula o valor pela tabela de preços; o usuário aceita o valor calculado ou digita outro.
    9.  **Cenário G - Fechar o atendimento:** Na agenda, o usuário marca *serviço feito* e, quando receber, *cliente pagou*; o atendimento só aparece como concluído com os dois marcados.

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
| 2026-09-10 | 3.1 | Wilson Gorosthides | **Correção da 3.0 a partir das fotos da agenda de papel** (quatro páginas, 2026-09-10), que contradisseram o formato escrito de memória. RF-005: **Hora deixa de ser obrigatória** e entra **Período** (manhã/tarde) como campo de tempo — a proprietária não anota horário, organiza por período e acerta na conversa conforme a rota; "Descrição do serviço" vira **lista de peças** com tipo, quantidade e medidas (o negócio é higienização de estofados e tapetes, cobrado por peça e por metragem). Novo **RF-013** (tabela de preços editável e cálculo por metro quadrado, com valor sobrescrevível). Novo **RF-014** (dois estados independentes: serviço feito e cliente pagou; concluído só com os dois). RF-011 passa a cobrir também **quando foi a última visita** — o serviço é periódico e "quando revisitar" é a segunda consulta mais frequente. RF-012 passa a valer só quando os dois atendimentos têm hora; a proteção para os sem hora é a contagem por período no RF-010. Novas Histórias 9 e 10, Cenários F e G no UC-002. Seção "Origem" reescrita com o formato real observado (dados fictícios: as fotos não são versionadas por conterem nome e endereço de clientes reais). |
| 2026-09-10 | 3.0 | Wilson Gorosthides | **A agenda por data passa a ser o centro do produto**, a partir do levantamento de campo com a proprietária (§2.2, "Origem"). Seção 2 reorganizada em 2.1 Gestão de Clientes, 2.2 Agenda e Atendimentos e 2.3 Pagamentos e Acesso. RF-005 reescrito de "histórico de serviço por cliente" para "registrar atendimento em uma data", com pré-preenchimento a partir do atendimento anterior e criação de cliente provisório (exceção declarada ao RF-001). Novos RF-010 (agenda por data como tela inicial), RF-011 (consultar o valor cobrado) e RF-012 (aviso de conflito de horário). Novos RNF-006 (teto de toques para registrar) e RNF-007 (tolerância a conexão fraca). História 5 reescrita e novas Histórias 6, 7 e 8; novo UC-002 e UC-001 deixa de iniciar no aplicativo. RF-006 marcado como não priorizado (a proprietária não faz controle financeiro e não pediu relatório). |
| 2026-07-21 | 2.8 | Wilson Gorosthides | Endereço passa a ser **estruturado** (logradouro, número, bairro, complemento, ponto de referência), todos opcionais — RF-001 (dados e aviso por endereço vazio), RF-003 (item exibe resumo) e RF-004 (busca por qualquer campo do endereço). Sem campos de CEP e cidade (decisão de simplicidade: na prática não seriam preenchidos; a área de atendimento é só Campo Grande - MS, âncora fixa na consulta ao mapa). Modela casa/apartamento/condomínio e prepara a abertura no mapa (issue #65). Requer migração no Supabase (`endereco` text → jsonb). |
