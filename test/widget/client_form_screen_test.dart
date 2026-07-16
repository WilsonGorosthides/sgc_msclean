import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/screens/client_form_screen.dart';

import '../mocks/mock_supabase_client.dart';

// Testes de widget do formulário de cadastro (RF-001), com
// MockSupabaseService injetado — roteiros em docs/casos-de-teste.md
// (CT-001, CT-002, CT-003, CT-005 e o caso extra de robustez do erro).
void main() {
  late MockSupabaseService service;

  setUpAll(() {
    registerFallbackValue(ClientModel(nome: '', endereco: '', telefone: ''));
  });

  setUp(() {
    service = MockSupabaseService();
  });

  final campoNome = find.byKey(const Key('campo_nome'));
  final campoEndereco = find.byKey(const Key('campo_endereco'));
  final campoTelefone = find.byKey(const Key('campo_telefone'));
  final botaoSalvar = find.byKey(const Key('botao_salvar'));

  Future<void> bombearFormulario(WidgetTester tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ClientFormScreen(service: service)));
  }

  Future<void> preencherValido(WidgetTester tester) async {
    await tester.enterText(campoNome, 'Débora Prado');
    await tester.enterText(campoEndereco, 'Rua das Acácias, 45');
    await tester.enterText(campoTelefone, '11 94444-4444');
  }

  group('client_form_screen_test:', () {
    testWidgets('exige nome, endereço e telefone', (tester) async {
      await bombearFormulario(tester);

      await tester.tap(botaoSalvar);
      await tester.pump();

      expect(find.text('Informe o nome'), findsOneWidget);
      expect(find.text('Informe o endereço'), findsOneWidget);
      expect(find.text('Informe o telefone'), findsOneWidget);
      verifyNever(() => service.addClient(any()));
    });

    testWidgets('bloqueia salvar com campo vazio ou só espaços',
        (tester) async {
      await bombearFormulario(tester);

      await tester.enterText(campoNome, 'Débora Prado');
      await tester.enterText(campoEndereco, 'Rua das Acácias, 45');
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
      expect(salvo.endereco, 'Rua das Acácias, 45');
      expect(salvo.telefone, '11 94444-4444');
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
  });
}
