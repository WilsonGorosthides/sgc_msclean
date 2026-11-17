import 'item_de_preco.dart';

// Peça de um atendimento (RF-005): o negócio é cobrado por peça e, nas peças
// medidas, por metragem. Persistida dentro do jsonb `pecas` do atendimento.
// Os serviços da peça (RF-013, #124) vêm da tabela de preços com o preço
// copiado: mudar a tabela depois não muda o que foi registrado.
class Peca {
  // Tipos oferecidos no formulário (RF-005), na ordem de frequência do
  // negócio; "outro" fecha a lista.
  static const tipos = ['tapete', 'sofá', 'poltrona', 'cortina', 'colchão', 'outro'];

  // Só o tapete é cobrado por metragem (largura × comprimento); o resto é
  // contado por unidade.
  static bool ehMedido(String tipo) => tipo == 'tapete';

  final String tipo;
  final int quantidade;
  final double? largura;
  final double? comprimento;
  // Serviços escolhidos (higienização, impermeabilização ou os dois).
  final List<ItemDePreco> servicos;

  const Peca({
    required this.tipo,
    this.quantidade = 1,
    this.largura,
    this.comprimento,
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
      servicos: [
        if (map['servicos'] is List)
          for (final s in (map['servicos'] as List).whereType<Map>())
            ItemDePreco.fromMap(s.cast<String, dynamic>()),
      ],
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
        if (servicos.isNotEmpty)
          'servicos': [
            for (final s in servicos)
              {'nome': s.nome, 'unidade': s.unidade.codigo, 'valor': s.valor},
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
    return '${_prefixo()}$tipo';
  }

  String _prefixo() => quantidade > 1 ? '$quantidade× ' : '';

  // 8.0 -> "8"; 4.5 -> "4,5" (vírgula decimal, como a proprietária escreve).
  static String _numero(double v) {
    final texto = v == v.truncateToDouble() ? v.toInt().toString() : '$v';
    return texto.replaceAll('.', ',');
  }
}
