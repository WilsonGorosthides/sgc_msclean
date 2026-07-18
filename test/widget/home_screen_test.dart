import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/screens/client_form_screen.dart';
import 'package:sgc_msclean/screens/home_screen.dart';

import '../mocks/mock_supabase_client.dart';

// Testes de widget da HomeScreen (RF-003 e RF-004), com MockSupabaseService
// injetado — os nomes dos casos seguem docs/matriz-rastreabilidade.md.
void main() {
  late MockSupabaseService service;

  final ana = ClientModel(
      id: '1',
      nome: 'Ana Souza',
      endereco: 'Rua das Flores, 10',
      telefone: '11 91111-1111');
  final bruno = ClientModel(
      id: '2',
      nome: 'Bruno Lima',
      endereco: 'Avenida Central, 200',
      telefone: '11 92222-2222');
  final carla = ClientModel(
      id: '3',
      nome: 'Carla Dias',
      endereco: 'Rua das Flores, 30',
      telefone: '11 93333-3333');

  setUpAll(() {
    registerFallbackValue(ClientModel(nome: '', endereco: '', telefone: ''));
  });

  setUp(() {
    service = MockSupabaseService();
  });

  Future<void> bombearTela(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen(service: service)));
    await tester.pump(); // processa a primeira emissão da stream
  }

  group('home_screen_test:', () {
    testWidgets('lista populada em ordem alfabética', (tester) async {
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => Stream.value([ana, bruno, carla]));

      await bombearTela(tester);

      final dyAna = tester.getTopLeft(find.text('Ana Souza')).dy;
      final dyBruno = tester.getTopLeft(find.text('Bruno Lima')).dy;
      final dyCarla = tester.getTopLeft(find.text('Carla Dias')).dy;
      expect(dyAna, lessThan(dyBruno));
      expect(dyBruno, lessThan(dyCarla));
    });

    testWidgets('item exibe nome e endereço', (tester) async {
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => Stream.value([ana]));

      await bombearTela(tester);

      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Rua das Flores, 10'), findsOneWidget);
    });

    testWidgets('lista reage à emissão da stream', (tester) async {
      // sync: true entrega cada emissão no próprio add(), tornando o teste
      // determinístico (sem corrida entre microtask e frame do pump).
      final controller = StreamController<List<ClientModel>>(sync: true);
      addTearDown(controller.close);
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => controller.stream);

      await bombearTela(tester);

      controller.add([ana]);
      await tester.pump();
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsNothing);

      // inserção chega pela stream e a lista atualiza sem ação manual
      controller.add([ana, bruno]);
      await tester.pump();
      expect(find.text('Bruno Lima'), findsOneWidget);

      // exclusão chega pela stream e o item some da lista
      controller.add([bruno]);
      await tester.pump();
      expect(find.text('Ana Souza'), findsNothing);
    });

    testWidgets('estado vazio exibe mensagem', (tester) async {
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => Stream.value([]));

      await bombearTela(tester);

      expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
    });

    testWidgets('filtragem ao digitar na busca', (tester) async {
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => Stream.value([ana, bruno]));
      when(() => service.getClientsStream('Ana'))
          .thenAnswer((_) => Stream.value([ana]));

      await bombearTela(tester);
      expect(find.text('Bruno Lima'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pump(); // rebuild com a nova stream
      await tester.pump(); // primeira emissão da nova stream

      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsNothing);

      // ao limpar o campo, a lista volta ao completo
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.pump();

      expect(find.text('Bruno Lima'), findsOneWidget);
    });

    testWidgets('busca sem correspondência exibe mensagem', (tester) async {
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => Stream.value([ana, bruno]));
      when(() => service.getClientsStream('inexistente'))
          .thenAnswer((_) => Stream.value([]));

      await bombearTela(tester);

      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pump();
      await tester.pump();

      expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
    });

    testWidgets('cliente salvo aparece na lista via stream', (tester) async {
      // CT-004: FAB abre o formulário; salvar grava via service; a lista
      // reflete o cliente novo quando a stream emite — sem recarga manual.
      final controller = StreamController<List<ClientModel>>(sync: true);
      addTearDown(controller.close);
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => controller.stream);
      when(() => service.addClient(any())).thenAnswer((_) async {});

      await bombearTela(tester);
      controller.add([ana]);
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(ClientFormScreen), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('campo_nome')), 'Débora Prado');
      await tester.enterText(
          find.byKey(const Key('campo_endereco')), 'Rua das Acácias, 45');
      await tester.enterText(
          find.byKey(const Key('campo_telefone')), '11 94444-4444');
      await tester.tap(find.byKey(const Key('botao_salvar')));
      await tester.pumpAndSettle();

      // voltou pra lista e o service recebeu os dados digitados
      expect(find.byType(ClientFormScreen), findsNothing);
      final salvo = verify(() => service.addClient(captureAny()))
          .captured
          .single as ClientModel;
      expect(salvo.nome, 'Débora Prado');

      // a stream emite a lista com o cliente novo e ele aparece sem recarga
      final debora = ClientModel(
          id: '4',
          nome: 'Débora Prado',
          endereco: 'Rua das Acácias, 45',
          telefone: '11 94444-4444');
      controller.add([ana, debora]);
      await tester.pump();
      expect(find.text('Débora Prado'), findsOneWidget);
    });

    testWidgets('editar abre formulário pré-preenchido', (tester) async {
      // CT-006: tocar no item da lista abre a edição com os dados atuais
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => Stream.value([ana]));

      await bombearTela(tester);

      await tester.tap(find.text('Ana Souza'));
      await tester.pumpAndSettle();

      expect(find.byType(ClientFormScreen), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Rua das Flores, 10'), findsOneWidget);
      expect(find.text('11 91111-1111'), findsOneWidget);
    });

    testWidgets('edição confirmada persiste e reflete na lista via stream',
        (tester) async {
      // CT-008: nada é gravado antes do salvar; na confirmação o service
      // recebe os novos dados (com o id) e a lista reflete via stream.
      final controller = StreamController<List<ClientModel>>(sync: true);
      addTearDown(controller.close);
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => controller.stream);
      when(() => service.updateClient(any())).thenAnswer((_) async {});

      await bombearTela(tester);
      controller.add([ana]);
      await tester.pump();

      await tester.tap(find.text('Ana Souza'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('campo_endereco')), 'Rua Nova, 99');
      verifyNever(() => service.updateClient(any()));

      await tester.tap(find.byKey(const Key('botao_salvar')));
      await tester.pumpAndSettle();

      // voltou pra lista e o update recebeu os novos dados do cliente certo
      expect(find.byType(ClientFormScreen), findsNothing);
      final salvo = verify(() => service.updateClient(captureAny()))
          .captured
          .single as ClientModel;
      expect(salvo.id, '1');
      expect(salvo.nome, 'Ana Souza');
      expect(salvo.endereco, 'Rua Nova, 99');

      // a stream emite a lista atualizada e a mudança aparece sem recarga
      final anaEditada = ClientModel(
          id: '1',
          nome: 'Ana Souza',
          endereco: 'Rua Nova, 99',
          telefone: '11 91111-1111');
      controller.add([anaEditada]);
      await tester.pump();
      expect(find.text('Rua Nova, 99'), findsOneWidget);
    });

    testWidgets('busca vazia exibe todos', (tester) async {
      when(() => service.getClientsStream(''))
          .thenAnswer((_) => Stream.value([ana, bruno, carla]));

      await bombearTela(tester);

      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsOneWidget);
      expect(find.text('Carla Dias'), findsOneWidget);
    });
  });
}
