// Peça de um atendimento (RF-005): o negócio é cobrado por peça e, nas peças
// medidas, por metragem. Persistida dentro do jsonb `pecas` do atendimento.
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

  const Peca({
    required this.tipo,
    this.quantidade = 1,
    this.largura,
    this.comprimento,
  });

  factory Peca.fromMap(Map<String, dynamic> map) {
    double? lerNumero(dynamic v) => v is num ? v.toDouble() : null;
    final quantidade = map['quantidade'];
    return Peca(
      tipo: (map['tipo'] ?? '').toString(),
      quantidade: quantidade is num ? quantidade.toInt() : 1,
      largura: lerNumero(map['largura']),
      comprimento: lerNumero(map['comprimento']),
    );
  }

  // Mapa para o jsonb `pecas`; as medidas só entram quando existem.
  Map<String, dynamic> toMap() => {
        'tipo': tipo,
        'quantidade': quantidade,
        if (largura != null) 'largura': largura,
        if (comprimento != null) 'comprimento': comprimento,
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
