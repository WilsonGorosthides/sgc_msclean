import 'familia.dart';

export 'familia.dart' show Familia, TipoDeServico;

// Unidade de cobrança de um serviço da tabela de preços (RF-013).
enum UnidadeDeCobranca {
  peca('peca', 'por peça'),
  m2('m2', 'por m²');

  const UnidadeDeCobranca(this.codigo, this.rotulo);

  // Valor gravado na coluna `unidade` (check 'peca' | 'm2').
  final String codigo;
  final String rotulo;

  static UnidadeDeCobranca deCodigo(Object? codigo) =>
      codigo == m2.codigo ? m2 : peca;
}

// Grupo do item na tabela (#134), como no app de referência: produto, mão de
// obra ou imprevisto. É o que a nota do orçamento (RF-017) separa; sem grupo
// informado (linhas e registros de antes), mão de obra.
enum Categoria {
  produto('produto', 'Produtos', 'Produto'),
  maoDeObra('mao_de_obra', 'Mão de obra', 'Mão de obra'),
  imprevisto('imprevisto', 'Imprevistos', 'Imprevisto');

  const Categoria(this.codigo, this.titulo, this.rotulo);

  // Valor da coluna `categoria` (e da chave no jsonb do registro).
  final String codigo;
  // Título do grupo (tabela, quadro Outros, rodapé).
  final String titulo;
  // Escolha no editor.
  final String rotulo;

  static Categoria deCodigo(Object? codigo) {
    for (final c in values) {
      if (c.codigo == codigo) return c;
    }
    return maoDeObra;
  }
}

// Serviço da tabela de preços (RF-013, parte 1, issue #123). Cada serviço é
// independente: impermeabilização é um serviço completo, como higienização, e
// o combo é escolher os dois (ou cadastrar o combo como mais um serviço).
//
// Desde a #134, o serviço diz a que peça, variante e serviço corresponde — é
// por aí que o seletor de peças acha o preço. Sem peça, é um item avulso.
class ItemDePreco {
  final String? id;
  final String nome;
  final UnidadeDeCobranca unidade;
  // Nulo = ainda sem valor: a tabela começa assim e ela completa.
  final double? valor;
  // Posição na lista (a sugerida vem na ordem do negócio; um novo vai ao fim).
  final int ordem;
  // Peça (família), variante (lugares, tamanho) e serviço; nulos no avulso.
  final Familia? peca;
  final String? variante;
  final TipoDeServico? servico;
  // Sofá ou poltrona retrátil/reclinável (#134). Na tabela, o `valor` dessa
  // linha é o acréscimo sobre a mesma peça comum; copiada para o atendimento,
  // já é o preço final (comum + acréscimo).
  final bool retratil;
  // Ajuste só no registro (CT-102): no serviço copiado para a peça, o preço
  // pode mudar (tecido especial, desconto) sem mexer na tabela. Guarda o
  // preço da tabela e a justificativa, se ela der uma.
  final bool ajustado;
  final double? valorDaTabela;
  final String? justificativa;
  // Grupo (#134). Um produto com peça e serviço vem junto com o serviço da
  // peça (o impermeabilizante com a impermeabilização); sem peça, é avulso.
  final Categoria categoria;

  const ItemDePreco({
    this.id,
    required this.nome,
    required this.unidade,
    this.valor,
    this.ordem = 0,
    this.peca,
    this.variante,
    this.servico,
    this.retratil = false,
    this.ajustado = false,
    this.valorDaTabela,
    this.justificativa,
    this.categoria = Categoria.maoDeObra,
  });

  bool get semValor => valor == null;

  // Item avulso: entra pelo quadro Outros, sem peça.
  bool get avulso => peca == null;

  // Produto que acompanha um serviço da peça (não é o preço do serviço).
  bool get produtoDoServico =>
      categoria == Categoria.produto && peca != null && servico != null;

  factory ItemDePreco.fromMap(Map<String, dynamic> map) {
    final valor = map['valor'];
    final ordem = map['ordem'];
    final variante = map['variante']?.toString();
    final daTabela = map['valor_tabela'];
    final justificativa = map['justificativa']?.toString();
    return ItemDePreco(
      id: map['id']?.toString(),
      nome: (map['nome'] ?? '').toString(),
      unidade: UnidadeDeCobranca.deCodigo(map['unidade']),
      valor: valor is num ? valor.toDouble() : null,
      ordem: ordem is num ? ordem.toInt() : 0,
      peca: Familia.deCodigo(map['peca']),
      variante: (variante == null || variante.isEmpty) ? null : variante,
      servico: TipoDeServico.deCodigo(map['servico']),
      retratil: map['retratil'] == true,
      ajustado: map['ajustado'] == true,
      valorDaTabela: daTabela is num ? daTabela.toDouble() : null,
      justificativa: (justificativa == null || justificativa.isEmpty)
          ? null
          : justificativa,
      categoria: Categoria.deCodigo(map['categoria']),
    );
  }

