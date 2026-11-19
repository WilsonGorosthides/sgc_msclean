# Documento de Requisitos de Software (DRS) - SGC para MSClean

## 1. Introdução

Este documento detalha os requisitos funcionais e não funcionais do Sistema de Gestão de Clientes (SGC) da MSClean. Serve de guia para as fases de design, desenvolvimento e teste.

**O produto é uma agenda virtual.** O que a proprietária quer é o controle diário, semanal e mensal dos seus clientes e serviços, no lugar do caderno de papel. A agenda (§2.2) é a tela que abre com o aplicativo e o centro de todas as decisões de prioridade e de navegação. A gestão de clientes (§2.1), a tabela de preços (RF-013) e o histórico (RF-011) existem para **apoiar a agenda** — facilitar o orçamento e a consulta —, e não como fins em si.

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
  - Os resultados vêm por **relevância**: nome igual ao termo, depois nome que começa com o termo, depois nome com uma palavra que começa com o termo, depois o termo no meio do nome e, por fim, o termo só no endereço; dentro de cada faixa, ordem alfabética. (Com a agenda inteira importada, a ordem alfabética punha "João Paulo" antes de "Paulo".)
  - A busca **não diferencia acento**: "joao" acha "João".

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

#### RF-016 - Trazer Cliente dos Contatos do Celular
O sistema deve permitir trazer nome e telefone de um contato do celular, em vez de digitá-los.

