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
class ItemDePreco {
  final String? id;
  final String nome;
  final UnidadeDeCobranca unidade;
  // Nulo = ainda sem valor: a tabela começa assim e ela completa.
  final double? valor;
  // Posição na lista (a sugerida vem na ordem do negócio; um novo vai ao fim).
  final int ordem;

  const ItemDePreco({
    this.id,
    required this.nome,
    required this.unidade,
    this.valor,
    this.ordem = 0,
  });

  bool get semValor => valor == null;

  factory ItemDePreco.fromMap(Map<String, dynamic> map) {
    final valor = map['valor'];
    final ordem = map['ordem'];
    return ItemDePreco(
      id: map['id']?.toString(),
      nome: (map['nome'] ?? '').toString(),
      unidade: UnidadeDeCobranca.deCodigo(map['unidade']),
      valor: valor is num ? valor.toDouble() : null,
      ordem: ordem is num ? ordem.toInt() : 0,
    );
  }

  // Linha do banco, sem id (gerado pelo Supabase no insert) nem criado_em.
  Map<String, dynamic> toMap() => {
        'nome': nome,
        'unidade': unidade.codigo,
        'valor': valor,
        'ordem': ordem,
      };

  // Lista inicial (RF-013): sem valor, para ela completar. Higienização e
  // impermeabilização como serviços separados, nunca um como extra do outro.
  static List<ItemDePreco> listaSugerida() {
    const peca = UnidadeDeCobranca.peca;
    const m2 = UnidadeDeCobranca.m2;
    const impermeabilizaveis = [
      'sofá 2 lugares',
      'sofá 3 lugares',
      'sofá 4 lugares',
      'sofá de canto',
      'poltrona',
      'cadeira',
    ];
    final itens = <(String, UnidadeDeCobranca)>[
      for (final p in impermeabilizaveis) ('Higienização $p', peca),
      for (final p in impermeabilizaveis) ('Impermeabilização $p', peca),
      ('Higienização colchão solteiro', peca),
      ('Higienização colchão casal', peca),
      ('Higienização colchão queen', peca),
      ('Higienização colchão king', peca),
      ('Higienização de tapete', m2),
      ('Impermeabilização de tapete', m2),
      ('Higienização de cortina', m2),
      ('Remoção de odor', peca),
      ('Remoção de mancha', peca),
      ('Deslocamento', peca),
    ];
    return [
      for (var i = 0; i < itens.length; i++)
        ItemDePreco(nome: itens[i].$1, unidade: itens[i].$2, ordem: i),
    ];
  }
}
