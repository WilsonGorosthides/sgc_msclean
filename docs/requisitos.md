# Documento de Requisitos de Software (DRS) - SGC para MSClean

## 1. Introdução
Este documento detalha os requisitos para o desenvolvimento do Sistema de Gestão de Clientes (SGC) da MSClean. O objetivo é digitalizar o controle de clientes, serviços e pagamentos, substituindo o uso de agendas físicas e garantindo a integridade dos dados históricos.

## 2. Requisitos Funcionais (RFs)

### 2.1 Gestão de Clientes
* **RF-001 - Cadastro de Cliente:** O sistema deve permitir o registro de Nome Completo, Endereço e Telefone.
* **RF-002 - Edição de Cliente:** O usuário deve poder alterar qualquer dado cadastral de um cliente já existente.
* **RF-003 - Visualização da Lista:** Exibição de uma lista centralizada com o resumo dos clientes cadastrados.
* **RF-004 - Busca em Tempo Real:** Filtragem dinâmica da lista por Nome ou Endereço conforme o usuário digita.

### 2.2 Gestão de Histórico e Financeiro
* **RF-005 - Registro de Serviço:** Adicionar registros vinculados ao cliente contendo descrição do serviço, valor cobrado e data.
* **RF-006 - Registro de Pagamento:** Adicionar registros de entrada financeira contendo valor pago, data e método de pagamento (Pix, Dinheiro ou Cartão).
* **RF-007 - Separação de Fluxos:** O sistema deve distinguir visualmente e logicamente o que é um histórico de execução (serviço) e o que é um histórico de quitação (pagamento).

### 2.3 Segurança e Ações Rápidas
* **RF-008 - Autenticação:** Acesso restrito via login (E-mail/Senha) para a proprietária.
* **RF-009 - Integração de Contato:** Botão de ação rápida para iniciar chamada telefônica ou conversa no WhatsApp a partir dos dados do cliente.

## 3. Requisitos Não Funcionais (RNFs)
* **RNF-001 - Usabilidade Mobile-First:** Interface otimizada para operação com uma única mão, dado o perfil de uso em campo.
* **RNF-002 - Desempenho de Busca:** O retorno da filtragem de clientes deve ser inferior a 1 segundo.
* **RNF-003 - Sincronização em Nuvem:** Os dados devem ser sincronizados em tempo real entre o App (Android) e o Console de Gestão (Web/Desktop).
* **RNF-004 - Persistência Relacional:** Garantir que registros de serviço/pagamento nunca fiquem "órfãos" (devem estar sempre atrelados a um ID de cliente válido).

## 4. Histórias de Usuário (HUs)
* **H1 (Organização):** Como proprietária, quero cadastrar meus clientes para eliminar a dependência da agenda de papel.
* **H2 (Logística):** Como proprietária, quero buscar clientes por endereço para otimizar meu trajeto de atendimento no dia a dia.
* **H3 (Cobrança):** Como proprietária, quero visualizar o histórico de pagamentos para identificar rapidamente quem está em dia e quem possui pendências.
* **H4 (Segregação de Dados):** Como proprietária, quero ver o histórico de serviços separado dos pagamentos para ter clareza sobre o que já foi executado.
* **H5 (Controle de Caixa):** Como proprietária, quero registrar o método de pagamento (Pix/Dinheiro/Cartão) para facilitar o fechamento financeiro diário.
* **H6 (Agilidade):** Como proprietária, quero um atalho para ligar para o cliente diretamente pelo app para avisar sobre atrasos ou confirmar horários.

## 5. Fluxo Principal (UC-001)
1. **Acesso:** Usuário realiza login.
2. **Consulta:** Usuário visualiza a lista ou utiliza a barra de busca para localizar um cliente.
3. **Gestão:** Ao selecionar um cliente, o usuário visualiza os detalhes e o histórico completo.
4. **Ação:** O usuário decide entre adicionar um novo serviço, registrar um novo pagamento ou editar os dados de contato.