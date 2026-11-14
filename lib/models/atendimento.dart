import 'peca.dart';

enum Periodo {
  manha('Manhã'),
  tarde('Tarde');

  const Periodo(this.rotulo);

  final String rotulo;

  // Valor gravado na coluna `periodo` ('manha' | 'tarde').
  static Periodo fromBanco(dynamic valor) =>
      valor == 'tarde' ? Periodo.tarde : Periodo.manha;
}

// Um atendimento da agenda (RF-010): data, período, hora opcional, cliente e
// as peças do serviço. Só os campos que a agenda exibe; o registro completo
// (RF-005) e os estados de conclusão (RF-014) entram nas suas entregas.
class Atendimento {
  final String? id;
  final DateTime data; // só a data, à meia-noite local
  final Periodo periodo;
  final String? hora; // 'HH:MM'
  final String clienteId;
  final String local;
  final List<Peca> pecas;
  final double? valor;
  final DateTime? criadoEm;

  // Estados de conclusão (RF-014): independentes — um não vale pelo outro.
  final bool feito; // serviço feito
  final bool pago; // cliente pagou

  // Concluído somente com os dois marcados.
  bool get concluido => feito && pago;

  Atendimento copyWith({bool? feito, bool? pago}) => Atendimento(
        id: id,
        data: data,
        periodo: periodo,
        hora: hora,
        clienteId: clienteId,
        local: local,
        pecas: pecas,
        valor: valor,
        criadoEm: criadoEm,
        feito: feito ?? this.feito,
        pago: pago ?? this.pago,
      );

  Atendimento({
    this.id,
    required this.data,
    required this.periodo,
    this.hora,
    required this.clienteId,
    this.local = '',
    this.pecas = const [],
    this.valor,
    this.criadoEm,
    this.feito = false,
    this.pago = false,
  });

  factory Atendimento.fromMap(Map<String, dynamic> map) {
    final data = DateTime.parse(map['data'].toString());
    final hora = map['hora']?.toString();
    final valor = map['valor'];
    final criadoEm = map['criado_em']?.toString();
    return Atendimento(
      id: map['id']?.toString(),
      data: DateTime(data.year, data.month, data.day),
      periodo: Periodo.fromBanco(map['periodo']),
      // a coluna `time` volta como HH:MM:SS; a agenda só usa HH:MM
      hora: (hora == null || hora.isEmpty)
          ? null
          : hora.substring(0, hora.length < 5 ? hora.length : 5),
      clienteId: map['cliente_id'].toString(),
      local: (map['local'] ?? '').toString(),
      pecas: _lerPecas(map['pecas']),
      valor: valor is num ? valor.toDouble() : null,
      criadoEm: criadoEm == null ? null : DateTime.tryParse(criadoEm),
      feito: map['feito'] == true,
      pago: map['pago'] == true,
    );
  }

  // Mapa para escrita no banco; sem id (gerado pelo Supabase), sem criado_em
  // (default now() na tabela) e sem feito/pago: as marcas têm escrita própria
  // (marcarConclusao), para salvar o formulário não apagar uma marca.
  Map<String, dynamic> toMap() => {
        'data': '${data.year}-${_dois(data.month)}-${_dois(data.day)}',
        'periodo': periodo.name,
        'hora': hora,
        'cliente_id': clienteId,
        'local': local,
        'pecas': pecas.map((p) => p.toMap()).toList(),
        'valor': valor,
      };

  static String _dois(int n) => n.toString().padLeft(2, '0');

  static List<Peca> _lerPecas(dynamic valor) {
    if (valor is! List) return const [];
    return valor
        .whereType<Map>()
        .map((p) => Peca.fromMap(p.cast<String, dynamic>()))
        .toList();
  }
}
