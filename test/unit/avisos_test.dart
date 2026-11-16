import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/utils/avisos.dart';

// Testes da regra dos avisos no celular (RF-015, issue #95): a função pura
// planejarAvisos, com o "agora" injetado. Roteiros CT-060 a CT-064 em
// docs/casos-de-teste.md. Agora: segunda-feira, 16/11/2026, 10h.
void main() {
  final agora = DateTime(2026, 11, 16, 10);
  final amanha = DateTime(2026, 11, 17);

  final clientes = [
    ClientModel(id: '1', nome: 'Ana Souza', telefones: const ['1']),
    ClientModel(id: '2', nome: 'Bruno Lima', telefones: const ['2']),
    ClientModel(id: '3', nome: 'Carla Dias', telefones: const ['3']),
  ];

  var ordem = 0;
  Atendimento at(DateTime data, Periodo periodo, String clienteId,
      {String? hora,
      String local = '',
      double? valor,
      bool feito = false,
      bool pago = false}) {
    ordem++;
    return Atendimento(
      id: 'a$ordem',
      data: data,
      periodo: periodo,
      hora: hora,
      clienteId: clienteId,
      local: local,
      valor: valor,
      feito: feito,
      pago: pago,
      criadoEm: DateTime(2026, 11, 1, 8, ordem),
    );
  }

  List<Aviso> planejar(List<Atendimento> lista, {DateTime? em}) =>
      planejarAvisos(lista, clientes, em ?? agora);

  Iterable<Aviso> doTipo(List<Aviso> avisos, TipoAviso tipo) =>
      avisos.where((a) => a.tipo == tipo);

  setUp(() => ordem = 0);

  group('avisos_test:', () {
    test('resumo da véspera às 19h com os períodos e os nomes', () {
      final avisos = planejar([
        at(amanha, Periodo.tarde, '3'),
        at(amanha, Periodo.manha, '1'),
        at(amanha, Periodo.manha, '2'),
      ]);

      final vespera = doTipo(avisos, TipoAviso.vespera).single;
      expect(vespera.quando, DateTime(2026, 11, 16, 19));
      expect(vespera.dia, amanha);
      expect(vespera.titulo, 'Amanhã: 3 atendimentos');
      // na ordem da agenda: manhã (na ordem do registro), depois tarde
      expect(vespera.corpo,
          '2 de manhã, 1 à tarde — Ana Souza, Bruno Lima, Carla Dias');
    });

    test('um atendimento só usa o singular e omite o período vazio', () {
      final avisos = planejar([at(amanha, Periodo.tarde, '2')]);

      final vespera = doTipo(avisos, TipoAviso.vespera).single;
      expect(vespera.titulo, 'Amanhã: 1 atendimento');
      expect(vespera.corpo, '1 à tarde — Bruno Lima');
    });

    test('resumo do dia às 7h', () {
      final avisos = planejar([
        at(amanha, Periodo.manha, '1'),
        at(amanha, Periodo.tarde, '2'),
      ]);

      final dia = doTipo(avisos, TipoAviso.dia).single;
      expect(dia.quando, DateTime(2026, 11, 17, 7));
      expect(dia.dia, amanha);
      expect(dia.titulo, 'Hoje: 2 atendimentos');
      expect(dia.corpo, '1 de manhã, 1 à tarde — Ana Souza, Bruno Lima');
    });

    test('aviso 1 hora antes só para atendimento com hora', () {
      final avisos = planejar([
        at(amanha, Periodo.tarde, '1',
            hora: '14:00', local: 'Rua das Flores, 10'),
        at(amanha, Periodo.manha, '2'),
      ]);

      final hora = doTipo(avisos, TipoAviso.hora).single;
      expect(hora.quando, DateTime(2026, 11, 17, 13));
      expect(hora.dia, amanha);
      expect(hora.titulo, 'Em 1 hora: Ana Souza');
      expect(hora.corpo, '14:00 · Rua das Flores, 10');
    });

    test('lembrete de cobrança só para feito e não pago, no terceiro dia às 10h',
        () {
      final dia14 = DateTime(2026, 11, 14);
      final avisos = planejar([
        at(dia14, Periodo.manha, '1', feito: true, valor: 250),
        at(dia14, Periodo.manha, '2', feito: true, pago: true),
        at(dia14, Periodo.tarde, '3'),
      ], em: DateTime(2026, 11, 16, 8));

      final cobranca = doTipo(avisos, TipoAviso.cobranca).single;
      expect(cobranca.quando, DateTime(2026, 11, 17, 10));
      expect(cobranca.dia, dia14);
      expect(cobranca.titulo, 'Cobrar: Ana Souza');
      expect(cobranca.corpo,
          'Serviço de 14/11 feito e ainda não pago · R\$ 250,00');
    });

    test('avisos com horário que já passou não entram', () {
      // segunda às 20h: a véspera de terça (19h) já passou
      final avisos = planejar([
        at(amanha, Periodo.manha, '1', hora: '08:00'),
        at(DateTime(2026, 11, 16), Periodo.tarde, '2', hora: '15:00'),
      ], em: DateTime(2026, 11, 16, 20));

      final quando = DateTime(2026, 11, 16, 20);
      expect(avisos, isNotEmpty);
      expect(avisos.every((a) => a.quando.isAfter(quando)), isTrue);
      expect(doTipo(avisos, TipoAviso.vespera), isEmpty);
      expect(doTipo(avisos, TipoAviso.dia).single.dia, amanha);
      expect(doTipo(avisos, TipoAviso.hora).single.quando,
          DateTime(2026, 11, 17, 7));
      // em ordem de horário, com ids distintos
      final ids = avisos.map((a) => a.id).toSet();
      expect(ids.length, avisos.length);
      for (var i = 1; i < avisos.length; i++) {
        expect(avisos[i].quando.isBefore(avisos[i - 1].quando), isFalse);
      }
    });
  });
}
