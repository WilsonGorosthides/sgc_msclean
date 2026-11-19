import '../models/atendimento.dart';
import 'agenda.dart';

// Histórico do cliente (RF-011, issue #81): quanto foi cobrado e quando foi a
// última visita. Funções puras; o "hoje" entra por parâmetro, como na agenda.

// Atendimentos do cliente até hoje, do mais recente ao mais antigo. O que
// está marcado para depois de hoje ainda não é visita e fica de fora.
List<Atendimento> historicoDoCliente(
    List<Atendimento> todos, String clienteId, DateTime hoje) {
  final limite = soData(hoje);
  final doCliente = [
    for (final a in todos)
      if (a.clienteId == clienteId && !soData(a.data).isAfter(limite)) a,
  ];
  // List.sort não é estável: no mesmo dia, o registrado por último vem antes.
  doCliente.sort((a, b) {
    final porData = b.data.compareTo(a.data);
    if (porData != 0) return porData;
    final ca = a.criadoEm;
    final cb = b.criadoEm;
    if (ca != null && cb != null) return cb.compareTo(ca);
    return 0;
  });
  return doCliente;
}

// O mais recente com valor registrado (o histórico já vem ordenado).
Atendimento? ultimoComValor(List<Atendimento> historico) {
  for (final a in historico) {
    if (a.valor != null) return a;
  }
  return null;
}

// "hoje", "ontem", "há 5 dias", "há 3 meses", "há 1 ano" — mesma régua do
// protótipo: mês de 30 dias, arredondado.
String haQuantoTempo(DateTime data, DateTime hoje) {
  // arredonda: com horário de verão, um dia de calendário pode ter 23 horas
  final dias = (soData(hoje).difference(soData(data)).inHours / 24).round();
  if (dias <= 0) return 'hoje';
  if (dias == 1) return 'ontem';
  if (dias < 30) return 'há $dias dias';
  final meses = (dias / 30).round();
  if (meses < 12) return 'há $meses ${meses > 1 ? 'meses' : 'mês'}';
  final anos = meses ~/ 12;
  return 'há $anos ${anos > 1 ? 'anos' : 'ano'}';
}

// Linha sob o cliente escolhido no atendimento (#129): "última vez há 3 meses
// · R$ 250,00". Quando o último valor é de uma visita mais antiga, vai com a
// data dela. [semId]: na edição, o próprio atendimento não conta.
String resumoDoHistorico(
  List<Atendimento> todos,
  String clienteId,
  DateTime hoje, {
  String? semId,
}) {
  final historico = [
    for (final a in historicoDoCliente(todos, clienteId, hoje))
      if (semId == null || a.id != semId) a,
  ];
  if (historico.isEmpty) return 'primeiro atendimento';
  final ultima = historico.first;
  final texto = 'última vez ${haQuantoTempo(ultima.data, hoje)}';
  final comValor = ultimoComValor(historico);
  if (comValor == null) return texto;
  final valor = valorEmReais(comValor.valor!);
  return identical(comValor, ultima)
      ? '$texto · $valor'
      : '$texto · $valor em ${dataCurta(comValor.data)}';
}

// "12/08/26"
String dataCurta(DateTime d) =>
    '${_dois(d.day)}/${_dois(d.month)}/${_dois(d.year % 100)}';

String _dois(int n) => n.toString().padLeft(2, '0');
