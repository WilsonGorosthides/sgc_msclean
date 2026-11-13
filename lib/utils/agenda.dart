import '../models/atendimento.dart';

// Funções puras da agenda (RF-010): calendário, contagem e ordem do dia.
// Nenhuma lê o relógio nem o Supabase — o "hoje" entra sempre por parâmetro.

const _diasDaSemana = [
  'domingo',
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
];

const _abreviaturas = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

// Descarta a hora: as datas da agenda são sempre à meia-noite local.
DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

// Soma por calendário (e não por Duration), para não depender de horário de verão.
DateTime somarDias(DateTime d, int dias) =>
    DateTime(d.year, d.month, d.day + dias);

// Dia 1 do mês de destino: navegar de 31/01 para "mês seguinte" não pode pular fevereiro.
DateTime somarMeses(DateTime d, int meses) =>
    DateTime(d.year, d.month + meses, 1);

// Os sete dias, de domingo a sábado, que contêm [d].
List<DateTime> semanaDe(DateTime d) {
  final domingo = somarDias(d, -(d.weekday % DateTime.sunday));
  return [for (var i = 0; i < 7; i++) somarDias(domingo, i)];
}

// Grade do mês em linhas de sete colunas (domingo a sábado); células de fora
// do mês são null.
List<DateTime?> gradeDoMes(DateTime mes) {
  final primeiro = DateTime(mes.year, mes.month, 1);
  final ultimo = DateTime(mes.year, mes.month + 1, 0);
  final antes = primeiro.weekday % DateTime.sunday;
  final total = antes + ultimo.day;
  final depois = (7 - total % 7) % 7;
  return [
    for (var i = 0; i < antes; i++) null,
    for (var dia = 1; dia <= ultimo.day; dia++)
      DateTime(mes.year, mes.month, dia),
    for (var i = 0; i < depois; i++) null,
  ];
}

Map<DateTime, int> contagemPorDia(List<Atendimento> atendimentos) {
  final contagem = <DateTime, int>{};
  for (final a in atendimentos) {
    final dia = soData(a.data);
    contagem[dia] = (contagem[dia] ?? 0) + 1;
  }
  return contagem;
}

List<Atendimento> atendimentosDoDia(List<Atendimento> todos, DateTime dia) {
  final alvo = soData(dia);
  return todos.where((a) => soData(a.data) == alvo).toList();
}

// Manhã antes da tarde. Dentro do período: os com hora, por hora; depois os
// sem hora, na ordem em que foram registrados. Período vazio não entra.
Map<Periodo, List<Atendimento>> agruparPorPeriodo(List<Atendimento> doDia) {
  final grupos = <Periodo, List<Atendimento>>{};
  for (final periodo in Periodo.values) {
    final lista = doDia.where((a) => a.periodo == periodo).toList();
    if (lista.isEmpty) continue;
    grupos[periodo] = _ordenarPeriodo(lista);
  }
  return grupos;
}

// List.sort do Dart não é estável; o índice original desempata.
List<Atendimento> _ordenarPeriodo(List<Atendimento> lista) {
  final indexada = [for (var i = 0; i < lista.length; i++) (i, lista[i])];
  indexada.sort((x, y) {
    final a = x.$2;
    final b = y.$2;
    if (a.hora != null && b.hora != null) {
      final porHora = a.hora!.compareTo(b.hora!);
      if (porHora != 0) return porHora;
    } else if (a.hora != null) {
      return -1;
    } else if (b.hora != null) {
      return 1;
    }
    final ca = a.criadoEm;
    final cb = b.criadoEm;
    if (ca != null && cb != null) {
      final porRegistro = ca.compareTo(cb);
      if (porRegistro != 0) return porRegistro;
    }
    return x.$1.compareTo(y.$1);
  });
  return [for (final item in indexada) item.$2];
}

String nomeDiaSemana(DateTime d) => _diasDaSemana[d.weekday % DateTime.sunday];

String abreviaturaDiaSemana(DateTime d) =>
    _abreviaturas[d.weekday % DateTime.sunday];

String nomeMes(DateTime d) => _meses[d.month - 1];

// "quarta-feira, 11 de novembro de 2026"
String dataPorExtenso(DateTime d) =>
    '${nomeDiaSemana(d)}, ${d.day} de ${nomeMes(d)} de ${d.year}';

// Chave estável por dia ("2026-11-11"), usada pelas telas e pelos testes.
String chaveDoDia(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// "R$ 1.250,00": vírgula decimal e ponto de milhar, como a proprietária escreve.
String valorEmReais(double valor) {
  final centavos = (valor * 100).round();
  final inteiro = (centavos ~/ 100).toString();
  final fracao = (centavos % 100).toString().padLeft(2, '0');
  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
  }
  return 'R\$ $buffer,$fracao';
}

// Lê o valor digitado ("180,50", "R$ 1.250,00", "180"): vírgula ou ponto como
// decimal, milhar ignorado. Vazio ou ilegível vira nulo — valor é opcional.
double? lerValor(String texto) {
  var limpo = texto.replaceAll(RegExp(r'[^\d,.]'), '');
  if (limpo.isEmpty) return null;
  if (limpo.contains(',')) {
    // vírgula é o decimal; pontos são milhar
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  } else if (limpo.indexOf('.') != limpo.lastIndexOf('.')) {
    // vários pontos sem vírgula: todos são milhar
    limpo = limpo.replaceAll('.', '');
  }
  return double.tryParse(limpo);
}