  // Linha do banco, sem id (gerado pelo Supabase no insert) nem criado_em.
  Map<String, dynamic> toMap() => {
        'nome': nome,
        'unidade': unidade.codigo,
        'valor': valor,
        'ordem': ordem,
        'peca': peca?.codigo,
        'variante': variante,
        'servico': servico?.codigo,
        'retratil': retratil,
        'categoria': categoria.codigo,
      };

  // Cópia para o registro (atendimento): o preço de agora, sem id nem ordem.
  ItemDePreco copia() => ItemDePreco(
        nome: nome,
        unidade: unidade,
        valor: valor,
        peca: peca,
        variante: variante,
        servico: servico,
        retratil: retratil,
        categoria: categoria,
      );

  // O serviço com outro preço só neste registro (CT-102). Ajustar de novo
  // mantém o preço da tabela de antes; justificativa em branco não fica.
  ItemDePreco ajustar(double novo, String? motivo) {
    final texto = motivo?.trim();
    return ItemDePreco(
      nome: nome,
      unidade: unidade,
      valor: novo,
      peca: peca,
      variante: variante,
      servico: servico,
      retratil: retratil,
      ajustado: true,
      valorDaTabela: ajustado ? valorDaTabela : valor,
      justificativa: (texto == null || texto.isEmpty) ? null : texto,
      categoria: categoria,
    );
  }

  // Volta ao preço da tabela copiado no registro.
  ItemDePreco semAjuste() => !ajustado
      ? this
      : ItemDePreco(
          nome: nome,
          unidade: unidade,
          valor: valorDaTabela,
          peca: peca,
          variante: variante,
          servico: servico,
          retratil: retratil,
          categoria: categoria,
        );

  // Lista inicial (RF-013): sem valor, para ela completar. Higienização e
  // impermeabilização como serviços separados, nunca um como extra do outro.
  // Cada linha já diz peça, variante e serviço (#134). Sem linhas de
  // retrátil: a linha retrátil é só o acréscimo sobre o preço comum, e ela
  // cadastra quando quiser.
  // Cortina por folha. Os produtos e os imprevistos (#134) seguem o app de
  // referência: o impermeabilizante do sofá vem junto com a impermeabilização
  // (que fica sendo a aplicação, mão de obra).
  static List<ItemDePreco> listaSugerida() {
    const hig = TipoDeServico.higienizar;
    const imp = TipoDeServico.impermeabilizar;
    final itens = <ItemDePreco>[];

    void servico(Familia f, TipoDeServico s,
        {String? variante,
        bool retratil = false,
        UnidadeDeCobranca unidade = UnidadeDeCobranca.peca}) {
      itens.add(ItemDePreco(
        nome: nomeDoServico(f, variante, retratil, s),
        unidade: unidade,
        peca: f,
        variante: variante,
        servico: s,
        retratil: retratil,
      ));
    }

    for (final s in [hig, imp]) {
      for (final v in Familia.sofa.variantes) {
        servico(Familia.sofa, s, variante: v);
      }
    }
    for (final s in [hig, imp]) {
      servico(Familia.poltrona, s);
    }
    for (final s in [hig, imp]) {
      servico(Familia.cadeira, s);
    }
    for (final s in [hig, imp]) {
      servico(Familia.tapete, s, unidade: UnidadeDeCobranca.m2);
    }
    servico(Familia.cortina, hig);
    for (final t in Familia.colchao.variantes) {
      servico(Familia.colchao, hig, variante: t);
    }
    for (final nome in ['Remoção de odor', 'Remoção de mancha', 'Deslocamento']) {
      itens.add(ItemDePreco(nome: nome, unidade: UnidadeDeCobranca.peca));
    }
    for (final v in Familia.sofa.variantes) {
      itens.add(ItemDePreco(
        nome: 'Impermeabilizante ${Familia.sofa.tipo} '
            '${Familia.sofa.nomeDaVariante(v)}',
        unidade: UnidadeDeCobranca.peca,
        peca: Familia.sofa,
        variante: v,
        servico: imp,
        categoria: Categoria.produto,
      ));
    }
    for (final nome in [
      'Neutralizador de odor',
      'Tira-manchas',
      'Hidratante de couro',
    ]) {
      itens.add(ItemDePreco(
          nome: nome,
          unidade: UnidadeDeCobranca.peca,
          categoria: Categoria.produto));
    }
    for (final nome in [
      'Segunda lavagem (sujeira pesada)',
      'Excesso de pelo de pet',
      'Tratamento de mofo',
      'Urina com odor',
    ]) {
      itens.add(ItemDePreco(
          nome: nome,
          unidade: UnidadeDeCobranca.peca,
          categoria: Categoria.imprevisto));
    }
    return [
      for (var i = 0; i < itens.length; i++)
        ItemDePreco(
          nome: itens[i].nome,
          unidade: itens[i].unidade,
          ordem: i,
          peca: itens[i].peca,
          variante: itens[i].variante,
          servico: itens[i].servico,
          retratil: itens[i].retratil,
          categoria: itens[i].categoria,
        ),
    ];
  }
}
