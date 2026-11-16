import '../models/atendimento.dart';
import '../models/client_model.dart';
import 'agenda.dart';

// Avisos no celular (RF-015, issue #95): QUAIS avisos existem e QUANDO, a
// partir da agenda. Função pura, com o "agora" por parâmetro — a entrega ao
// Android fica em services/avisos_do_aparelho.dart.

enum TipoAviso { vespera, dia, hora, cobranca }

class Aviso {
  const Aviso({
    required this.id,
    required this.tipo,
    required this.quando,
    required this.dia,
    required this.titulo,
    required this.corpo,
  });

  final int id; // único na lista; os avisos são substituídos em bloco
  final TipoAviso tipo;
  final DateTime quando; // hora local em que o celular avisa
  final DateTime dia; // o dia da agenda que o toque abre
  final String titulo;
  final String corpo;
}

// Horários combinados com a proprietária em 2026-11-16 (issue #95).
const horaDaVespera = 19;
const horaDoDia = 7;
const horaDaCobranca = 10;
const diasAteCobrar = 3;

// O Android guarda até 500 alarmes por app; 60 cobre semanas de agenda.
const limiteDeAvisos = 60;

List<Aviso> planejarAvisos(
  List<Atendimento> atendimentos,
  List<ClientModel> clientes,
  DateTime agora,
) {
  final nomes = {for (final c in clientes) c.id: c.nome};
  String nome(Atendimento a) => nomes[a.clienteId] ?? 'Cliente';

  final rascunhos = <(TipoAviso, DateTime, DateTime, String, String)>[];

  // Resumos: um par (véspera e manhã) por dia com atendimento.
  final dias = {for (final a in atendimentos) soData(a.data)};
  for (final dia in dias) {
    final grupos = agruparPorPeriodo(atendimentosDoDia(atendimentos, dia));
    final total = grupos.values.fold<int>(0, (s, l) => s + l.length);
    final periodos = [
      for (final e in grupos.entries)
        '${e.value.length} ${e.key == Periodo.manha ? 'de manhã' : 'à tarde'}',
    ];
    final quem = grupos.values.expand((l) => l).map(nome).join(', ');
    final corpo = '${periodos.join(', ')} — $quem';
    final quantos = '$total ${total == 1 ? 'atendimento' : 'atendimentos'}';
    rascunhos.add((
      TipoAviso.vespera,
      DateTime(dia.year, dia.month, dia.day - 1, horaDaVespera),
      dia,
      'Amanhã: $quantos',
      corpo,
    ));
    rascunhos.add((
      TipoAviso.dia,
      DateTime(dia.year, dia.month, dia.day, horaDoDia),
      dia,
      'Hoje: $quantos',
      corpo,
    ));
  }

  for (final a in atendimentos) {
    final dia = soData(a.data);

    // Uma hora antes, só quando a hora foi anotada (a minoria).
    final hora = _lerHora(a.hora);
    if (hora != null) {
      rascunhos.add((
        TipoAviso.hora,
        DateTime(dia.year, dia.month, dia.day, hora.$1, hora.$2)
            .subtract(const Duration(hours: 1)),
        dia,
        'Em 1 hora: ${nome(a)}',
        a.local.isEmpty ? a.hora! : '${a.hora} · ${a.local}',
      ));
    }

    // Cobrança: feito e não pago, uma vez, no terceiro dia depois do
    // atendimento. Marcar o pago tira o atendimento daqui, e o aviso some na
    // próxima substituição.
    if (a.feito && !a.pago) {
      final data = '${_dois(dia.day)}/${_dois(dia.month)}';
      final valor = a.valor == null ? '' : ' · ${valorEmReais(a.valor!)}';
      rascunhos.add((
        TipoAviso.cobranca,
        DateTime(dia.year, dia.month, dia.day + diasAteCobrar, horaDaCobranca),
        dia,
        'Cobrar: ${nome(a)}',
        'Serviço de $data feito e ainda não pago$valor',
      ));
    }
  }

  // Só o que ainda vai acontecer, em ordem de horário; List.sort do Dart não
  // é estável, então o índice desempata.
  final futuros = [
    for (var i = 0; i < rascunhos.length; i++)
      if (rascunhos[i].$2.isAfter(agora)) (i, rascunhos[i]),
  ]..sort((x, y) {
      final porHora = x.$2.$2.compareTo(y.$2.$2);
      return porHora != 0 ? porHora : x.$1.compareTo(y.$1);
    });

  return [
    for (var i = 0; i < futuros.length && i < limiteDeAvisos; i++)
      Aviso(
        id: i + 1,
        tipo: futuros[i].$2.$1,
        quando: futuros[i].$2.$2,
        dia: futuros[i].$2.$3,
        titulo: futuros[i].$2.$4,
        corpo: futuros[i].$2.$5,
      ),
  ];
}

(int, int)? _lerHora(String? hora) {
  if (hora == null) return null;
  final partes = hora.split(':');
  if (partes.length < 2) return null;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null) return null;
  return (h, m);
}

String _dois(int n) => n.toString().padLeft(2, '0');
