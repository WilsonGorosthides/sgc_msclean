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
  });
}
