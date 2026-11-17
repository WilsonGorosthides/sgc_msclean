import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/models/endereco.dart';
import 'package:sgc_msclean/models/peca.dart';
import 'package:sgc_msclean/screens/client_form_screen.dart';
import 'package:sgc_msclean/services/contatos.dart';

import '../mocks/agenda_falsa.dart';
import '../mocks/mock_supabase_client.dart';

// Testes de widget do formulário de cadastro e edição (RF-001/RF-002), com
// MockSupabaseService injetado — roteiros em docs/casos-de-teste.md
// (CT-001, CT-002, CT-003, CT-005, CT-007, CT-009 e o caso extra de
// robustez do erro). Endereço passa a ser estruturado (#65).
void main() {
  late MockSupabaseService service;

  final cliente = ClientModel(
      id: '7',
      nome: 'Ana Souza',
      endereco: const Endereco(logradouro: 'Rua das Flores', numero: '10'),
      telefones: ['11 91111-1111']);

  setUpAll(() {
    registerFallbackValue(ClientModel(nome: '', telefones: const []));
  });

  setUp(() {
    service = MockSupabaseService();
    // A edição mostra o histórico do cliente (RF-011): sem atendimentos.
    when(() => service.getAtendimentosStream())
        .thenAnswer((_) => Stream.value(const <Atendimento>[]));
  });

  final campoNome = find.byKey(const Key('campo_nome'));
  final campoLogradouro = find.byKey(const Key('campo_logradouro'));
  final campoNumero = find.byKey(const Key('campo_numero'));
  final campoTelefone = find.byKey(const Key('campo_telefone_0'));
  final botaoSalvar = find.byKey(const Key('botao_salvar'));

  // Com o endereço estruturado (#65), o formulário ficou mais alto que o
  // viewport padrão de teste (800x600) e o botão de salvar caía fora da
  // ListView; um viewport mais alto mantém tudo montado (em tela real, rola).
  void ajustarViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> bombearFormulario(WidgetTester tester) async {
    ajustarViewport(tester);
    await tester
        .pumpWidget(MaterialApp(home: ClientFormScreen(service: service)));
  }

  Future<void> preencherValido(WidgetTester tester) async {
    await tester.enterText(campoNome, 'Débora Prado');
    await tester.enterText(campoLogradouro, 'Rua das Acácias');
    await tester.enterText(campoNumero, '45');
    await tester.enterText(campoTelefone, '11 94444-4444');
  }

  // RF-016 (#115): trazer nome e telefone dos contatos do celular.
  final ivete = ClientModel(
      id: '9', nome: 'Ivete Souza', telefones: const ['67 99301-8496']);

  Future<AgendaFalsa> bombearComContatos(WidgetTester tester, Contato? contato,
      {ClientModel? cliente, List<ClientModel> clientes = const []}) async {
    ajustarViewport(tester);
    final agenda = AgendaFalsa(contato);
    await tester.pumpWidget(MaterialApp(
        key: UniqueKey(),
        home: ClientFormScreen(
            service: service,
            cliente: cliente,
            clientes: clientes,
            contatos: agenda)));
    return agenda;
  }

  group('client_form_screen_test: contatos:', () {
    testWidgets('contato escolhido preenche nome e telefone', (tester) async {
      await bombearComContatos(
          tester, const Contato(nome: 'Dona Ivete', telefone: '(67) 99301-8496'));
      await tester.tap(find.byKey(const Key('dos_contatos')));
      await tester.pumpAndSettle();
      expect(
          tester.widget<TextFormField>(campoNome).controller!.text, 'Dona Ivete');
      expect(tester.widget<TextFormField>(campoTelefone).controller!.text,
          '+55 67 99301-8496');
    });

    testWidgets('sem contato escolhido nada muda; na edição não há o botão',
        (tester) async {
      final agenda = await bombearComContatos(tester, null);
      await tester.tap(find.byKey(const Key('dos_contatos')));
      await tester.pumpAndSettle();
      expect(agenda.aberturas, 1);
      expect(tester.widget<TextFormField>(campoNome).controller!.text, '');

      await bombearComContatos(tester, null, cliente: cliente);
      expect(find.byKey(const Key('dos_contatos')), findsNothing);
    });

    testWidgets('contato já cadastrado avisa e abre o cadastro existente',
        (tester) async {
      await bombearComContatos(
          tester, const Contato(nome: 'Ivete', telefone: '+55 67 99301-8496'),
          clientes: [cliente, ivete]);
      await tester.tap(find.byKey(const Key('dos_contatos')));
      await tester.pumpAndSettle();
      expect(find.text('Já cadastrado como Ivete Souza'), findsOneWidget);

      await tester.tap(find.byKey(const Key('abrir_existente')));
      await tester.pumpAndSettle();
      expect(find.text('Editar Cliente'), findsOneWidget);
      expect(tester.widget<TextFormField>(campoNome).controller!.text,
          'Ivete Souza');
    });

    testWidgets('contato já cadastrado pode ser cadastrado mesmo assim',
        (tester) async {
      await bombearComContatos(
          tester, const Contato(nome: 'Ivete', telefone: '+55 67 99301-8496'),
          clientes: [ivete]);
      await tester.tap(find.byKey(const Key('dos_contatos')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cadastrar_mesmo_assim')));
      await tester.pumpAndSettle();
      expect(find.text('Novo Cliente'), findsOneWidget);
      expect(tester.widget<TextFormField>(campoNome).controller!.text, 'Ivete');
    });
  });

  group('client_form_screen_test:', () {
    testWidgets('exige nome e telefone; endereço é opcional', (tester) async {
      // CT-001: nome e telefone continuam obrigatórios; endereço, não (#61)
      await bombearFormulario(tester);

      await tester.tap(botaoSalvar);
      await tester.pump();

      expect(find.text('Informe o nome'), findsOneWidget);
      expect(find.text('Informe o telefone'), findsOneWidget);
      expect(find.text('Informe o endereço'), findsNothing);
      verifyNever(() => service.addClient(any()));
    });

    testWidgets('salvar sem endereço pede confirmação e grava ao confirmar',
        (tester) async {
      // CT-025: endereço vazio não bloqueia — pede confirmação e, ao
      // confirmar, grava com endereço em branco (#61).
      when(() => service.addClient(any())).thenAnswer((_) async {});

      await bombearFormulario(tester);
      await tester.enterText(campoNome, 'Débora Prado');
      await tester.enterText(campoTelefone, '11 94444-4444');
      await tester.tap(botaoSalvar);
      await tester.pumpAndSettle();

      expect(find.text('Cliente sem endereço. Deseja salvar mesmo assim?'),
          findsOneWidget);
      verifyNever(() => service.addClient(any()));

      await tester.tap(find.byKey(const Key('confirmar_sem_endereco')));
      await tester.pumpAndSettle();

      final salvo = verify(() => service.addClient(captureAny()))
          .captured
          .single as ClientModel;
      expect(salvo.nome, 'Débora Prado');
      expect(salvo.endereco.vazio, isTrue);
    });

    testWidgets('cancelar o aviso de sem endereço não grava', (tester) async {
      // CT-025 (contraparte): cancelar o aviso mantém o formulário sem gravar.
      await bombearFormulario(tester);
      await tester.enterText(campoNome, 'Débora Prado');
      await tester.enterText(campoTelefone, '11 94444-4444');
      await tester.tap(botaoSalvar);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelar_sem_endereco')));
      await tester.pumpAndSettle();

      verifyNever(() => service.addClient(any()));
      expect(find.byType(ClientFormScreen), findsOneWidget);
    });

    testWidgets('bloqueia salvar com campo vazio ou só espaços',
        (tester) async {
      await bombearFormulario(tester);

      await tester.enterText(campoNome, 'Débora Prado');
      await tester.enterText(campoLogradouro, 'Rua das Acácias');
      await tester.enterText(campoTelefone, '   '); // só espaços
      await tester.tap(botaoSalvar);
      await tester.pump();

      expect(find.text('Informe o telefone'), findsOneWidget);
      verifyNever(() => service.addClient(any()));
    });

    testWidgets('telefone rejeita caracteres inválidos', (tester) async {
      await bombearFormulario(tester);

      await preencherValido(tester);
      await tester.enterText(campoTelefone, '12#34');
      await tester.tap(botaoSalvar);
      await tester.pump();

      expect(
          find.text('Use apenas dígitos, espaços e + ( ) -'), findsOneWidget);
      verifyNever(() => service.addClient(any()));
    });

    testWidgets('salvar fecha o formulário', (tester) async {
      when(() => service.addClient(any())).thenAnswer((_) async {});
      ajustarViewport(tester);

      // formulário empilhado por navegação, como em produção
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ClientFormScreen(service: service),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await preencherValido(tester);
      await tester.tap(botaoSalvar);
      await tester.pumpAndSettle();

      // o service recebeu os dados digitados e o formulário fechou
      final salvo = verify(() => service.addClient(captureAny()))
          .captured
          .single as ClientModel;
      expect(salvo.nome, 'Débora Prado');
      expect(salvo.endereco,
          const Endereco(logradouro: 'Rua das Acácias', numero: '45'));
      expect(salvo.telefones, ['11 94444-4444']);
      expect(find.byType(ClientFormScreen), findsNothing);
    });

    testWidgets('falha ao salvar exibe erro e mantém o formulário aberto',
        (tester) async {
      // robustez além dos critérios do RF-001: insert falhando (ex.: sem
      // internet) não pode falhar em silêncio
      when(() => service.addClient(any()))
          .thenAnswer((_) async => throw Exception('sem conexão'));

      await bombearFormulario(tester);
      await preencherValido(tester);
      await tester.tap(botaoSalvar);
      await tester.pump();
      await tester.pump();

      expect(find.text('Erro ao salvar. Tente novamente.'), findsOneWidget);
      expect(find.byType(ClientFormScreen), findsOneWidget);
    });

    testWidgets('edição aplica as validações do cadastro', (tester) async {
      // CT-007: as regras do cadastro valem também no modo edição
      ajustarViewport(tester);
      await tester.pumpWidget(MaterialApp(
          home: ClientFormScreen(service: service, cliente: cliente)));

      await tester.enterText(campoNome, ''); // apaga o nome
      await tester.tap(botaoSalvar);
      await tester.pump();
      expect(find.text('Informe o nome'), findsOneWidget);

      await tester.enterText(campoNome, 'Ana Souza');
      await tester.enterText(campoTelefone, '12#34');
      await tester.tap(botaoSalvar);
      await tester.pump();
      expect(
          find.text('Use apenas dígitos, espaços e + ( ) -'), findsOneWidget);

      verifyNever(() => service.updateClient(any()));
      verifyNever(() => service.addClient(any()));
    });

    testWidgets('cancelar edição não grava nada', (tester) async {
      // CT-009: fechar sem confirmar não pode chamar gravação alguma
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    ClientFormScreen(service: service, cliente: cliente),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(campoLogradouro, 'Rua Nova');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ClientFormScreen), findsNothing);
      verifyNever(() => service.updateClient(any()));
      verifyNever(() => service.addClient(any()));
    });

    testWidgets('adiciona e remove campo de telefone', (tester) async {
      // #62: começa com um telefone; permite adicionar e remover campos
      await bombearFormulario(tester);

      expect(find.byKey(const Key('campo_telefone_0')), findsOneWidget);
      expect(find.byKey(const Key('campo_telefone_1')), findsNothing);

      await tester.tap(find.byKey(const Key('adicionar_telefone')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('campo_telefone_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('remover_telefone_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('campo_telefone_1')), findsNothing);
    });

    testWidgets('salva com dois telefones', (tester) async {
      // #62: os dois números preenchidos chegam ao service como lista
      when(() => service.addClient(any())).thenAnswer((_) async {});

      await bombearFormulario(tester);
      await tester.enterText(campoNome, 'Débora Prado');
      await tester.enterText(campoLogradouro, 'Rua das Acácias');
      await tester.enterText(
          find.byKey(const Key('campo_telefone_0')), '11 94444-4444');
      await tester.tap(find.byKey(const Key('adicionar_telefone')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('campo_telefone_1')), '11 95555-5555');
      await tester.tap(botaoSalvar);
      await tester.pumpAndSettle();

      final salvo = verify(() => service.addClient(captureAny()))
          .captured
          .single as ClientModel;
      expect(salvo.telefones, ['11 94444-4444', '11 95555-5555']);
    });

    testWidgets('segundo telefone inválido bloqueia o salvamento',
        (tester) async {
      await bombearFormulario(tester);
      await preencherValido(tester);
      await tester.tap(find.byKey(const Key('adicionar_telefone')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('campo_telefone_1')), '12#34');
      await tester.tap(botaoSalvar);
      await tester.pump();

      expect(
          find.text('Use apenas dígitos, espaços e + ( ) -'), findsOneWidget);
      verifyNever(() => service.addClient(any()));
    });
  });

  // RF-011 (#81): o histórico do cliente no topo da tela do cliente.
  group('client_form_screen_test: histórico:', () {
    final hoje = DateTime(2026, 11, 17);
    final marco = Atendimento(
      data: DateTime(2026, 3, 10),
      periodo: Periodo.manha,
      clienteId: '7',
      valor: 250,
      pecas: const [Peca(tipo: 'tapete', largura: 3, comprimento: 2)],
    );
    final agosto = Atendimento(
      data: DateTime(2026, 8, 12),
      periodo: Periodo.tarde,
      clienteId: '7',
      pecas: const [Peca(tipo: 'sofá')],
    );
    final futuro = Atendimento(
      data: DateTime(2026, 11, 30),
      periodo: Periodo.manha,
      clienteId: '7',
      valor: 999,
      pecas: const [Peca(tipo: 'poltrona')],
    );
    final deOutro = Atendimento(
      data: DateTime(2026, 9, 1),
      periodo: Periodo.manha,
      clienteId: '8',
      valor: 777,
      pecas: const [Peca(tipo: 'colchão')],
    );

    Future<void> abrirCliente(
        WidgetTester tester, List<Atendimento> atendimentos) async {
      ajustarViewport(tester);
      when(() => service.getAtendimentosStream())
          .thenAnswer((_) => Stream.value(atendimentos));
      await tester.pumpWidget(MaterialApp(
          home: ClientFormScreen(
              service: service, cliente: cliente, agora: () => hoje)));
      await tester.pump();
    }

    testWidgets('mostra a última visita e há quanto tempo', (tester) async {
      await abrirCliente(tester, [marco, futuro, agosto, deOutro]);

      final ultima = find.byKey(const Key('ultima_visita'));
      expect(find.descendant(of: ultima, matching: find.text('há 3 meses')),
          findsOneWidget);
      expect(
          find.descendant(
              of: ultima, matching: find.text('última visita em 12/08/26')),
          findsOneWidget);
    });

    testWidgets('mostra o último valor com a data e as peças', (tester) async {
      await abrirCliente(tester, [marco, agosto]);

      final valor = find.byKey(const Key('ultimo_valor'));
      expect(find.descendant(of: valor, matching: find.text('R\$ 250,00')),
          findsOneWidget);
      expect(
          find.descendant(
              of: valor,
              matching: find.text('cobrado em 10/03/26 · tapete 3 × 2')),
          findsOneWidget);
    });

    testWidgets('lista os atendimentos do mais recente ao mais antigo',
        (tester) async {
      await abrirCliente(tester, [marco, futuro, agosto, deOutro]);

      final primeiro = find.byKey(const Key('historico_item_0'));
      final segundo = find.byKey(const Key('historico_item_1'));
      expect(find.byKey(const Key('historico_item_2')), findsNothing);
      expect(find.descendant(of: primeiro, matching: find.text('12/08/26')),
          findsOneWidget);
      expect(find.descendant(of: primeiro, matching: find.text('sofá')),
          findsOneWidget);
      expect(find.descendant(of: primeiro, matching: find.text('—')),
          findsOneWidget);
      expect(find.descendant(of: segundo, matching: find.text('10/03/26')),
          findsOneWidget);
      expect(
          find.descendant(of: segundo, matching: find.text('tapete 3 × 2')),
          findsOneWidget);
      expect(find.descendant(of: segundo, matching: find.text('R\$ 250,00')),
          findsOneWidget);
      expect(find.text('R\$ 999,00'), findsNothing);
      expect(find.text('R\$ 777,00'), findsNothing);
    });

    testWidgets('sem atendimento mostra "Nenhum atendimento registrado"',
        (tester) async {
      await abrirCliente(tester, [deOutro, futuro]);

      expect(find.text('Nenhum atendimento registrado'), findsOneWidget);
      expect(find.byKey(const Key('ultima_visita')), findsNothing);
      expect(find.byKey(const Key('ultimo_valor')), findsNothing);

      // no cadastro de cliente novo o histórico não aparece
      await tester.pumpWidget(MaterialApp(
          key: UniqueKey(),
          home: ClientFormScreen(service: service, agora: () => hoje)));
      await tester.pump();
      expect(find.byKey(const Key('historico')), findsNothing);
      expect(find.text('Nenhum atendimento registrado'), findsNothing);
    });
  });
}
