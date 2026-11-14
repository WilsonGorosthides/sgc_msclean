import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/utils/agenda.dart';

// Funções puras da agenda (RF-010): semana, mês, contagem por dia e ordem do
// dia. Sem relógio nem Supabase — o "hoje" nunca é lido aqui.
Atendimento _at(String id, DateTime data, Periodo periodo,
    {String? hora, int ordem = 0}) {
  return Atendimento(
    id: id,
    data: data,
    periodo: periodo,
    hora: hora,
    clienteId: 'c',
    criadoEm: DateTime(2026, 11, 1, 8, ordem),
  );
}

void main() {
  group('agenda_test:', () {
    test('semana vai do domingo ao sábado que contêm o dia', () {
      final semana = semanaDe(DateTime(2026, 11, 11)); // quarta-feira

      expect(semana.length, 7);
      expect(semana.first, DateTime(2026, 11, 8));
      expect(semana.first.weekday, DateTime.sunday);
      expect(semana.last, DateTime(2026, 11, 14));
      expect(semana.last.weekday, DateTime.saturday);
    });

    test('domingo abre a semana e sábado a fecha', () {
      expect(semanaDe(DateTime(2026, 11, 8)).first, DateTime(2026, 11, 8));
      expect(semanaDe(DateTime(2026, 11, 14)).first, DateTime(2026, 11, 8));
    });

    test('semana que atravessa a virada de mês', () {
      final semana = semanaDe(DateTime(2026, 12, 2));

      expect(semana.first, DateTime(2026, 11, 29));
      expect(semana.last, DateTime(2026, 12, 5));
    });

    test('somar dias atravessa o mês', () {
      expect(somarDias(DateTime(2026, 11, 28), 7), DateTime(2026, 12, 5));
      expect(somarDias(DateTime(2026, 12, 1), -1), DateTime(2026, 11, 30));
    });

    test('somar meses cai no dia 1 do mês de destino', () {
      expect(somarMeses(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 1));
      expect(somarMeses(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 1));
      expect(somarMeses(DateTime(2026, 1, 10), -1), DateTime(2025, 12, 1));
    });

    test('conta atendimentos por dia', () {
      final contagem = contagemPorDia([
        _at('1', DateTime(2026, 11, 9), Periodo.manha),
        _at('2', DateTime(2026, 11, 9), Periodo.tarde),
        _at('3', DateTime(2026, 11, 17), Periodo.manha),
      ]);

      expect(contagem[DateTime(2026, 11, 9)], 2);
      expect(contagem[DateTime(2026, 11, 17)], 1);
      expect(contagem[DateTime(2026, 11, 10)], isNull);
    });

    test('filtra os atendimentos de um dia', () {
      final todos = [
        _at('1', DateTime(2026, 11, 9), Periodo.manha),
        _at('2', DateTime(2026, 11, 10), Periodo.manha),
      ];

      expect(atendimentosDoDia(todos, DateTime(2026, 11, 10)).map((a) => a.id),
          ['2']);
    });

    test('manhã antes da tarde; com hora por hora; sem hora por registro', () {
      final dia = DateTime(2026, 11, 11);
      final grupos = agruparPorPeriodo([
        _at('tarde', dia, Periodo.tarde, ordem: 5),
        _at('sem-hora-2', dia, Periodo.manha, ordem: 4),
        _at('10h', dia, Periodo.manha, hora: '10:00', ordem: 1),
        _at('sem-hora-1', dia, Periodo.manha, ordem: 3),
        _at('8h', dia, Periodo.manha, hora: '08:00', ordem: 2),
      ]);

      expect(grupos.keys, [Periodo.manha, Periodo.tarde]);
      expect(grupos[Periodo.manha]!.map((a) => a.id),
          ['8h', '10h', 'sem-hora-1', 'sem-hora-2']);
      expect(grupos[Periodo.tarde]!.map((a) => a.id), ['tarde']);
    });

    test('período sem atendimento não aparece nos grupos', () {
      final grupos =
          agruparPorPeriodo([_at('1', DateTime(2026, 11, 11), Periodo.tarde)]);

      expect(grupos.keys, [Periodo.tarde]);
    });

    test('grade do mês alinha o dia 1 à coluna do dia da semana', () {
      // dezembro de 2026 começa numa terça-feira e tem 31 dias
      final grade = gradeDoMes(DateTime(2026, 12, 15));

      expect(grade.length % 7, 0);
      expect(grade.sublist(0, 2), [null, null]); // domingo e segunda vazios
      expect(grade[2], DateTime(2026, 12, 1));
      expect(grade.whereType<DateTime>().length, 31);
      expect(grade.whereType<DateTime>().last, DateTime(2026, 12, 31));
    });

    test('grade de um mês que começa no domingo não tem vazios antes', () {
      final grade = gradeDoMes(DateTime(2026, 11, 3)); // novembro/2026

      expect(grade.first, DateTime(2026, 11, 1));
      expect(grade.whereType<DateTime>().length, 30);
    });

    test('nomes em português', () {
      expect(nomeDiaSemana(DateTime(2026, 11, 11)), 'quarta-feira');
      expect(abreviaturaDiaSemana(DateTime(2026, 11, 8)), 'dom');
      expect(nomeMes(DateTime(2026, 12, 1)), 'dezembro');
      expect(dataPorExtenso(DateTime(2026, 11, 11)),
          'quarta-feira, 11 de novembro de 2026');
    });

    test('valorEmReais formata com virgula decimal e ponto de milhar', () {
      expect(valorEmReais(1250), 'R\$ 1.250,00');
      expect(valorEmReais(80.5), 'R\$ 80,50');
      expect(valorEmReais(0), 'R\$ 0,00');
      expect(valorEmReais(1234567.891), 'R\$ 1.234.567,89');
    });

    test('lerValor aceita virgula ou ponto e devolve nulo para vazio', () {
      expect(lerValor('180,50'), 180.5);
      expect(lerValor('180.50'), 180.5);
      expect(lerValor('180'), 180.0);
      expect(lerValor('R\$ 1.250,00'), 1250.0);
      expect(lerValor(''), isNull);
      expect(lerValor('   '), isNull);
      expect(lerValor('abc'), isNull);
    });

    test('trocar de semana seleciona o domingo, ou hoje se estiver na semana',
        () {
      final hoje = DateTime(2026, 11, 11); // quarta
      // de um sábado para a semana seguinte: domingo dela, não o outro sábado
      expect(diaAoTrocarSemana(DateTime(2026, 11, 14), 1, hoje),
          DateTime(2026, 11, 15));
      expect(diaAoTrocarSemana(DateTime(2026, 11, 11), -1, hoje),
          DateTime(2026, 11, 1));
      // voltando para a semana corrente, a seleção cai em hoje
      expect(diaAoTrocarSemana(DateTime(2026, 11, 21), -1, hoje), hoje);
      expect(diaAoTrocarSemana(DateTime(2026, 11, 1), 1, hoje), hoje);
    });
  });
}
