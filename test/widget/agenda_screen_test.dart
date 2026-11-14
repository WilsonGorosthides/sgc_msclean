import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/screens/agenda_screen.dart';
import 'package:sgc_msclean/screens/atendimento_form_screen.dart';

import '../mocks/mock_supabase_client.dart';

// Testes de widget da AgendaScreen (RF-010). O "hoje" é injetado: quarta-feira,
// 11/11/2026 — a semana corrente vai de domingo 08/11 a sábado 14/11.
void main() {
  late MockSupabaseService service;
  final hoje = DateTime(2026, 11, 11);

  ClientModel cliente(String id, String nome) =>
      ClientModel(id: id, nome: nome, telefones: const ['11 90000-0000']);

  final clientes = [
    cliente('1', 'Ana Souza'),
    cliente('2', 'Bruno Lima'),
    cliente('3', 'Carla Dias'),
    cliente('4', 'Dani Reis'),
    cliente('5', 'Eva Costa'),
  ];

  var ordem = 0;
  Atendimento at(String id, DateTime data, Periodo periodo, String clienteId,
      {String? hora}) {
    ordem++;
    return Atendimento(
      id: id,
      data: data,
      periodo: periodo,
      hora: hora,
      clienteId: clienteId,
      criadoEm: DateTime(2026, 11, 1, 8, ordem),
    );
  }

  setUpAll(() {
    registerFallbackValue(Atendimento(
      data: DateTime(2026),
      periodo: Periodo.manha,
      clienteId: '',
    ));
  });

  setUp(() {
    service = MockSupabaseService();
    ordem = 0;
    when(() => service.getClientsStream())
        .thenAnswer((_) => Stream.value(clientes));
  });

  Future<void> bombear(WidgetTester tester, List<Atendimento> atendimentos,
      {DateTime? agora}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(() => service.getAtendimentosStream())
        .thenAnswer((_) => Stream.value(atendimentos));
    await tester.pumpWidget(MaterialApp(
      home: AgendaScreen(service: service, agora: () => agora ?? hoje),
    ));
    await tester.pump();
  }

  Future<void> tocar(WidgetTester tester, String chave) async {
    await tester.tap(find.byKey(Key(chave)));
    await tester.pump();
  }

  String dataSelecionada(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('data_selecionada'))).data!;

  String textoDe(WidgetTester tester, String chave) =>
      tester.widget<Text>(find.byKey(Key(chave))).data!;

  group('agenda_screen_test:', () {
    testWidgets('abre no dia de hoje e mostra só os atendimentos de hoje',
        (tester) async {
      await bombear(tester, [
        at('a', hoje, Periodo.manha, '1'),
        at('b', DateTime(2026, 11, 12), Periodo.manha, '2'),
      ]);

      expect(find.text('Hoje'), findsOneWidget);
      expect(dataSelecionada(tester), 'quarta-feira, 11 de novembro de 2026');
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsNothing);
    });

    testWidgets('agrupa por período e ordena por hora, sem hora depois',
        (tester) async {
      await bombear(tester, [
        // fora da ordem de exibição de propósito; sem1 é registrado antes de sem2
        at('tarde', hoje, Periodo.tarde, '5'),
        at('sem1', hoje, Periodo.manha, '3'),
        at('dez', hoje, Periodo.manha, '2', hora: '10:00'),
        at('sem2', hoje, Periodo.manha, '4'),
        at('oito', hoje, Periodo.manha, '1', hora: '08:00'),
      ]);

      double topo(String texto) => tester.getTopLeft(find.text(texto)).dy;

      expect(topo('Manhã'), lessThan(topo('Tarde')));
      expect(topo('Ana Souza'), lessThan(topo('Bruno Lima'))); // 08:00, 10:00
      expect(topo('Bruno Lima'), lessThan(topo('Carla Dias'))); // com hora
      expect(topo('Carla Dias'), lessThan(topo('Dani Reis'))); // por registro
      expect(topo('Dani Reis'), lessThan(topo('Eva Costa'))); // manhã < tarde
    });

    testWidgets('cartão exibe a hora, ou "sem hora", e o local', (tester) async {
      await bombear(tester, [
        Atendimento(
          id: 'a',
          data: hoje,
          periodo: Periodo.manha,
          hora: '09:00',
          clienteId: '1',
          local: 'Rua das Garças, 570',
        ),
        at('b', hoje, Periodo.manha, '2'),
      ]);

      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('sem hora'), findsOneWidget);
      expect(find.text('Rua das Garças, 570'), findsOneWidget);
    });

    testWidgets('cada período exibe quantos atendimentos tem', (tester) async {
      await bombear(tester, [
        at('1', hoje, Periodo.manha, '1'),
        at('2', hoje, Periodo.manha, '2'),
        at('3', hoje, Periodo.manha, '3'),
        at('4', hoje, Periodo.tarde, '4'),
      ]);

      expect(textoDe(tester, 'contagem_periodo_manha'), '3');
      expect(textoDe(tester, 'contagem_periodo_tarde'), '1');
    });

    testWidgets('navega para outro dia tocando na faixa da semana',
        (tester) async {
      await bombear(tester, [
        at('a', hoje, Periodo.manha, '1'),
        at('b', DateTime(2026, 11, 12), Periodo.manha, '2'),
      ]);

      await tocar(tester, 'dia_2026-11-12');

      expect(dataSelecionada(tester), 'quinta-feira, 12 de novembro de 2026');
      expect(find.text('Bruno Lima'), findsOneWidget);
      expect(find.text('Ana Souza'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('dia sem atendimento exibe a mensagem', (tester) async {
      await bombear(tester, [
        at('b', DateTime(2026, 11, 12), Periodo.manha, '2'),
      ]);

      expect(find.text('Nenhum atendimento neste dia.'), findsOneWidget);
      expect(find.byKey(const Key('periodo_manha')), findsNothing);
      expect(find.byKey(const Key('periodo_tarde')), findsNothing);
    });

    testWidgets('dias com atendimento têm marca; os vazios não',
        (tester) async {
      await bombear(tester, [
        at('a', DateTime(2026, 11, 9), Periodo.manha, '1'),
        at('b', DateTime(2026, 11, 13), Periodo.tarde, '2'),
      ]);

      expect(find.byKey(const Key('contagem_2026-11-09')), findsOneWidget);
      expect(find.byKey(const Key('contagem_2026-11-13')), findsOneWidget);
      expect(find.byKey(const Key('contagem_2026-11-10')), findsNothing);
      expect(find.byKey(const Key('contagem_2026-11-11')), findsNothing);
    });

    testWidgets('faixa mostra domingo a sábado com a quantidade por dia',
        (tester) async {
      await bombear(tester, [
        at('a', DateTime(2026, 11, 9), Periodo.manha, '1'),
        at('b', DateTime(2026, 11, 9), Periodo.tarde, '2'),
        at('c', DateTime(2026, 11, 17), Periodo.manha, '3'),
      ]);

      for (var dia = 8; dia <= 14; dia++) {
        expect(find.byKey(Key('dia_2026-11-${dia.toString().padLeft(2, '0')}')),
            findsOneWidget);
      }
      expect(find.byKey(const Key('dia_2026-11-07')), findsNothing);
      expect(find.byKey(const Key('dia_2026-11-15')), findsNothing);
      expect(textoDe(tester, 'contagem_2026-11-09'), '2');
    });

    testWidgets('avança e retrocede a semana', (tester) async {
      await bombear(tester, [
        at('a', DateTime(2026, 11, 9), Periodo.manha, '1'),
        at('c', DateTime(2026, 11, 17), Periodo.manha, '3'),
      ]);

      await tocar(tester, 'semana_proxima');

      expect(find.byKey(const Key('dia_2026-11-15')), findsOneWidget);
      expect(find.byKey(const Key('dia_2026-11-21')), findsOneWidget);
      expect(find.byKey(const Key('dia_2026-11-14')), findsNothing);
      expect(textoDe(tester, 'contagem_2026-11-17'), '1');
      // a seleção vai para o domingo da semana de destino (issue #87)
      expect(dataSelecionada(tester), 'domingo, 15 de novembro de 2026');

      await tocar(tester, 'semana_anterior');
      // de volta à semana corrente, a seleção cai em hoje
      expect(dataSelecionada(tester), 'quarta-feira, 11 de novembro de 2026');
      await tocar(tester, 'semana_anterior');
      expect(dataSelecionada(tester), 'domingo, 1 de novembro de 2026');

      expect(find.byKey(const Key('dia_2026-11-01')), findsOneWidget);
      expect(find.byKey(const Key('dia_2026-11-07')), findsOneWidget);
      expect(find.byKey(const Key('dia_2026-11-08')), findsNothing);
    });

    testWidgets('abre o mês com um toque e navega entre meses', (tester) async {
      await bombear(tester, [
        at('a', DateTime(2026, 11, 9), Periodo.manha, '1'),
        at('b', DateTime(2026, 11, 9), Periodo.tarde, '2'),
        at('c', DateTime(2026, 12, 3), Periodo.manha, '3'),
      ]);

      await tocar(tester, 'abrir_mes');

      expect(textoDe(tester, 'titulo_mes'), 'novembro de 2026');
      expect(textoDe(tester, 'mes_contagem_2026-11-09'), '2');
      expect(find.byKey(const Key('mes_contagem_2026-11-10')), findsNothing);
      expect(find.byKey(const Key('mes_dia_2026-11-30')), findsOneWidget);

      await tocar(tester, 'mes_proximo');
      expect(textoDe(tester, 'titulo_mes'), 'dezembro de 2026');
      expect(textoDe(tester, 'mes_contagem_2026-12-03'), '1');

      await tocar(tester, 'mes_anterior');
      await tocar(tester, 'mes_anterior');
      expect(textoDe(tester, 'titulo_mes'), 'outubro de 2026');
    });

    testWidgets('tocar num dia do mês seleciona e volta à visão do dia',
        (tester) async {
      await bombear(tester, [
        at('d', DateTime(2026, 11, 24), Periodo.tarde, '4'),
      ]);

      await tocar(tester, 'abrir_mes');
      await tocar(tester, 'mes_dia_2026-11-24');

      expect(find.byKey(const Key('titulo_mes')), findsNothing);
      expect(dataSelecionada(tester), 'terça-feira, 24 de novembro de 2026');
      expect(find.text('Dani Reis'), findsOneWidget);
      expect(find.byKey(const Key('dia_2026-11-22')), findsOneWidget);
      expect(find.byKey(const Key('dia_2026-11-28')), findsOneWidget);
    });

    testWidgets('hoje tem marca própria na semana e no mês', (tester) async {
      await bombear(tester, []);

      expect(find.byKey(const Key('marca_hoje')), findsOneWidget);

      await tocar(tester, 'abrir_mes');

      expect(find.byKey(const Key('mes_marca_hoje')), findsOneWidget);
    });

    testWidgets('atalho volta a hoje a partir de outro mês', (tester) async {
      await bombear(tester, []);
      expect(find.byKey(const Key('voltar_hoje')), findsNothing);

      await tocar(tester, 'abrir_mes');
      await tocar(tester, 'mes_proximo');
      await tocar(tester, 'mes_dia_2026-12-15');

      expect(dataSelecionada(tester), 'terça-feira, 15 de dezembro de 2026');
      expect(find.byKey(const Key('marca_hoje')), findsNothing);
      expect(find.byKey(const Key('voltar_hoje')), findsOneWidget);

      await tocar(tester, 'voltar_hoje');

      expect(dataSelecionada(tester), 'quarta-feira, 11 de novembro de 2026');
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.byKey(const Key('voltar_hoje')), findsNothing);
    });

    testWidgets('lista de clientes abre pela agenda e volta ao mesmo dia',
        (tester) async {
      await bombear(tester, []);
      await tocar(tester, 'dia_2026-11-13');

      await tocar(tester, 'abrir_clientes');
      await tester.pump();
      await tester.pump();

      expect(find.text('MSClean - Clientes'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('MSClean - Clientes'), findsNothing);
      expect(dataSelecionada(tester), 'sexta-feira, 13 de novembro de 2026');
    });

    testWidgets(
        'novo atendimento parte do dia selecionado e, salvo, consta no período',
        (tester) async {
      await bombear(tester, []);
      await tocar(tester, 'dia_2026-11-13');

      await tocar(tester, 'novo_atendimento');
      await tester.pumpAndSettle();

      // CT-040: a data vem do dia selecionado, sem campo para digitá-la
      expect(find.byType(AtendimentoFormScreen), findsOneWidget);
      expect(textoDe(tester, 'data_atendimento'),
          'sexta-feira, 13 de novembro de 2026');
      expect(find.byKey(const Key('campo_data')), findsNothing);

      final salvo = Atendimento(
        id: 'novo',
        data: DateTime(2026, 11, 13),
        periodo: Periodo.tarde,
        clienteId: '4',
      );
      when(() => service.addAtendimento(any())).thenAnswer((_) async {});
      // a agenda renova a stream ao voltar do formulário (issue #57)
      when(() => service.getAtendimentosStream())
          .thenAnswer((_) => Stream.value([salvo]));

      await tocar(tester, 'escolher_cliente_4');
      await tocar(tester, 'escolher_tarde');
      await tocar(tester, 'botao_salvar');
      await tester.pumpAndSettle();

      final gravado =
          verify(() => service.addAtendimento(captureAny())).captured.single
              as Atendimento;
      expect(gravado.data, DateTime(2026, 11, 13));
      expect(gravado.periodo, Periodo.tarde);
      expect(gravado.clienteId, '4');

      // CT-048: de volta à agenda, no mesmo dia, o cartão está na Tarde
      expect(find.byType(AtendimentoFormScreen), findsNothing);
      expect(dataSelecionada(tester), 'sexta-feira, 13 de novembro de 2026');
      expect(find.byKey(const Key('periodo_tarde')), findsOneWidget);
      expect(find.text('Dani Reis'), findsOneWidget);
    });

    testWidgets('tocar no cartão abre a edição e a hora alterada é atualizada',
        (tester) async {
      await bombear(tester, [
        at('a', hoje, Periodo.manha, '1', hora: '09:00'),
      ]);

      await tocar(tester, 'atendimento_a');
      await tester.pumpAndSettle();

      expect(find.text('Editar atendimento'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      final campoHora =
          tester.widget<TextFormField>(find.byKey(const Key('campo_hora')));
      expect(campoHora.controller!.text, '09:00');

      when(() => service.updateAtendimento(any())).thenAnswer((_) async {});
      await tester.enterText(find.byKey(const Key('campo_hora')), '10:30');
      await tocar(tester, 'botao_salvar');
      await tester.pumpAndSettle();

      final gravado =
          verify(() => service.updateAtendimento(captureAny())).captured.single
              as Atendimento;
      expect(gravado.id, 'a');
      expect(gravado.hora, '10:30');
      expect(gravado.clienteId, '1');
      verifyNever(() => service.addAtendimento(any()));
    });
  });
}
