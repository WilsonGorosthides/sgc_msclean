import 'item_de_preco.dart';

// Peça de um atendimento (RF-005): o negócio é cobrado por peça e, nas peças
// medidas, por metragem. Persistida dentro do jsonb `pecas` do atendimento.
// Os serviços da peça (RF-013, #124) vêm da tabela de preços com o preço
// copiado: mudar a tabela depois não muda o que foi registrado.
class Peca {
  // Tipos oferecidos no formulário (RF-005), na ordem de frequência do
  // negócio; "outro" fecha a lista.
  static const tipos = [
    'tapete',
    'sofá',
    'poltrona',
    'cortina',
    'colchão',
    'cadeira',
    'outro',
  ];

  // Só o tapete é cobrado por metragem (largura × comprimento); o resto é
  // contado por unidade.
  static bool ehMedido(String tipo) => tipo == 'tapete';

  final String tipo;
  final int quantidade;
  final double? largura;
  final double? comprimento;
  // Variante que muda o preço (#134): lugares do sofá ('2', '3', '4',
  // 'canto') ou tamanho do colchão; nula nas demais e nas peças de antes.
  final String? variante;
  // Sofá ou poltrona retrátil/reclinável (#134).
  final bool retratil;
  // Serviços escolhidos (higienização, impermeabilização ou os dois).
  final List<ItemDePreco> servicos;

  const Peca({
    required this.tipo,
    this.quantidade = 1,
    this.largura,
    this.comprimento,
    this.variante,
    this.retratil = false,
    this.servicos = const [],
  });

  // Área em m² (largura × comprimento); nula sem uma das medidas.
  double? get area =>
      largura != null && comprimento != null ? largura! * comprimento! : null;

  factory Peca.fromMap(Map<String, dynamic> map) {
    double? lerNumero(dynamic v) => v is num ? v.toDouble() : null;
    final quantidade = map['quantidade'];
    return Peca(
      tipo: (map['tipo'] ?? '').toString(),
      quantidade: quantidade is num ? quantidade.toInt() : 1,
      largura: lerNumero(map['largura']),
      comprimento: lerNumero(map['comprimento']),
      variante: map['variante']?.toString(),
      retratil: map['retratil'] == true,
      servicos: [
        if (map['servicos'] is List)
          for (final s in (map['servicos'] as List).whereType<Map>())
            _lerServico(s.cast<String, dynamic>()),
      ],
    );
  }

  // Serviço gravado antes da #134 não tem a chave `servico`: o tipo
  // (higienizar ou impermeabilizar) sai do começo do nome.
  static ItemDePreco _lerServico(Map<String, dynamic> map) {
    final item = ItemDePreco.fromMap(map);
    if (item.servico != null || map.containsKey('servico')) return item;
    final pelo = TipoDeServico.peloNome(item.nome);
    if (pelo == null) return item;
    return ItemDePreco(
      nome: item.nome,
      unidade: item.unidade,
      valor: item.valor,
      servico: pelo,
    );
  }

  // Mapa para o jsonb `pecas`; as medidas e os serviços só entram quando
  // existem. Do serviço vai o que o cálculo usa: nome, unidade e o valor da
  // tabela no momento do registro.
  Map<String, dynamic> toMap() => {
        'tipo': tipo,
        'quantidade': quantidade,
        if (largura != null) 'largura': largura,
        if (comprimento != null) 'comprimento': comprimento,
        if (variante != null) 'variante': variante,
        if (retratil) 'retratil': true,
        if (servicos.isNotEmpty)
          'servicos': [
            for (final s in servicos)
              {
                'nome': s.nome,
                'unidade': s.unidade.codigo,
                'valor': s.valor,
                if (s.servico != null) 'servico': s.servico!.codigo,
              },
          ],
      };

  // Texto do cartão da agenda: "2× tapete 3 × 2", "6 folhas de cortina".
  String get resumo {
    if (largura != null && comprimento != null) {
      final medidas = '${_numero(largura!)} × ${_numero(comprimento!)}';
      return '${_prefixo()}$tipo $medidas';
    }
    if (tipo == 'cortina') {
      return '$quantidade ${quantidade > 1 ? 'folhas' : 'folha'} de cortina';
    }
    final partes = [
      tipo,
      if (variante != null) Familia.deTipo(tipo).nomeDaVariante(variante!),
      if (retratil) 'retrátil',
    ];
    return '${_prefixo()}${partes.join(' ')}';
  }

  String _prefixo() => quantidade > 1 ? '$quantidade× ' : '';

  // 8.0 -> "8"; 4.5 -> "4,5" (vírgula decimal, como a proprietária escreve).
  static String _numero(double v) {
    final texto = v == v.truncateToDouble() ? v.toInt().toString() : '$v';
    return texto.replaceAll('.', ',');
  }
}
