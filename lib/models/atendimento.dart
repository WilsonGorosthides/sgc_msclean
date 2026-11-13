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
    );
  }

  static List<Peca> _lerPecas(dynamic valor) {
    if (valor is! List) return const [];
    return valor
        .whereType<Map>()
        .map((p) => Peca.fromMap(p.cast<String, dynamic>()))
        .toList();
  }
}
