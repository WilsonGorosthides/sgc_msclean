import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/models/endereco.dart';
import 'package:sgc_msclean/screens/client_form_screen.dart';
import 'package:sgc_msclean/screens/home_screen.dart';

import '../mocks/mock_supabase_client.dart';

// Testes de widget da HomeScreen (RF-003 e RF-004), com MockSupabaseService
// injetado — os nomes dos casos seguem docs/matriz-rastreabilidade.md.
// Endereço passa a ser estruturado (#65): a lista exibe o resumo.
void main() {
  late MockSupabaseService service;

  final ana = ClientModel(
      id: '1',
      nome: 'Ana Souza',
      endereco: const Endereco(logradouro: 'Rua das Flores', numero: '10'),
      telefones: ['11 91111-1111']);
  final bruno = ClientModel(
      id: '2',
      nome: 'Bruno Lima',
      endereco: const Endereco(logradouro: 'Avenida Central', numero: '200'),
      telefones: ['11 92222-2222']);
  final carla = ClientModel(
      id: '3',
      nome: 'Carla Dias',
      endereco: const Endereco(logradouro: 'Rua das Flores', numero: '30'),
      telefones: ['11 93333-3333']);

  setUpAll(() {
    registerFallbackValue(ClientModel(nome: '', telefones: const []));
  });

  setUp(() {
    service = MockSupabaseService();
  });

  // Viewport mais alto: os testes que abrem o formulário (endereço
  // estruturado, #65) precisam do botão de salvar montado dentro da ListView.
  void ajustarViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> bombearTela(WidgetTester tester) async {
    ajustarViewport(tester);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(service: service)));
    await tester.pump(); // processa a primeira emissão da stream
  }

  group('home_screen_test:', () {
    testWidgets('lista populada em ordem alfabética', (tester) async {
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana, bruno, carla]));

      await bombearTela(tester);

      final dyAna = tester.getTopLeft(find.text('Ana Souza')).dy;
      final dyBruno = tester.getTopLeft(find.text('Bruno Lima')).dy;
      final dyCarla = tester.getTopLeft(find.text('Carla Dias')).dy;
      expect(dyAna, lessThan(dyBruno));
      expect(dyBruno, lessThan(dyCarla));
    });

    testWidgets('item exibe nome e endereço', (tester) async {
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana]));

      await bombearTela(tester);

      expect(find.text('Ana Souza'), findsOneWidget);
      // o item mostra o resumo do endereço estruturado
      expect(find.text('Rua das Flores, 10'), findsOneWidget);
    });

    testWidgets('item sem endereço exibe placeholder', (tester) async {
      // #61: endereço é opcional; o item mostra um texto discreto no lugar
      final semEndereco = ClientModel(
          id: '9',
          nome: 'Zé Sem Rua',
          endereco: const Endereco(),
          telefones: ['11 90000-0000']);
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([semEndereco]));

      await bombearTela(tester);

      expect(find.text('Zé Sem Rua'), findsOneWidget);
      expect(find.text('Sem endereço'), findsOneWidget);
    });

    testWidgets('lista reage à emissão da stream', (tester) async {
      // sync: true entrega cada emissão no próprio add(), tornando o teste
      // determinístico (sem corrida entre microtask e frame do pump).
      final controller = StreamController<List<ClientModel>>(sync: true);
      addTearDown(controller.close);
      when(() => service.getClientsStream())
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
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([]));

      await bombearTela(tester);

      expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
    });

    testWidgets('filtragem ao digitar na busca', (tester) async {
      // a stream é única; o filtro acontece no widget sobre a lista emitida
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana, bruno]));

      await bombearTela(tester);
      expect(find.text('Bruno Lima'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pump(); // rebuild com o filtro novo

      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsNothing);

      // ao limpar o campo, a lista volta ao completo
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('Bruno Lima'), findsOneWidget);
    });

    testWidgets('busca sem correspondência exibe mensagem', (tester) async {
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana, bruno]));

      await bombearTela(tester);

      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pump();

      expect(find.text('Nenhum cliente encontrado.'), findsOneWidget);
    });

    testWidgets('cliente salvo aparece na lista via stream', (tester) async {
      // CT-004: FAB abre o formulário; salvar grava via service; ao
      // retornar, a Home renova a stream e o cliente novo aparece na
      // lista — sem recarga manual do usuário.
      final debora = ClientModel(
          id: '4',
          nome: 'Débora Prado',
          endereco:
              const Endereco(logradouro: 'Rua das Acácias', numero: '45'),
          telefones: ['11 94444-4444']);
      final respostas = [
        Stream.value([ana]),
        Stream.value([ana, debora]),
      ];
      when(() => service.getClientsStream())
          .thenAnswer((_) => respostas.removeAt(0));
      when(() => service.addClient(any())).thenAnswer((_) async {});

      await bombearTela(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(ClientFormScreen), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('campo_nome')), 'Débora Prado');
      await tester.enterText(
          find.byKey(const Key('campo_logradouro')), 'Rua das Acácias');
      await tester.enterText(find.byKey(const Key('campo_numero')), '45');
      await tester.enterText(
          find.byKey(const Key('campo_telefone_0')), '11 94444-4444');
      await tester.tap(find.byKey(const Key('botao_salvar')));
      await tester.pumpAndSettle();

      // voltou pra lista e o service recebeu os dados digitados
      expect(find.byType(ClientFormScreen), findsNothing);
      final salvo = verify(() => service.addClient(captureAny()))
          .captured
          .single as ClientModel;
      expect(salvo.nome, 'Débora Prado');

      // a Home renovou a stream no retorno e o cliente novo está na lista
      expect(find.text('Débora Prado'), findsOneWidget);
    });

    testWidgets('editar abre formulário pré-preenchido', (tester) async {
      // CT-006: tocar no item da lista abre a edição com os dados atuais
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana]));

      await bombearTela(tester);

      await tester.tap(find.text('Ana Souza'));
      await tester.pumpAndSettle();

      expect(find.byType(ClientFormScreen), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      // os campos estruturados vêm pré-preenchidos
      expect(find.text('Rua das Flores'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('11 91111-1111'), findsOneWidget);
    });

    testWidgets('edição confirmada persiste e reflete na lista ao voltar',
        (tester) async {
      // CT-008 (critério renegociado, requisitos.md 2.4 / issue #57): nada
      // é gravado antes do salvar; na confirmação o service recebe os novos
      // dados (com o id) e, ao retornar do formulário, a Home renova a
      // stream — a lista exibe a alteração sem recarga manual do usuário.
      final anaEditada = ClientModel(
          id: '1',
          nome: 'Ana Souza',
          endereco: const Endereco(logradouro: 'Rua Nova', numero: '99'),
          telefones: ['11 91111-1111']);
      final respostas = [
        Stream.value([ana]),
        Stream.value([anaEditada]),
      ];
      when(() => service.getClientsStream())
          .thenAnswer((_) => respostas.removeAt(0));
      when(() => service.updateClient(any())).thenAnswer((_) async {});

      await bombearTela(tester);

      await tester.tap(find.text('Ana Souza'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('campo_logradouro')), 'Rua Nova');
      await tester.enterText(find.byKey(const Key('campo_numero')), '99');
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
      expect(salvo.endereco.logradouro, 'Rua Nova');
      expect(salvo.endereco.numero, '99');

      // a Home renovou a stream no retorno e a lista mostra a alteração
      verify(() => service.getClientsStream()).called(2);
      expect(find.text('Rua Nova, 99'), findsOneWidget);
    });

    testWidgets('busca não recria a assinatura da stream', (tester) async {
      // Defeito real observado no CT-008 (RF-002): cada rebuild da Home
      // criava uma assinatura realtime nova no Supabase (uma por tecla na
      // busca), e o churn de canais derruba a entrega de eventos UPDATE.
      // A tela deve assinar a stream UMA vez, por toda a sua vida.
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana, bruno]));

      await bombearTela(tester);

      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.pump();
      await tester.pump();

      verify(() => service.getClientsStream()).called(1);
    });

    testWidgets('busca vazia exibe todos', (tester) async {
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana, bruno, carla]));

      await bombearTela(tester);

      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsOneWidget);
      expect(find.text('Carla Dias'), findsOneWidget);
    });

    testWidgets('exclusão pede confirmação antes de remover', (tester) async {
      // CT-019: tocar na lixeira abre o diálogo; nada é removido antes da
      // resposta do usuário.
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana, bruno]));

      await bombearTela(tester);

      await tester.tap(find.byKey(const Key('excluir_1')));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar exclusão?'), findsOneWidget);
      verifyNever(() => service.deleteClient(any()));
    });

    testWidgets('cancelar a confirmação não remove', (tester) async {
      // CT-020: cancelar o diálogo não chama exclusão e mantém o cliente.
      when(() => service.getClientsStream())
          .thenAnswer((_) => Stream.value([ana, bruno]));

      await bombearTela(tester);

      await tester.tap(find.byKey(const Key('excluir_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => service.deleteClient(any()));
      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('confirmar remove e a lista reflete ao renovar a stream',
        (tester) async {
      // CT-021 (critério renegociado, requisitos.md 2.5): confirmar chama
      // deleteClient com o cliente certo; a Home renova a stream e o item
      // some da lista, sem depender do evento DELETE do realtime (issue #57).
      final respostas = [
        Stream.value([ana, bruno]),
        Stream.value([bruno]),
      ];
      when(() => service.getClientsStream())
          .thenAnswer((_) => respostas.removeAt(0));
      when(() => service.deleteClient(any())).thenAnswer((_) async {});

      await bombearTela(tester);

      await tester.tap(find.byKey(const Key('excluir_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      final excluido = verify(() => service.deleteClient(captureAny()))
          .captured
          .single as ClientModel;
      expect(excluido.id, '1');
      verify(() => service.getClientsStream()).called(2);
      expect(find.text('Ana Souza'), findsNothing);
      expect(find.text('Bruno Lima'), findsOneWidget);
    });

    testWidgets('exclusão bem-sucedida exibe feedback', (tester) async {
      // CT-022: SnackBar "Cliente excluído" após a exclusão confirmada.
      final respostas = [
        Stream.value([ana]),
        Stream.value(<ClientModel>[]),
      ];
      when(() => service.getClientsStream())
          .thenAnswer((_) => respostas.removeAt(0));
      when(() => service.deleteClient(any())).thenAnswer((_) async {});

      await bombearTela(tester);

      await tester.tap(find.byKey(const Key('excluir_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Cliente excluído'), findsOneWidget);
    });
  });
}
