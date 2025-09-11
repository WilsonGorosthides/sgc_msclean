# Documento de Esquema do Banco de Dados (Firestore) - SGC para MSClean

## 1. Introdução
Este documento descreve a estrutura e o modelo de dados que serão utilizados no banco de dados Firestore para a aplicação SGC MSClean. Ele serve como uma referência técnica para o desenvolvimento e a manutenção da base de dados.

## 2. Estrutura Geral
O banco de dados será organizado em coleções. A coleção principal será `clientes`, onde cada documento representará um cliente único da MSClean.

## 3. Detalhamento da Coleção `clientes`

Cada documento dentro da coleção `clientes` terá um ID único gerado automaticamente pelo Firestore. A estrutura interna de cada documento será a seguinte:

### 3.1. Campos Principais do Documento `cliente`

| Nome do Campo         | Tipo de Dado | Obrigatório | Descrição                                    |
| :-------------------- | :----------- | :---------- | :------------------------------------------- |
| `nomeCompleto`        | String       | Sim         | Nome completo do cliente.                    |
| `endereco`            | String       | Sim         | Endereço completo do cliente.                |
| `telefone`            | String       | Sim         | Número de telefone para contato.             |
| `historicoServicos`   | Array        | Não         | Uma lista de todos os serviços prestados.    |
| `historicoPagamentos` | Array        | Não         | Uma lista de todos os pagamentos recebidos.  |

### 3.2. Estrutura do Objeto `Servico` (dentro do array `historicoServicos`)

Cada item no array `historicoServicos` será um objeto (map) com a seguinte estrutura:

| Nome do Campo | Tipo de Dado | Obrigatório | Descrição                                                                      |
| :------------ | :----------- | :---------- | :----------------------------------------------------------------------------- |
| `data`        | Timestamp    | Sim         | Data e hora em que o serviço foi realizado.                                    |
| `descricao`   | String       | Sim         | Descrição detalhada do serviço prestado (ex: "Lavagem de sofá de 3 lugares"). |
| `valor`       | Number       | Sim         | O valor cobrado pelo serviço.                                                  |

### 3.3. Estrutura do Objeto `Pagamento` (dentro do array `historicoPagamentos`)

Cada item no array `historicoPagamentos` será um objeto (map) com a seguinte estrutura:

| Nome do Campo       | Tipo de Dado | Obrigatório | Descrição                                                                      |
| :------------------ | :----------- | :---------- | :----------------------------------------------------------------------------- |
| `data`              | Timestamp    | Sim         | Data e hora em que o pagamento foi recebido.                                   |
| `valorPago`         | Number       | Sim         | O montante pago pelo cliente (valor total da transação).                       |
| `metodo`            | String       | Sim         | O método principal de pagamento (ex: "Pix", "Dinheiro", "Cartão de Crédito").    |
| `detalhesPagamento` | Map          | Não         | Um objeto opcional para detalhes extras, como parcelamento.                    |

#### 3.3.1 Estrutura do Objeto `detalhesPagamento`

| Nome do Campo | Tipo de Dado | Obrigatório | Descrição                                     |
| :------------ | :----------- | :---------- | :-------------------------------------------- |
| `parcelas`    | Number       | Sim         | Número de parcelas (1 para "à vista", 2 para 2x, etc.). |


## 4. Exemplo de um Documento `cliente` (em formato JSON)

```json
{
  "nomeCompleto": "Ana Silva",
  "endereco": "Rua das Flores, 123, Bairro Jardim, Campo Grande-MS",
  "telefone": "(67) 99999-8888",
  "historicoServicos": [
    {
      "data": "2025-09-15T14:00:00Z",
      "descricao": "Limpeza e impermeabilização de sofá retrátil",
      "valor": 350.00
    },
    {
      "data": "2025-10-20T10:30:00Z",
      "descricao": "Lavagem de 4 cadeiras de jantar",
      "valor": 120.00
    }
  ],
  "historicoPagamentos": [
    {
      "data": "2025-09-15T14:05:00Z",
      "valorPago": 350.00,
      "metodo": "Cartão de Crédito",
      "detalhesPagamento": {
        "parcelas": 3
      }
    },
    {
      "data": "2025-10-20T11:00:00Z",
      "valorPago": 120.00,
      "metodo": "Pix"
    }
  ]
}