> A agenda do celular da proprietária é onde o cliente novo já está: ela salva o
> contato quando ele chama no WhatsApp. Digitar de novo no app é a fricção que
> faz a anotação voltar para o papel (decisão de 2026-11-17, issue #115; spike #29).

* **Critérios de aceitação:**
  - No **cadastro de cliente** (novo) e na escolha de cliente do **atendimento**, um botão **"Dos contatos"** abre o seletor de contatos do próprio Android; o app recebe **só o contato escolhido** (nome e o número tocado), sem pedir acesso à agenda inteira.
  - No cadastro, o contato escolhido **preenche o nome e o telefone**; ela confere e salva como sempre.
  - Se o telefone do contato **já é de um cliente**, o app avisa **"Já cadastrado como <nome>"** e oferece abrir o cadastro existente, em vez de duplicar; ela ainda pode cadastrar mesmo assim.
  - No atendimento, um contato que **já é cliente** seleciona esse cliente; um contato **novo** vira cliente **com o telefone** (não provisório) ao salvar o atendimento, inclusive sem internet (fila do aparelho, RNF-007).
  - O telefone vem no formato da base (`+55 67 99999-9999`); número sem DDD recebe o **67**. Dois números são o mesmo cliente quando batem DDD e os 8 últimos dígitos (com ou sem o nono dígito, com ou sem `+55`).
* **Fora do escopo:** sincronizar a agenda inteira do celular com o app (contato apagado ou editado nos dois lados, contatos pessoais no banco) e receber o contato compartilhado pelo WhatsApp (#116). Só no Android; na web o botão não aparece.

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
  - As **Peças do serviço** são uma lista: cada peça tem **tipo** (sofá, tapete, poltrona, cortina, colchão, cadeira, outro), **quantidade**, a **variante** quando o preço depende dela (lugares do sofá, tamanho do colchão, retrátil/reclinável) e, no tapete, **largura e comprimento**. A escolha e o ajuste seguem a interação do RF-013 (seletor de peças).
  - O registro continua **rápido**: peças e valor não são exigidos e ficam numa **linha de resumo** que abre a tela **Peças e valor** (o seletor do RF-013, com o rodapé do total); ao voltar, o resumo mostra as peças e o valor a cobrar, e o atendimento é salvo pelo botão do próprio formulário.
  - No resumo das peças (cartão da agenda, linha do formulário e histórico do cliente), o item do quadro Outros aparece pelo **nome** ("deslocamento", "excesso de pelo de pet"), e não como "outro".
  - O **Valor** é calculado a partir das peças e da tabela de preços (RF-013) e **pode ser sobrescrito** pela proprietária antes de salvar.
  - O Cliente pode ser escolhido entre os cadastrados **ou** informado por um nome ainda não cadastrado. Neste segundo caso o sistema cria um **cliente provisório** apenas com o nome — exceção deliberada ao RF-001, que exige ao menos um telefone. A exceção existe porque o registro precisa caber no momento em que o serviço é combinado; exigir telefone e endereço ali é o atrito que hoje empurra a anotação para depois.
  - O cliente provisório é sinalizado na lista de clientes até ser completado.
  - Quando o Cliente escolhido **já tem atendimento anterior**, as Peças e a Observação vêm pré-preenchidas com as do atendimento mais recente daquele cliente, e podem ser alteradas antes de salvar.
  - Quando o Cliente tem endereço cadastrado, o Local vem pré-preenchido com o resumo do endereço (mesmo resumo do RF-003), e pode ser alterado.
  - Ao salvar, o atendimento passa a constar no dia e no período correspondentes da agenda.
  - Na **edição**, o dia do atendimento pode ser **trocado** por um calendário (adiar ou corrigir o dia anotado errado); salvo, o atendimento passa para o dia novo, com peças, valor e marcas, e a agenda passa a mostrar esse dia.
  - Na **edição**, o atendimento pode ser **excluído**, após confirmação (cliente que desmarcou ou anotação errada); sem internet, a exclusão avisa e não acontece.

#### RF-010 - Agenda por Data
O sistema deve exibir os atendimentos organizados por dia, abrir nessa visão, e permitir enxergar a **semana** e o **mês**.

> A agenda de papel dá as três leituras de graça: a página é o dia, virar duas ou
> três folhas é a semana, e folhear o caderno é o mês. O aplicativo precisa
> devolver as três, ou a proprietária perde a noção de carga que hoje tem ao
> folhear — e é essa noção que decide se ela aceita mais um serviço.

* **Critérios de aceitação:**
  - Ao abrir o aplicativo, o sistema exibe a agenda posicionada no **dia de hoje**.
  - Os atendimentos do dia selecionado são agrupados por **período** (manhã, depois tarde) e, dentro do período, ordenados por hora quando houver — os sem hora aparecem depois dos com hora, na ordem em que foram registrados.
  - Cada período exibe **quantos atendimentos tem**, para que a carga do dia seja visível antes de aceitar mais um.
  - O usuário navega para outros dias sem precisar digitar uma data.
  - Um dia sem atendimentos exibe a mensagem "Nenhum atendimento neste dia." em vez de uma lista vazia silenciosa (consistente com o RF-003).
  - Na navegação entre dias, os dias que possuem ao menos um atendimento são visualmente distinguíveis dos vazios.
  - A **semana** do dia selecionado fica visível junto ao dia: os sete dias (domingo a sábado), cada um com a **quantidade de atendimentos**. O usuário avança e retrocede de semana em semana.
  - A partir da agenda, em **um toque**, o usuário abre o **mês** em formato de calendário: cada dia do mês exibe a quantidade de atendimentos. O usuário avança e retrocede de mês em mês.
  - Tocar em um dia, na semana ou no mês, seleciona esse dia e exibe os seus atendimentos.
  - O **dia de hoje** é identificável na semana e no mês, e um atalho volta a hoje a partir de qualquer data.
  - A lista de clientes (RF-003) continua acessível, deixando de ser a tela inicial.
* **Fora do escopo:** semana e mês são alcances de **navegação e de carga** (quantos atendimentos há em cada dia). Não exibem totais de valor por período — a proprietária declarou não fazer controle financeiro (ver a nota de prioridade do RF-006).

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
* **Nota de entrega (issue #81):** o histórico fica no topo da tela do cliente, a que abre ao tocar no nome na lista. Conta só os atendimentos **até hoje** — o que está marcado para depois ainda não é visita e aparece só na agenda.

#### RF-012 - Aviso de Conflito de Horário
O sistema deve avisar quando um atendimento é marcado em horário já ocupado.

* **Critérios de aceitação:**
  - O aviso só se aplica quando **os dois atendimentos têm hora informada** — sem hora não há conflito a detectar, e inventar um seria alarme falso.
  - Ao salvar um atendimento **com hora**, se já existir outro no mesmo dia **com hora** a menos de 1 hora de distância, o sistema exibe um aviso antes de gravar.
  - O aviso identifica o atendimento conflitante por **cliente e hora**.
  - O aviso **não bloqueia**: a usuária pode confirmar mesmo assim (e o atendimento é gravado) ou voltar e ajustar o horário.
  - **Limitação assumida:** a duração do serviço não é modelada nesta versão, então o conflito é aproximado pela janela fixa de 1 hora. Se a janela se mostrar imprecisa no uso real, a decisão a rever é modelar a duração — não ajustar o número.
  - Para os atendimentos **sem hora**, a proteção contra excesso não é o aviso, e sim a contagem por período exibida no RF-010: a carga do dia fica visível antes de aceitar mais um.

#### RF-013 - Tabela de Preços e Cálculo do Valor
O sistema deve calcular o valor de um atendimento (e de um orçamento, RF-017) a partir dos serviços, usando uma tabela de preços que a proprietária mantém.

> **Referência (2026-11-17).** A proprietária comprou e usa um app de orçamento
> de higienização. Gosta da forma de precificar: uma tabela de itens (produtos,
> mão de obra e imprevistos), com o valor de cada um e o total que sai pronto.
> **Reclamação dela:** lá, a impermeabilização só entra como *extra* de uma
> higienização. Ela também faz **só impermeabilização**: é um serviço completo,
> não um extra. O combo (higienizar e impermeabilizar a mesma peça) existe e é
> comum, mas é a soma de dois serviços, não a regra. Daí o critério de serviços
> independentes.

* **Critérios de aceitação:**
  - A proprietária mantém a **tabela de preços** como uma lista de **serviços**: cada um com **nome** (ex.: "Higienização sofá 3 lugares", "Impermeabilização sofá 3 lugares", "Higienização de tapete"), **unidade de cobrança** (peça ou metro quadrado) e **valor**. Ela adiciona, edita e remove serviços.
  - **Cada serviço é independente**: impermeabilização é um serviço como higienização, e pode ser orçada e registrada **sozinha**, sem higienização na mesma peça.
  - O **combo** (higienizar e impermeabilizar a mesma peça) é escolher os dois serviços; o valor é a soma. Se ela cobra o combo com preço próprio, cadastra o combo como mais um serviço da tabela.
  - A tabela começa com uma **lista inicial** de serviços **sem valor**, que ela completa; um serviço sem valor não entra no cálculo, e o total avisa que falta valor.
  - Para serviços cobrados por metro quadrado, o sistema calcula a área a partir de largura × comprimento e multiplica pelo valor do metro (ex.: `8 × 4,5 = 36 m²`).
  - Para serviços cobrados por peça, o sistema multiplica o valor pela quantidade.
  - O valor total é a soma dos serviços, exibido enquanto eles são informados.
  - O valor calculado é **sugestão, não imposição**: a proprietária pode sobrescrevê-lo (desconto, combinado diferente) sem alterar a tabela.
  - Alterar a tabela de preços **não altera** o valor de atendimentos e orçamentos já registrados.
* **Entrega em duas partes:** a tabela editável (os quatro primeiros critérios) e o cálculo no atendimento (os demais).
* **Interação do seletor de peças (issue #134).** A primeira versão do cálculo (#124) funcionou, mas ficou confusa no uso. A escolha segue a estrutura do app de referência — peça primeiro, depois o ajuste, depois os serviços, total num rodapé fixo —, com a regra dela: impermeabilizar é um serviço da peça, ao lado de higienizar, e não um extra. O mesmo componente serve ao orçamento (RF-017). No atendimento, o seletor fica numa tela própria, aberta por uma linha de resumo: anotar na agenda tem de continuar levando poucos toques (decisão de 2026-11-17, depois do primeiro teste no celular); montar o preço peça por peça é o trabalho do orçamento.
  - A peça é escolhida em **quadros por família**, com ícone e cor próprios, nesta ordem: sofá, tapete, poltrona, cortina, colchão, cadeira e outros; cada quadro mostra quantas peças daquela família já estão no atendimento (×N).
  - A peça é **ajustada sem digitar**, com botões − / +: cada sofá é um cartão com os lugares (2, 3, 4 ou de canto), o interruptor retrátil/reclinável e "Pôr outro sofá"; poltrona tem quantidade e retrátil/reclinável; cadeira, a quantidade; cortina, as folhas; tapete, largura × comprimento de 0,5 em 0,5 m com os m² à vista; colchão, uma grade Solteiro/Casal/Queen/King com a quantidade de cada.
  - Em **cada peça**, os serviços **Higienizar** e **Impermeabilizar** são marcados separadamente ou juntos (combo); nenhum é extra do outro, e a peça pode ter só a impermeabilização.
  - O preço de cada serviço marcado vem da linha da tabela com a **mesma peça, variante (lugares, tamanho) e serviço**; sem essa linha, ou com ela sem valor, o serviço aparece "sem valor" e o total avisa — nunca se usa o preço de outros lugares ou de outro tamanho. No sofá ou na poltrona **retrátil/reclinável**, o preço é o da mesma peça não retrátil **mais o acréscimo do retrátil**: a linha retrátil da tabela guarda só a diferença (como no app de referência, + R$ 30 na higienização do sofá); sem acréscimo cadastrado, vale o preço comum (o retrátil nunca deixa o serviço sem preço).
  - O **deslocamento** fica fora do quadro Outros, num bloco próprio, e **já vem incluído** quando ela abre Peças e valor de um atendimento ainda sem peças (é cobrado quase sempre); o valor, o da tabela, sobe e desce de **R$ 1 em R$ 1** com − / + e pode ser **digitado** tocando nele; um interruptor tira o deslocamento quando não for cobrado. Os outros itens avulsos da tabela (sem peça: odor, mancha, combo com preço próprio) entram pelo quadro **Outros**, cada um com a sua quantidade.
  - O **preço de cada serviço** marcado pode ser **ajustado só neste registro** (tecido especial, desconto, combinado), com uma **justificativa opcional**; o serviço e os detalhes do total mostram o valor ajustado ao lado do preço da tabela, e "Voltar ao da tabela" desfaz. A tabela não muda.
  - Cada item da tabela pertence a um **grupo**, como no app de referência: **produto**, **mão de obra** ou **imprevisto** (sem grupo informado, mão de obra). A tabela de preços aparece dividida nesses três grupos, e o editor escolhe o grupo. A lista inicial já traz os produtos (impermeabilizante do sofá por lugares, neutralizador de odor, tira-manchas, hidratante de couro) e os imprevistos (segunda lavagem, excesso de pelo, mofo, urina com odor), sem valor.
  - Um **produto** da tabela com peça e serviço **vem junto com o serviço**: ao marcar o serviço na peça, entram a linha de mão de obra e os produtos da mesma peça e serviço (com a mesma variante, ou sem variante, que vale para todas). Ex.: impermeabilizar o sofá de 3 lugares traz a aplicação (mão de obra, R$ 90) e o impermeabilizante (produto, R$ 190), como na nota do app de referência; o botão do serviço mostra a soma, e cada linha tem o seu preço e o seu ajuste. O retrátil não muda o produto. Desmarcar o serviço tira os dois.
  - O registro grava o **grupo de cada serviço** (serviço gravado sem grupo conta como mão de obra), para a nota do orçamento (RF-017) separar produtos, mão de obra e imprevistos. Os avulsos do quadro Outros aparecem separados por grupo; o **deslocamento é mão de obra**. Os detalhes do rodapé mostram o **subtotal de cada grupo** com valor, antes das linhas.
  - Um **rodapé fixo** mostra o total em destaque, a lista detalhada (serviço, legenda e valor de cada linha) e o botão de salvar; o valor segue sugestão, com "Usar o calculado" depois de sobrescrito.
  - Atendimentos registrados antes desta interação abrem com as peças e os preços copiados, e salvar não perde nenhum serviço.
  - Na tabela de preços, cada serviço informa a **peça**, a **variante** e o **serviço** a que corresponde (ou nenhuma peça, se avulso), e a lista inicial já vem assim, sem linhas de retrátil (ela cadastra o acréscimo quando quiser); a linha retrátil aparece e se edita como acréscimo ("+ R$"); a cortina é cobrada por folha.

#### RF-017 - Orçamento
O sistema deve montar um orçamento a partir da tabela de preços (RF-013), mandá-lo pelo WhatsApp e, aprovado, levá-lo à agenda.

> Pedido da proprietária, a partir do app de orçamento que ela usa (ver a nota
> do RF-013). Lá o orçamento é isolado; aqui ele nasce do cadastro de clientes
> e termina na agenda — "cliente aprovou" vira atendimento sem digitar de novo,
> o que fecha a etapa de transcrição que já causou agendamento duplicado
> (RNF-006).

* **Critérios de aceitação:**
  - O orçamento é feito para um cliente **cadastrado**, um **contato do celular** (RF-016) ou um **nome novo** (cliente provisório, como no RF-005).
  - Os itens são **serviços da tabela** (com quantidade ou medidas) e **itens avulsos** (descrição e valor, para imprevistos); o total sai pelo RF-013 e pode ser sobrescrito.
  - O orçamento leva **garantia**, **validade** (em dias) e **formas de pagamento**, textos que ela configura uma vez e pode mudar em cada orçamento.
  - Cada orçamento tem uma **situação**: rascunho, enviado, aprovado ou recusado.
  - **Enviar pelo WhatsApp** abre o WhatsApp com o orçamento em texto (itens, total, garantia, validade e pagamento) e marca o orçamento como enviado.
  - **Cliente aprovou** pede o dia e o período e cria o **atendimento** na agenda com os mesmos itens e valor; o orçamento fica aprovado e ligado ao atendimento.
  - Os orçamentos ficam numa lista, do mais recente ao mais antigo, com cliente, total e situação.
* **Decisões em aberto (com a proprietária):** mostrar o total separado em **produtos e mão de obra**, como no app de referência, ou só o total; envio só em **texto** ou também em **PDF com o logo**; resumo do mês (**quanto foi orçado e quantos aprovados**), que esbarra na nota de prioridade do RF-006.
* **Já coberto pelo app:** o "lembrete de retorno", pago à parte no app de referência, é o histórico do cliente (RF-011) mais os avisos no celular (RF-015).

#### RF-018 - Orçamento por Áudio
O sistema deve montar o orçamento (RF-017) a partir de um áudio em que a proprietária descreve o serviço.

* **Nota de prioridade:** é o recurso de destaque do app de referência. Exige reconhecimento de voz e um modelo de linguagem para casar a fala com a tabela de preços — com custo por uso e um servidor que guarde a chave. Fica especificado e **não priorizado** até o RF-017 estar em uso; antes, um spike avalia custo e precisão.

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

#### RF-015 - Avisos no Celular
O celular avisa a proprietária da agenda, sem ela precisar abrir o app.

> Pedido da proprietária na demonstração de 2026-11-16, ao aprovar o app: "não
> basta anotar, o bom seria o celular avisar". É a primeira coisa que o app faz
> e o caderno não faz. Os avisos são do próprio aparelho: funcionam sem
> internet e sem servidor, e valem só no Android (issue #95).

* **Critérios de aceitação:**
  - Às **19h** da véspera de um dia com atendimentos, o celular avisa quantos são no dia seguinte, por período, com os nomes dos clientes.
  - Às **7h** de um dia com atendimentos, o celular avisa quantos são hoje, por período, com os nomes dos clientes.
  - Um atendimento **com hora** gera um aviso **1 hora antes**, com o cliente, a hora e o local.
  - Um atendimento com **serviço feito** e **sem pagamento** gera **um** lembrete de cobrança às 10h do **terceiro dia** depois da data do atendimento; marcar o pago antes disso cancela o lembrete.
  - Os avisos **acompanham a agenda**: registrar, mudar a hora, marcar o pago ou excluir um atendimento refaz os avisos; avisos de horário que já passou não são agendados.
  - Tocar no aviso abre a agenda no **dia** a que ele se refere.
  - Na primeira abertura, o app pede ao sistema, em **um toque**, para ficar **fora da economia de bateria**; se ela negar, só volta a pedir depois de **30 dias**; se já estiver liberado, não pede. (Sem isso, Samsung, Xiaomi e Motorola seguram os alarmes do app parado; issue #101.)

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

* **RNF-001 - Usabilidade:** Todas as ações principais (cadastrar, buscar, editar, excluir) devem ser alcançáveis em no máximo 2 toques a partir da tela inicial, sem necessidade de treinamento prévio. Nenhum botão ou campo fica **coberto pela barra de navegação** do sistema: o fim de cada tela rolável termina acima dela (Android 15+ desenha o app de ponta a ponta; achado no celular da usuária, issue #118).
* **RNF-002 - Desempenho:** Operações de busca, cadastro, edição e exclusão devem responder em menos de 2 segundos para uma base de até 500 clientes, em uso por um único usuário.
* **RNF-003 - Compatibilidade de Plataforma:** A aplicação deve compilar e funcionar a partir de um único código-fonte Flutter em **Android** e em **navegadores web (desktop)**.
* **RNF-004 - Sincronização de Dados:** Os dados gravados em uma plataforma devem aparecer na outra sem ação manual de atualização, por meio da stream em tempo real do Supabase (latência típica inferior a 2 segundos).
* **RNF-005 - Segurança:** O acesso ao banco deve ser controlado por **Row Level Security (RLS)** no Supabase; no cliente expõe-se apenas a `anonKey` pública. As credenciais (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) são carregadas de um arquivo `.env` fora do controle de versão, e um `.env.example` documenta as chaves esperadas.
* **RNF-006 - Velocidade de Registro:** Registrar um atendimento para um cliente que já tem atendimento anterior deve ser possível em **no máximo 4 toques** a partir da agenda — dia, cliente, período e confirmar —, sem digitação, aproveitando as peças e o valor do atendimento anterior. Motivo: o registro compete com anotar uma linha no papel; se for mais lento, a anotação volta para o papel — e é justamente o adiamento da anotação que causou o agendamento duplicado.
* **RNF-007 - Anotar sem Internet:** O app continua útil **sem conexão**, como o caderno. (a) Sem rede, a agenda e a lista de clientes abrem com os **últimos dados guardados no aparelho**, em vez de uma tela vazia. (b) Um atendimento novo — e o cliente provisório criado com ele — registrado sem rede fica **gravado no aparelho**, aparece na agenda na hora com a marca **"aguardando envio"** e é enviado ao banco **sozinho** quando a conexão voltar, **sem duplicar**. (c) A agenda e a lista de clientes exibem um aviso discreto de **"sem conexão"**; falha de conexão não aparece como lista vazia. (d) Nada anotado sem rede se perde ao fechar e reabrir o app. Fora do escopo, por trazer conflito entre o aparelho e o banco: editar ou excluir atendimento ou cliente, e marcar feito/pago, sem rede — essas ações avisam e não gravam; um item ainda aguardando envio também não se edita nem se marca até ser enviado. Motivo: a proprietária anota no carro e na casa dos clientes, onde o sinal às vezes falta; se o app falha onde o caderno não falha, ela volta para o caderno (verificação no celular, 2026-11-13, issue #94). Substitui a versão anterior ("sinal fraco, não ausente").
* **RNF-008 - Identidade Visual:** O app se apresenta com a marca da MS Clean (arte em `docs/Logo_MS_Clean.pdf`). (a) Na gaveta de apps, o ícone é o **símbolo da marca** — a gota com o sofá, sem o texto, que fica ilegível nesse tamanho — sobre o **azul-marinho** da marca, e o nome exibido é **"MS Clean"**. (b) Ao abrir, enquanto o app carrega, aparece o **logo completo** sobre o mesmo azul-marinho, em vez de uma tela branca. (c) Na web, a aba e o atalho usam o mesmo símbolo e o mesmo nome. As cores das telas do app não mudam: a marca entra no ícone e na abertura (decisão de 2026-11-16, issue #96). Motivo: a proprietária aprovou o app e quer reconhecê-lo como da empresa na tela do celular.

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
    * **Eu quero** abrir o aplicativo e já ver os atendimentos de hoje, com a semana à vista e o mês a um toque,
    * **Para que** eu saiba para onde vou e como está a minha carga sem precisar consultar o caderno.
* **História 7: Lembrar quanto eu cobro e quando estive lá**
    * **Como** proprietária da empresa,
    * **Eu quero** ver quanto cobrei de uma cliente da última vez e há quanto tempo foi,
    * **Para que** eu não perca tempo procurando em conversas antigas e saiba quando voltar.
* **História 9: Calcular o preço na hora**
    * **Como** proprietária da empresa,
    * **Eu quero** informar os serviços, as peças e as medidas e ver o valor sair pronto,
    * **Para que** eu passe o orçamento na conversa sem fazer conta no papel.
* **História 11: Mandar o orçamento e, aprovado, já estar na agenda**
    * **Como** proprietária da empresa,
    * **Eu quero** montar o orçamento pela minha tabela, mandar pelo WhatsApp e, quando a cliente aprovar, ver o serviço já na agenda,
    * **Para que** eu não precise de outro app para orçar nem passe nada a limpo depois.
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
    2.  O sistema exibe a agenda posicionada no dia de hoje, com os atendimentos agrupados por período e a semana corrente à vista.
    3.  **Cenário A - Registrar:** O usuário seleciona o dia, aciona a opção de adicionar, escolhe o cliente e o período. Se o cliente já tem atendimento anterior, as peças, o valor e a observação vêm pré-preenchidos, e o local vem do endereço cadastrado. O usuário confirma e o atendimento passa a constar no dia, dentro do período.
    4.  **Cenário B - Cliente novo:** No mesmo formulário, o usuário informa um nome ainda não cadastrado; o sistema cria um cliente provisório com esse nome e segue com o registro.
    5.  **Cenário C - Navegar entre dias, semanas e meses:** O usuário toca em outro dia da semana, avança ou retrocede a semana, ou abre o mês e toca em um dia do calendário; a agenda mostra os atendimentos do dia escolhido, ou a mensagem de dia vazio. Semana e mês mostram quantos atendimentos há em cada dia; um atalho volta a hoje.
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
| 2026-11-12 | 3.2 | Wilson Gorosthides | **A agenda é o produto: visões de semana e mês.** §1 passa a declarar o produto como agenda virtual (controle diário, semanal e mensal de clientes e serviços), com clientes, preços e histórico como apoio a ela. RF-010 ganha quatro critérios: semana do dia selecionado sempre visível, com a quantidade de atendimentos por dia e navegação por semana; mês em calendário a um toque, com a quantidade por dia e navegação por mês; tocar em um dia (na semana ou no mês) seleciona e exibe; hoje identificável e com atalho de retorno. Nota de fora do escopo: semana e mês não exibem totais de valor (RF-006 segue não priorizado). História 6 e UC-002 (passo 2 e Cenário C) ajustados. |
| 2026-11-16 | 3.3 | Wilson Gorosthides | **RNF-007 ampliado para uso sem internet** (issue #94): leitura dos últimos dados guardados no aparelho, registro de atendimento e de cliente provisório em fila com envio automático e sem duplicar, aviso de "sem conexão" e nada perdido ao reabrir; edição, exclusão e marcas sem rede ficam fora, avisando. Substitui "sinal fraco, não ausente". |
| 2026-11-16 | 3.4 | Wilson Gorosthides | Novo **RNF-008 - Identidade Visual** (issue #96): ícone com o símbolo da marca sobre o azul-marinho, nome "MS Clean" na gaveta, logo completo na abertura e o mesmo na web; a paleta das telas não muda. |
| 2026-11-16 | 3.5 | Wilson Gorosthides | Novo **RF-015 - Avisos no Celular** (issue #95, pedido da proprietária na demonstração): resumo da véspera às 19h, resumo do dia às 7h, aviso 1 hora antes do atendimento com hora, lembrete único de feito e não pago no terceiro dia, avisos que acompanham a agenda e toque que abre o dia. Avisos locais, só no Android. |
| 2026-11-16 | 3.6 | Wilson Gorosthides | RF-015 ganha o critério do pedido de liberação da economia de bateria na primeira abertura, com nova tentativa só após 30 dias (issue #101). |
| 2026-11-16 | 3.7 | Wilson Gorosthides | RF-005 ganha dois critérios: trocar o dia na edição (adiar ou corrigir) e excluir o atendimento com confirmação — cancelar é excluir, sem marca de cancelado (decisão de 2026-11-16, issue #106). |
| 2026-11-17 | 3.8 | Wilson Gorosthides | RF-004 ganha dois critérios: resultados por relevância (quem começa com o termo primeiro) e busca sem diferenciar acento — achado com a agenda importada de 4.371 contatos (issue #113). |
| 2026-11-17 | 3.9 | Wilson Gorosthides | RNF-001: nenhum botão coberto pela barra de navegação do sistema (Android 15+ de ponta a ponta; Salvar coberto no celular da usuária, issue #118). |
| 2026-11-17 | 3.10 | Wilson Gorosthides | Novo **RF-016 - Trazer Cliente dos Contatos do Celular** (issue #115): botão "Dos contatos" no cadastro e no atendimento, só o contato escolhido, aviso de já cadastrado, contato novo vira cliente com telefone, formato e comparação de telefone. |
| 2026-11-17 | 3.11 | Wilson Gorosthides | RF-011 entregue (issue #81): nota de entrega — histórico no topo da tela do cliente, contando só atendimentos até hoje. |
| 2026-11-17 | 3.12 | Wilson Gorosthides | A partir do app de orçamento que a proprietária usa: **RF-013 reescrito** (tabela como lista de serviços independentes — impermeabilização é serviço completo, não extra de higienização; combo é a soma ou um item próprio; lista inicial sem valor; entrega em duas partes), novo **RF-017 - Orçamento** (tabela, avulsos, garantia/validade/pagamento, situação, envio pelo WhatsApp, aprovado vira atendimento; decisões em aberto registradas) e novo **RF-018 - Orçamento por Áudio** (não priorizado); História 9 ajustada e nova História 11. |
| 2026-11-17 | 3.13 | Wilson Gorosthides | RF-013 ganha a interação do seletor de peças (issue #134): quadros por família, ajuste por − / + (sofá por lugares e retrátil, tapete por medidas, colchão por tamanho), Higienizar e Impermeabilizar por peça, preço por peça + variante + serviço, avulsos em Outros, rodapé fixo com o total; RF-005 passa a citar cadeira e variante nas peças. |
| 2026-11-17 | 3.14 | Wilson Gorosthides | RF-005: registro rápido — peças e valor numa linha de resumo que abre a tela Peças e valor (seletor do RF-013); o orçamento (RF-017) é onde o seletor ocupa a tela (issue #134, decisão depois do teste no celular). |
| 2026-11-18 | 3.15 | Wilson Gorosthides | RF-013, depois do teste no celular (#134): retrátil sem preço próprio usa o preço comum; deslocamento liga/desliga; preço de cada serviço ajustável só no registro, com justificativa opcional; lista inicial sem linhas de retrátil. |
| 2026-11-19 | 3.16 | Wilson Gorosthides | RF-013, depois do segundo teste no celular (#134): o retrátil é o preço comum **mais um acréscimo** (a linha retrátil guarda só a diferença, + R$ 30 no app de referência), e a tabela mostra e edita essa linha como acréscimo. |
| 2026-11-19 | 3.17 | Wilson Gorosthides | RF-013, depois do terceiro teste no celular (#134): deslocamento fora do quadro Outros, já incluído ao abrir Peças e valor sem peças, com o valor de R$ 1 em R$ 1 ou digitado, e um interruptor para tirar. |
| 2026-11-19 | 3.18 | Wilson Gorosthides | RF-013, pedido do desenvolvedor depois do terceiro teste no celular (#134): itens da tabela em grupos (produto, mão de obra, imprevisto) como no app de referência; produto vem junto com o serviço da peça (impermeabilizar = aplicação + impermeabilizante); o registro grava o grupo e o deslocamento é mão de obra, para a nota do orçamento (RF-017). |
| 2026-11-19 | 3.19 | Wilson Gorosthides | RF-005: no resumo das peças, o item do quadro Outros aparece pelo nome (deslocamento, avulso), e não como "outro" (issue #141, achado nos prints do modo demonstração). |
