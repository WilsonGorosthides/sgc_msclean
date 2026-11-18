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
  // Sofá ou poltrona retrátil/reclinável: preço próprio, se ela cadastrar
  // um; senão vale o da mesma peça (#134).
  final bool retratil;
  // Ajuste só no registro (CT-102): no serviço copiado para a peça, o preço
  // pode mudar (tecido especial, desconto) sem mexer na tabela. Guarda o
  // preço da tabela e a justificativa, se ela der uma.
  final bool ajustado;
  final double? valorDaTabela;
  final String? justificativa;

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
  });

  bool get semValor => valor == null;

  // Item avulso: entra pelo quadro Outros, sem peça.
  bool get avulso => peca == null;

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
        );

  // Lista inicial (RF-013): sem valor, para ela completar. Higienização e
  // impermeabilização como serviços separados, nunca um como extra do outro.
  // Cada linha já diz peça, variante e serviço (#134). Sem linhas de
  // retrátil: o retrátil usa o preço comum até ela cadastrar um próprio.
  // Cortina por folha.
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
        ),
    ];
  }
}
