# SGC para MSClean

## 📝 Descrição do Projeto
O Sistema de Gestão de Clientes (SGC) para a MSClean é uma aplicação desenvolvida para resolver o desafio de gerenciamento manual de uma base de clientes em rápido crescimento. Ele centraliza informações de contato, históricos de serviços e pagamentos, permitindo que a proprietária da empresa tenha controle total e eficiente de seu negócio.

## 🎯 Objetivo de Negócio
Substituir o gerenciamento manual (WhatsApp, planilhas, etc.) por uma ferramenta digital simples e intuitiva, garantindo organização, agilidade e profissionalismo no dia a dia da MSClean.

## 🚀 Metodologia
Este projeto segue a metodologia **Ágil (Scrum Simplificado)**, permitindo entregas rápidas de funcionalidades e ajustes contínuos com base no feedback da proprietária.

## 📈 Roadmap (Próximos Passos)
- **Fase 1 (MVP):** Implementação das funcionalidades essenciais de cadastro, edição, listagem e busca simples de clientes.
- **Fase 2:** Testes de usabilidade e coleta de feedback.
- **Fase 3:** Melhorias na versão desktop e filtros avançados.

## 📌 Requisitos do Sistema

### Requisitos Funcionais (O que o sistema faz)
- **RF001:** Cadastro, edição e exclusão de clientes.
- **RF002:** Visualização e busca de clientes por palavras-chave.
- **RF003:** Registro do histórico de serviços e pagamentos de cada cliente.

### Requisitos Não Funcionais (Como o sistema deve ser)
- **RNF001:** Interface simples e intuitiva (alta usabilidade).
- **RNF002:** Compatível com dispositivos móveis Android.
- **RNF003:** Acessível via navegador web para desktop.
- **RNF004:** Dados sincronizados em tempo real entre dispositivos.

## ⚙️ Arquitetura e Tecnologia
A arquitetura proposta é baseada no modelo Cliente-Servidor com um BaaS (Backend as a Service).

* **Linguagem:** `Dart`
* **Framework:** `Flutter` (para Android e Web)
* **Backend & DB:** `Supabase` (PostgreSQL e Auth)


## 📁 Estrutura do Projeto
````
sgc_msclean/
├── lib/
│   ├── main.dart
│   ├── core/             # Cores (Dark Theme), constantes de API e estilos
│   ├── models/           # Classes: ClientModel e RecordModel
│   ├── services/         # SupabaseService.dart (Onde a mágica acontece)
│   ├── screens/          # Pastas por tela (home, details, form)
│   └── widgets/          # Seus botões e cards personalizados
├── test/
└── pubspec.yaml


````

## 🛠️ Como Instalar e Executar
1. Garanta que você tenha o **Flutter SDK** instalado.
2. Clone este repositório: `git clone https://github.com/seu-usuario/sgc_msclean.git`
3. Configure as chaves do **Supabase** no arquivo de constantes.
4. Execute a aplicação: `flutter run`

## 📜 Licença
Este projeto está licenciado sob a licença [MIT](https://opensource.org/licenses/MIT).