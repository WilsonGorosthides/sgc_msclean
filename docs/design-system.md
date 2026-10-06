# Design System — SGC para MSClean

## 1. Propósito

Este documento é a **especificação escrita** dos tokens visuais do aplicativo: cor,
tipografia, espaçamento e raio. Ele existe para que estilo deixe de ser decidido tela a
tela.

Nasceu do protótipo navegável da agenda
(<https://wilsongorosthides.github.io/sgc_msclean/>), que foi onde a paleta e a escala
tipográfica apareceram pela primeira vez — mas **não é uma cópia dele**. A seção 7 lista
o que mudou e por quê.

### Regra de fonte da verdade

> O **código Dart em `lib/theme/` é canônico.** Este documento e qualquer biblioteca de
> componentes em HTML são **vistas** dele. Quando um token mudar, muda primeiro no Dart e
> depois aqui.

O motivo é histórico e custou caro num projeto vizinho: manter duas definições
independentes da mesma coisa termina sempre com as duas divergindo, e a divergência só
aparece quando já é tarde. Uma fonte, várias vistas.

## 2. Cor

Todos os pares abaixo foram **medidos** contra o critério WCAG 2.1 nível AA para texto
normal (razão de contraste mínima de 4.5:1). Nenhum par em uso falha.

### 2.1 Superfícies e texto

| token | hex | papel | contraste medido |
|---|---|---|---|
| `fundo` | `#F2F4F4` | fundo da aplicação | — |
| `superficie` | `#FFFFFF` | cartões, folhas, campos | — |
| `superficieAlt` | `#FAFBFB` | cabeçalho, linha de total, faixas | — |
| `tinta` | `#12242A` | texto principal | **14.50** sobre `fundo` · **16.01** sobre `superficie` |
| `tintaFraca` | `#5C7178` | texto secundário, legendas | **4.65** sobre `fundo` · **5.14** sobre `superficie` |
| `tintaDesabilitada` | `#8699A0` | **só** controle desabilitado e ornamento | 2.97 — ver 2.4 |
| `borda` | `#DCE3E4` | borda padrão | — |
| `bordaForte` | `#C3CFD1` | borda enfatizada, divisor | — |

### 2.2 Cores de papel

| token | hex | fundo par | papel | contraste medido |
|---|---|---|---|---|
| `primaria` | `#0B6E7F` | `primariaFundo` `#E2F0F2` | ação principal, **manhã** | **5.91** sobre branco · **5.06** sobre o par |
| `tarde` | `#9E5C17` | `tardeFundo` `#F7EDDF` | período da **tarde** | **5.25** sobre branco · **4.54** sobre o par |
| `sucesso` | `#2D7958` | `sucessoFundo` `#E3F1EA` | serviço feito, cliente pagou | **5.27** sobre branco · **4.52** sobre o par |
| `alerta` | `#B3452F` | `alertaFundo` `#F8E7E3` | erro, conflito de horário | **5.51** sobre branco · **4.60** sobre o par |

### 2.3 Mapeamento semântico

A cor carrega informação, não decoração. Estes vínculos são parte do sistema:

| significado | token | origem |
|---|---|---|
| Manhã | `primaria` | luz fria do início do dia |
| Tarde | `tarde` | luz quente do fim do dia |
| Serviço feito / cliente pagou | `sucesso` | as marcas de conferido da agenda de papel (RF-014) |
| Conflito de horário, erro | `alerta` | RF-012 |

Manhã e tarde ganharem temperaturas opostas não é enfeite: é a única pista visual que
separa os dois blocos do dia quando a tela é olhada de relance, dentro do carro, entre um
atendimento e outro.

### 2.4 Sobre o `tintaDesabilitada`

O protótipo tinha **três** níveis de texto. O terceiro (`#8699A0`) mede **2.97** sobre
branco — reprova em AA até para texto grande. Corrigi-lo mantendo o matiz produz
`#5F7178`, que é indistinguível do `tintaFraca` (`#5C7178`).

Conclusão: **o terceiro nível de texto não sobrevive à acessibilidade.** O token
continua existindo, mas rebaixado — só para **controles desabilitados**, que a WCAG 2.1
isenta explicitamente do critério de contraste (§1.4.3), e para ornamento sem conteúdo.
Texto que precisa ser lido usa `tinta` ou `tintaFraca`, e a hierarquia do terceiro nível
passa a ser feita por **tamanho e peso**, não por cor.

## 3. Tipografia

Família única: **Archivo** (via `google_fonts`, já no `pubspec.yaml`).

| token | tamanho | peso | uso |
|---|---|---|---|
| `rotulo` | 11 | 600 | etiquetas em caixa alta, com `letterSpacing: 0.9` |
| `apoio` | 13 | 400 | legendas, endereço, lista de peças |
| `corpo` | 15 | 400 | texto padrão, campos |
| `titulo` | 17 | 600 | nome do cliente, título de folha |
| `secao` | 20 | 700 | título de tela |
| `display` | 26 | 700 | número em destaque, valor cobrado |

Onde houver dígito em coluna — valor, data, hora, contagem — usar
`FontFeature.tabularFigures()`, para os números não dançarem entre as linhas.

O `Caveat` do protótipo **não entra no app**. Era voz de página — a letra do caderno
citada uma vez — e dentro da interface viraria ruído.

## 4. Espaçamento

Escala de 4. Seis degraus, e nada fora deles.

| token | valor | uso típico |
|---|---|---|
| `xs` | 4 | separação dentro de um mesmo elemento |
| `sm` | 8 | entre itens irmãos de uma lista |
| `md` | 12 | padding interno de cartão pequeno |
| `lg` | 16 | padding de tela, padding de cartão |
| `xl` | 24 | entre blocos distintos |
| `xxl` | 32 | respiro de seção |

O protótipo usava **onze** valores diferentes, escolhidos a olho. Funcionou numa página;
não sobreviveria a sete telas com pessoas diferentes mexendo.

## 5. Raio

Três degraus, e nada fora deles.

| token | valor | uso |
|---|---|---|
| `pequeno` | 8 | selos, chips, campos |
| `medio` | 14 | cartões, botões, folhas |
| `grande` | 22 | contêineres de destaque |

O protótipo usava oito raios distintos. Mesma razão da seção anterior.

## 6. Como usar no Flutter

```dart
// Cor — sempre pelo tema, nunca hex literal na tela
Theme.of(context).colorScheme.primary
AppColors.tarde          // papéis que não cabem no ColorScheme

// Tipografia
Theme.of(context).textTheme.titleMedium    // = token "titulo"

// Espaçamento e raio
const EdgeInsets.all(AppSpacing.lg)
BorderRadius.circular(AppRadius.medio)
```

Nenhuma tela deve conter `Color(0x...)` nem `Colors.*`. Se um valor não existe no
sistema, a resposta é acrescentá-lo aqui e no `lib/theme/` — não improvisar na tela.

**Essa regra tem teste.** `test/unit/design_system_test.dart` varre `lib/screens/`
e falha se encontrar cor literal, listando arquivo e linha. Regra sem teste é
recomendação esquecida: sem a guarda, a próxima tela da agenda volta a hardcodear
e a revisão não pega. `lib/theme/` fica fora da varredura — é onde o sistema é
definido, e ali a cor literal é o próprio ponto.

## 7. O que mudou em relação ao protótipo

| mudança | motivo |
|---|---|
| `tarde` escurecido de `#B4691A` para `#9E5C17` | o original media 4.22 sobre branco e 3.64 sobre o próprio fundo — reprovava em AA |
| `sucesso` escurecido de `#2E7D5B` para `#2D7958` | media 4.29 sobre o próprio fundo — reprovava em AA |
| Terceiro nível de texto rebaixado a "desabilitado" | media 2.97 — ver seção 2.4 |
| Onze espaçamentos colapsados em seis | escala em vez de improviso |
| Oito raios colapsados em três | idem |
| Dezessete tamanhos de fonte colapsados em seis | idem |
| `Caveat` removido | voz de página, não de interface |

O protótipo continua válido como validação de **fluxo**. Como sistema visual, ele era um
rascunho — e um rascunho que não passava em acessibilidade.

## 8. Componentes

Os tokens acima são aplicados aos componentes do Material pelo `AppTheme`, de modo
que a tela não precise estilizar nada: um `Card` sem nenhum parâmetro já sai com a
forma do sistema. Doze temas de componente, cobrindo tudo o que as telas usam:

| componente | o que o tema fixa |
|---|---|
| `AppBar` | `superficie`, título centralizado, sem sombra, borda inferior `borda` |
| `Card` | `superficie`, raio médio, borda `borda`, elevação 0 |
| `ListTile` | título em `tinta`, subtítulo e ícone em `tintaFraca` |
| campo (`InputDecoration`) | preenchido em `superficie`, raio pequeno, borda `borda`; foco em `primaria` com 2px; erro em `alerta`; desabilitado em `tintaDesabilitada` |
| `FloatingActionButton` | `primaria` com ícone em `superficie` |
| `FilledButton` | `primaria`, raio médio, padding `xl`/`lg`; desabilitado em `borda` |
| `TextButton` | texto em `primaria`, raio pequeno |
| `IconButton` | `tintaFraca` |
| `SnackBar` | contraste invertido: fundo `tinta`, texto `fundo`, ação em `primariaFundo` |
| diálogo | `superficie`, raio grande, elevação 0 |
| divisor | `bordaForte`, 1px |
| indicador de progresso | `primaria` |

**Por que sem sombra.** Com o `surfaceTint` desligado (ver abaixo), a elevação do
Material 3 não teria como se manifestar em cor, e sobraria uma sombra solta. A
separação entre superfícies é feita por **borda**, não por elevação.

**Por que o `surfaceTint` está desligado.** No Material 3 ele tinge o cartão elevado
com a primária. Toda a paleta da seção 2 foi medida contra `#FFFFFF` e `#F2F4F4`;
com o tint ligado, qualquer cartão com elevação passaria a ter um branco azulado que
não foi medido.

**Por que o `ColorScheme` é escrito à mão.** `ColorScheme.fromSeed` derivaria as trinta
e tantas cores do esquema de uma única semente, pelo algoritmo tonal do Material 3, e
descartaria no caminho a paleta medida — inclusive as três correções da seção 7. O
custo assumido é manutenção manual.

`tarde` e `sucesso` ficam **fora** do `ColorScheme`, em `AppColors`: significam período
do dia e serviço concluído, e não nível de hierarquia Material. `secondary` e `tertiary`
espelham a primária, para que um widget que peça `tertiary` por acidente receba a paleta
principal em vez de um verde que mentiria sobre o estado do atendimento.

### Ainda fora deste documento

- **Widgets reutilizáveis.** O tema cobre os componentes do Material. Widgets próprios
  do domínio — cartão de atendimento, selo de período, linha de peça — nascem com as
  telas da agenda, não antes delas.
- **Tema escuro.** O app é claro. A decisão está registrada em `arquitetura.md` §7. Um
  tema escuro exigiria medir a paleta inteira de novo, e não há demanda da usuária.
- **Figma.** Fora do escopo do projeto, com a justificativa registrada em `arquitetura.md` §7.

## 9. Histórico de Versões

| Versão | Data | Autor | Alterações |
|---|---|---|---|
| 1.0 | 2026-09-23 | Wilson Gorosthides | Versão inicial: tokens de cor, tipografia, espaçamento e raio extraídos do protótipo da agenda e corrigidos para WCAG 2.1 AA. Regra de fonte da verdade (Dart canônico). Issue #60. |
| 1.1 | 2026-10-06 | Wilson Gorosthides | Tokens implementados em `lib/theme/` e aplicados: §6 registra a guarda automatizada da regra de "nenhuma cor na tela" (`design_system_test.dart`); §8 deixa de listar componentes como pendência e passa a documentar os doze temas de componente do `AppTheme`, com as justificativas de `ColorScheme` explícito, `surfaceTint` desligado e separação por borda em vez de sombra. Widgets de domínio passam a ser a única pendência de componente. Issue #60. |
