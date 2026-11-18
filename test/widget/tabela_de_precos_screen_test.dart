import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/item_de_preco.dart';
import 'package:sgc_msclean/screens/tabela_de_precos_screen.dart';

import '../mocks/mock_supabase_client.dart';

// Tela da tabela de preços (RF-013, parte 1, issue #123). Roteiros CT-081 a
// CT-085 em docs/casos-de-teste.md.
void main() {
  late MockSupabaseService service;
  late List<ItemDePreco> tabela;

  const sofa = ItemDePreco(
    id: 'p1',
    nome: 'Higienização sofá 3 lugares',
    unidade: UnidadeDeCobranca.peca,
    valor: 180,
    ordem: 0,
  );
  const tapete = ItemDePreco(
    id: 'p2',
    nome: 'Higienização de tapete',
    unidade: UnidadeDeCobranca.m2,
    ordem: 1,
  );

  setUpAll(() {
    registerFallbackValue(sofa);
    registerFallbackValue(<ItemDePreco>[]);
  });

  setUp(() {
    service = MockSupabaseService();
    tabela = [sofa, tapete];
    when(() => service.conectado).thenReturn(ValueNotifier(true));
    // cada assinatura lê a tabela do momento: renovar a stream mostra a nova
    when(() => service.getPrecosStream())
        .thenAnswer((_) => Stream.value([...tabela]));
    when(() => service.addPreco(any())).thenAnswer((_) async {});
    when(() => service.updatePreco(any())).thenAnswer((_) async {});
    when(() => service.deletePreco(any())).thenAnswer((_) async {});
    when(() => service.addPrecos(any())).thenAnswer((_) async {});
  });

  Future<void> bombear(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        MaterialApp(home: TabelaDePrecosScreen(service: service)));
    await tester.pump();
  }

  group('tabela_de_precos_screen_test:', () {
    testWidgets('lista nome, unidade e valor; sem valor quando vazio',
        (tester) async {
      await bombear(tester);

      expect(find.text('Tabela de preços'), findsOneWidget);
      expect(find.text('Higienização sofá 3 lugares'), findsOneWidget);
      expect(find.text('por peça'), findsOneWidget);
      expect(find.text('R\$ 180,00'), findsOneWidget);
      expect(find.text('Higienização de tapete'), findsOneWidget);
      expect(find.text('por m²'), findsOneWidget);
      expect(find.text('sem valor'), findsOneWidget);
    });

    testWidgets('adicionar exige nome e grava com o valor e a ordem seguinte',
        (tester) async {
      await bombear(tester);

      await tester.tap(find.byKey(const Key('novo_preco')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('salvar_preco')));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome'), findsOneWidget);
      verifyNever(() => service.addPreco(any()));

      await tester.enterText(
          find.byKey(const Key('preco_nome')), 'Impermeabilização poltrona');
      await tester.enterText(find.byKey(const Key('preco_valor')), '90,50');
      await tester.tap(find.byKey(const Key('salvar_preco')));
      await tester.pumpAndSettle();

      final gravado =
          verify(() => service.addPreco(captureAny())).captured.single
              as ItemDePreco;
      expect(gravado.nome, 'Impermeabilização poltrona');
      expect(gravado.unidade, UnidadeDeCobranca.peca);
      expect(gravado.valor, 90.5);
      expect(gravado.ordem, 2);
      // a lista é renovada ao voltar
      verify(() => service.getPrecosStream()).called(2);
    });

    testWidgets('editar abre preenchido e apagar o valor grava sem valor',
        (tester) async {
      await bombear(tester);

      await tester.tap(find.text('Higienização de tapete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unidade_peca')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('unidade_m2')));
      await tester.pump();

      expect(
          tester
              .widget<TextField>(find.byKey(const Key('preco_nome')))
              .controller!
              .text,
          'Higienização de tapete');
      await tester.enterText(find.byKey(const Key('preco_valor')), '35');
      await tester.tap(find.byKey(const Key('salvar_preco')));
      await tester.pumpAndSettle();

      var gravado = verify(() => service.updatePreco(captureAny()))
          .captured
          .single as ItemDePreco;
      expect(gravado.id, 'p2');
      expect(gravado.unidade, UnidadeDeCobranca.m2);
      expect(gravado.valor, 35.0);
      expect(gravado.ordem, 1);

      await tester.tap(find.text('Higienização sofá 3 lugares'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('preco_valor')))
              .controller!
              .text,
          '180,00');
      await tester.enterText(find.byKey(const Key('preco_valor')), '');
      await tester.tap(find.byKey(const Key('salvar_preco')));
      await tester.pumpAndSettle();

      gravado = verify(() => service.updatePreco(captureAny()))
          .captured
          .single as ItemDePreco;
      expect(gravado.id, 'p1');
      expect(gravado.valor, isNull);
    });

    // CT-100 (#134): o serviço diz a que peça, variante e serviço corresponde.
    testWidgets('editor grava peça, variante, serviço e retrátil',
        (tester) async {
      await bombear(tester);

      await tester.tap(find.byKey(const Key('novo_preco')));
      await tester.pumpAndSettle();
      // variante só aparece depois de escolher uma peça que tem variante
      expect(find.byKey(const Key('preco_variante_4')), findsNothing);
      await tester.tap(find.byKey(const Key('preco_peca_sofa')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('preco_variante_4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('preco_servico_impermeabilizar')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('preco_retratil')));
      await tester.pump();

      // o nome se monta sozinho enquanto ela não digita outro
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('preco_nome')))
              .controller!
              .text,
          'Impermeabilização sofá 4 lugares retrátil');
      await tester.enterText(find.byKey(const Key('preco_valor')), '260');
      await tester.tap(find.byKey(const Key('salvar_preco')));
      await tester.pumpAndSettle();

      final gravado =
          verify(() => service.addPreco(captureAny())).captured.single
              as ItemDePreco;
      expect(gravado.peca, Familia.sofa);
      expect(gravado.variante, '4');
      expect(gravado.servico, TipoDeServico.impermeabilizar);
      expect(gravado.retratil, isTrue);
      expect(gravado.valor, 260);
    });

    testWidgets('remover pede confirmação; cancelar não remove',
        (tester) async {
      await bombear(tester);

      await tester.tap(find.byKey(const Key('excluir_preco_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(() => service.deletePreco(any()));

      await tester.tap(find.byKey(const Key('excluir_preco_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      verify(() => service.deletePreco('p1')).called(1);
      expect(find.text('Serviço removido'), findsOneWidget);
    });

    testWidgets('dica: serviços independentes e combo', (tester) async {
      await bombear(tester);

      final dica = tester
          .widget<Text>(find.byKey(const Key('dica_servicos')))
          .data!
          .toLowerCase();
      expect(dica, contains('independente'));
      expect(dica, contains('impermeabilização'));
      expect(dica, contains('combo'));
    });

    testWidgets('tabela vazia começa com a lista sugerida, sem valor',
        (tester) async {
      tabela = [];
      await bombear(tester);

      await tester.tap(find.byKey(const Key('lista_sugerida')));
      await tester.pumpAndSettle();

      final gravada = verify(() => service.addPrecos(captureAny()))
          .captured
          .single as List<ItemDePreco>;
      expect(gravada.map((i) => i.nome),
          ItemDePreco.listaSugerida().map((i) => i.nome));
      expect(gravada.every((i) => i.valor == null), isTrue);
      verify(() => service.getPrecosStream()).called(2);
    });

    testWidgets('com serviço cadastrado, a lista sugerida não aparece',
        (tester) async {
      await bombear(tester);

      expect(find.byKey(const Key('lista_sugerida')), findsNothing);
    });
  });
}
