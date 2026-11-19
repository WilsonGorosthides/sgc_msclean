// Família da peça (RF-013, seletor de peças, issue #134): o primeiro passo da
// escolha e a chave que casa a peça com a tabela de preços (coluna `peca`).
// A ordem é a dos quadros na tela, pela frequência no negócio.
enum Familia {
  sofa('sofa', 'sofá', 'Sofá', ['2', '3', '4', 'canto'], retratil: true),
  tapete('tapete', 'tapete', 'Tapete', []),
  poltrona('poltrona', 'poltrona', 'Poltrona', [], retratil: true),
  cortina('cortina', 'cortina', 'Cortina', []),
  colchao('colchao', 'colchão', 'Colchão', ['solteiro', 'casal', 'queen', 'king']),
  cadeira('cadeira', 'cadeira', 'Cadeira', []),
  // Itens avulsos (odor, mancha, deslocamento): sem peça na tabela.
  outros(null, 'outro', 'Outros', []);

  const Familia(this.codigo, this.tipo, this.rotulo, this.variantes,
      {this.retratil = false});

  // Valor da coluna `peca` da tabela de preços; nulo nos avulsos.
  final String? codigo;
  // Valor de `Peca.tipo` no jsonb do atendimento (o mesmo desde a #77).
  final String tipo;
  final String rotulo;
  // Variantes que mudam o preço (lugares, tamanho), na ordem do − / +.
  final List<String> variantes;
  // Tem o interruptor retrátil/reclinável.
  final bool retratil;

  static Familia? deCodigo(Object? codigo) {
    for (final f in values) {
      if (f.codigo != null && f.codigo == codigo) return f;
    }
    return null;
  }

  // Tipo desconhecido (ou "outro") cai em Outros.
  static Familia deTipo(String tipo) {
    for (final f in values) {
      if (f.tipo == tipo) return f;
    }
    return outros;
  }

  // "3" → "3 lugares", "canto" → "de canto", "casal" → "casal".
  String nomeDaVariante(String variante) {
    if (this == sofa) {
      return variante == 'canto' ? 'de canto' : '$variante lugares';
    }
    return variante;
  }
}

// Serviço de uma peça: dois serviços completos e independentes (regra da
// proprietária). Impermeabilizar nunca é extra de higienizar.
enum TipoDeServico {
  higienizar('higienizar', 'Higienizar', 'Higienização'),
  impermeabilizar('impermeabilizar', 'Impermeabilizar', 'Impermeabilização');

  const TipoDeServico(this.codigo, this.rotulo, this.substantivo);

  // Valor da coluna `servico`.
  final String codigo;
  // Botão do cartão ("Higienizar").
  final String rotulo;
  // Começo do nome na tabela ("Higienização sofá 3 lugares").
  final String substantivo;

  static TipoDeServico? deCodigo(Object? codigo) {
    for (final s in values) {
      if (s.codigo == codigo) return s;
    }
    return null;
  }

  // Serviço gravado antes da #134 (sem a chave): reconhecido pelo nome.
  static TipoDeServico? peloNome(String nome) {
    final n = nome.toLowerCase();
    if (n.startsWith('higieniza')) return higienizar;
    if (n.startsWith('impermeabiliza')) return impermeabilizar;
    return null;
  }
}

// Nome do serviço na tabela, montado de peça, variante e serviço:
// "Higienização sofá 3 lugares", "Impermeabilização de tapete",
// "Higienização colchão casal", "... retrátil".
String nomeDoServico(Familia familia, String? variante, bool retratil,
    TipoDeServico servico) {
  final peca = switch (familia) {
    Familia.tapete || Familia.cortina => 'de ${familia.tipo}',
    _ => familia.tipo,
  };
  final partes = [
    servico.substantivo,
    peca,
    if (variante != null) familia.nomeDaVariante(variante),
    if (retratil) 'retrátil',
  ];
  return partes.join(' ');
}
