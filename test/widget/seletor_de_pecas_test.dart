import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/item_de_preco.dart';
import 'package:sgc_msclean/models/peca.dart';
import 'package:sgc_msclean/widgets/seletor_de_pecas.dart';

// Seletor de peças e serviços (RF-013, issue #134): quadros por família,
// ajuste por − / +, Higienizar e Impermeabilizar por peça, preço pela tabela.
// Roteiros CT-093 a CT-096, CT-098, CT-099 e CT-102 em docs/casos-de-teste.md.
// Índice do cartão que contém a chave (o colchão muda de posição conforme
// as famílias que já entraram).
int _indiceDoCartao(WidgetTester tester, String chave) {
  final cartao = find.ancestor(
      of: find.byKey(Key(chave)),
      matching: find.byWidgetPredicate((w) =>
          w is Card && (w.key as ValueKey<String>?)?.value.startsWith('cartao_') == true));
  final k = (tester.widget<Card>(cartao).key! as ValueKey<String>).value;
  return int.parse(k.substring('cartao_'.length));
}

void main() {
  ItemDePreco linha(String nome, Familia? peca, String? variante,
          TipoDeServico? servico, double? valor,
          {bool retratil = false,
          UnidadeDeCobranca unidade = UnidadeDeCobranca.peca}) =>
      ItemDePreco(
          id: nome,
          nome: nome,
          unidade: unidade,
          valor: valor,
          peca: peca,
          variante: variante,
          servico: servico,
          retratil: retratil);

  const hig = TipoDeServico.higienizar;
  const imp = TipoDeServico.impermeabilizar;
  final tabela = [
    linha('Higienização sofá 3 lugares', Familia.sofa, '3', hig, 200),
    linha('Impermeabilização sofá 3 lugares', Familia.sofa, '3', imp, 150),
    // a linha retrátil guarda só o acréscimo (#134)
    linha('Higienização sofá 3 lugares retrátil', Familia.sofa, '3', hig, 30,
        retratil: true),
    linha('Higienização colchão casal', Familia.colchao, 'casal', hig, 150),
    linha('Higienização de tapete', Familia.tapete, null, hig, 12,
        unidade: UnidadeDeCobranca.m2),
    linha('Higienização poltrona', Familia.poltrona, null, hig, 90),
    linha('Deslocamento', null, null, null, 30),
    linha('Remoção de mancha', null, null, null, 50),
  ];

  late List<Peca> mudou;

  Future<void> bombear(WidgetTester tester,
      {List<Peca> pecas = const [], List<ItemDePreco>? precos}) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    mudou = pecas;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SeletorDePecas(
            pecas: pecas,
            tabela: precos ?? tabela,
            aoMudar: (p) => mudou = p,
          ),
        ),
      ),
    ));
  }

  Future<void> tocar(WidgetTester tester, String chave) async {
    await tester.tap(find.byKey(Key(chave)));
    await tester.pump();
  }

  String texto(WidgetTester tester, String chave) =>
      tester.widget<Text>(find.byKey(Key(chave))).data!;

  group('seletor_de_pecas_test:', () {
    testWidgets('quadros na ordem das famílias, com selo ×N', (tester) async {
      await bombear(tester);

      final ordem = [
        for (final f in Familia.values)
          tester.getTopLeft(find.byKey(Key('familia_${f.name}'))),
      ];
      // em grade: cada quadro vem depois do anterior (linha, depois coluna)
      for (var i = 1; i < ordem.length; i++) {
        final antes = ordem[i - 1];
        final agora = ordem[i];
        expect(
            agora.dy > antes.dy || (agora.dy == antes.dy && agora.dx > antes.dx),
            isTrue,
            reason: Familia.values[i].name);
      }
      expect(Familia.values.map((f) => f.rotulo), [
        'Sofá',
        'Tapete',
        'Poltrona',
        'Cortina',
        'Colchão',
        'Cadeira',
        'Outros'
      ]);
      expect(find.byKey(const Key('selo_familia_sofa')), findsNothing);

      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'familia_poltrona');

      expect(texto(tester, 'selo_familia_sofa'), '×2');
      expect(texto(tester, 'selo_familia_poltrona'), '×1');
      expect(mudou.where((p) => p.tipo == 'sofá'), hasLength(2));
      expect(mudou.where((p) => p.tipo == 'poltrona').single.quantidade, 1);
    });

    testWidgets('sofá: lugares de 2 a canto, retrátil e pôr outro sofá',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_sofa');

      expect(texto(tester, 'cartao_0_lugares'), '3 lug.');
      await tocar(tester, 'cartao_0_menos_lugares');
      expect(texto(tester, 'cartao_0_lugares'), '2 lug.');
      await tocar(tester, 'cartao_0_menos_lugares'); // não passa de 2
      expect(texto(tester, 'cartao_0_lugares'), '2 lug.');
      for (var i = 0; i < 4; i++) {
        await tocar(tester, 'cartao_0_mais_lugares');
      }
      expect(texto(tester, 'cartao_0_lugares'), 'canto');
      expect(mudou.single.variante, 'canto');

      await tocar(tester, 'cartao_0_retratil');
      expect(mudou.single.retratil, isTrue);

      await tocar(tester, 'por_outro_sofa');
      expect(mudou, hasLength(2));
      expect(mudou.last.variante, '3');
      expect(find.text('Sofá 2'), findsOneWidget);

      await tocar(tester, 'cartao_1_remover');
      expect(mudou, hasLength(1));
    });

    testWidgets('tapete: medidas de 0,5 em 0,5 com os m² na hora',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_tapete');

      expect(texto(tester, 'cartao_0_area'), 'informe as medidas');
      for (var i = 0; i < 4; i++) {
        await tocar(tester, 'cartao_0_mais_largura');
      }
      for (var i = 0; i < 6; i++) {
        await tocar(tester, 'cartao_0_mais_comprimento');
      }
      expect(texto(tester, 'cartao_0_largura'), '2 m');
      expect(texto(tester, 'cartao_0_comprimento'), '3 m');
      expect(texto(tester, 'cartao_0_area'), '6 m²');

      await tocar(tester, 'cartao_0_menos_comprimento');
      expect(texto(tester, 'cartao_0_comprimento'), '2,5 m');
      expect(texto(tester, 'cartao_0_area'), '5 m²');
      expect(mudou.single.largura, 2);
      expect(mudou.single.comprimento, 2.5);
    });

    testWidgets('colchão, cortina, poltrona e cadeira por − / +',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_colchao');
      await tocar(tester, 'colchao_casal_mais');
      await tocar(tester, 'colchao_casal_mais');
      await tocar(tester, 'colchao_solteiro_mais');
      await tocar(tester, 'colchao_solteiro_menos');
      expect(texto(tester, 'colchao_casal_quantidade'), '2');
      expect(texto(tester, 'selo_familia_colchao'), '×2');

      await tocar(tester, 'familia_cortina');
      await tocar(tester, 'familia_cadeira');
      final cortina = mudou.indexWhere((p) => p.tipo == 'cortina');
      final cadeira = mudou.indexWhere((p) => p.tipo == 'cadeira');
      expect(cortina, isNonNegative);
      expect(cadeira, isNonNegative);

      // cartões na ordem das famílias: cortina (0), colchão (1), cadeira (2)
      await tocar(tester, 'cartao_0_mais');
      await tocar(tester, 'cartao_0_mais');
      expect(texto(tester, 'cartao_0_quantidade'), '3');
      await tocar(tester, 'cartao_2_mais');
      await tocar(tester, 'cartao_2_menos');
      await tocar(tester, 'cartao_2_menos'); // não passa de 1
      expect(texto(tester, 'cartao_2_quantidade'), '1');

      // poltrona tocada de novo soma na mesma peça
      await tocar(tester, 'familia_poltrona');
      await tocar(tester, 'familia_poltrona');
      expect(mudou.where((p) => p.tipo == 'poltrona').single.quantidade, 2);

      final colchoes = mudou.where((p) => p.tipo == 'colchão').toList();
      expect(colchoes.single.variante, 'casal');
      expect(colchoes.single.quantidade, 2);
      expect(mudou.firstWhere((p) => p.tipo == 'cortina').quantidade, 3);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('higienizar e impermeabilizar marcados separados ou juntos',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_sofa');

      expect(texto(tester, 'cartao_0_higienizar_preco'), 'R\$ 200,00');
      expect(texto(tester, 'cartao_0_impermeabilizar_preco'), 'R\$ 150,00');

      await tocar(tester, 'cartao_0_impermeabilizar');
      expect(mudou.single.servicos.single.nome,
          'Impermeabilização sofá 3 lugares');
      expect(mudou.single.servicos.single.valor, 150);

      await tocar(tester, 'cartao_0_higienizar');
      expect(mudou.single.servicos.map((s) => s.servico),
          containsAll([hig, imp]));

      await tocar(tester, 'cartao_0_impermeabilizar');
      expect(mudou.single.servicos.single.servico, hig);
    });

    testWidgets('preço troca com a variante; sem linha fica sem valor',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'cartao_0_higienizar');
      expect(mudou.single.servicos.single.valor, 200);

      await tocar(tester, 'cartao_0_mais_lugares'); // 4 lugares: sem linha
      expect(mudou.single.servicos.single.nome, 'Higienização sofá 4 lugares');
      expect(mudou.single.servicos.single.valor, isNull);
      expect(texto(tester, 'cartao_0_higienizar_preco'), 'sem valor');

      await tocar(tester, 'cartao_0_menos_lugares');
      // retrátil: o preço comum mais o acréscimo da linha retrátil
      await tocar(tester, 'cartao_0_retratil');
      expect(mudou.single.servicos.single.nome,
          'Higienização sofá 3 lugares retrátil');
      expect(mudou.single.servicos.single.valor, 230);
      expect(texto(tester, 'cartao_0_higienizar_preco'), 'R\$ 230,00');

      await tocar(tester, 'familia_colchao');
      await tocar(tester, 'colchao_casal_mais');
      await tocar(tester, 'colchao_casal_mais');
      await tocar(tester, 'cartao_1_higienizar');
      final colchao = mudou.firstWhere((p) => p.tipo == 'colchão');
      expect(colchao.servicos.single.valor, 150);
      expect(colchao.quantidade, 2);
    });

    testWidgets('deslocamento é liga/desliga; os outros avulsos por quantidade',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_outros');

      expect(find.text('Deslocamento'), findsOneWidget);
      expect(find.byKey(const Key('avulso_Deslocamento_mais')), findsNothing);
      await tocar(tester, 'avulso_Deslocamento_liga');

      final outro = mudou.single;
      expect(outro.tipo, 'outro');
      expect(outro.quantidade, 1);
      expect(outro.servicos.single.nome, 'Deslocamento');
      expect(outro.servicos.single.valor, 30);
      expect(texto(tester, 'selo_familia_outros'), '×1');

      await tocar(tester, 'avulso_Remoção de mancha_mais');
      await tocar(tester, 'avulso_Remoção de mancha_mais');
      expect(
          mudou.firstWhere((p) => p.servicos.single.nome == 'Remoção de mancha')
              .quantidade,
          2);

      await tocar(tester, 'avulso_Deslocamento_liga');
      expect(mudou.single.servicos.single.nome, 'Remoção de mancha');
    });

    // CT-102: preço do serviço ajustado só neste registro.
    Future<void> ajustar(WidgetTester tester, String chave, String valor,
        {String? justificativa}) async {
      await tester.tap(find.byKey(Key(chave)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('ajuste_valor')), valor);
      if (justificativa != null) {
        await tester.enterText(
            find.byKey(const Key('ajuste_justificativa')), justificativa);
      }
      await tester.tap(find.byKey(const Key('ajuste_confirmar')));
      await tester.pumpAndSettle();
    }

    testWidgets('ajustar o preço de um serviço só neste registro, com justificativa',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_sofa');
      // só o serviço marcado pode ser ajustado
      expect(find.byKey(const Key('cartao_0_higienizar_ajustar')), findsNothing);
      await tocar(tester, 'cartao_0_higienizar');

      await ajustar(tester, 'cartao_0_higienizar_ajustar', '220',
          justificativa: 'tecido linho');

      expect(texto(tester, 'cartao_0_higienizar_preco'), 'R\$ 220,00');
      expect(find.byKey(const Key('cartao_0_higienizar_ajustado')),
          findsOneWidget);
      final s = mudou.single.servicos.single;
      expect(s.valor, 220);
      expect(s.valorDaTabela, 200);
      expect(s.justificativa, 'tecido linho');
      expect(tabela.first.valor, 200); // a tabela não muda

      // avulso e colchão também, sem justificativa
      await tocar(tester, 'familia_outros');
      await tocar(tester, 'avulso_Deslocamento_liga');
      await ajustar(tester, 'avulso_Deslocamento_ajustar', '45');
      expect(
          mudou.firstWhere((p) => p.tipo == 'outro').servicos.single.valor, 45);

      await tocar(tester, 'familia_colchao');
      await tocar(tester, 'colchao_casal_mais');
      final colchao = _indiceDoCartao(tester, 'colchao_casal_mais');
      await tocar(tester, 'cartao_${colchao}_higienizar');
      await ajustar(tester, 'colchao_casal_higienizar_ajustar', '130',
          justificativa: 'só um lado');
      final c = mudou.firstWhere((p) => p.tipo == 'colchão').servicos.single;
      expect(c.valor, 130);
      expect(c.valorDaTabela, 150);
    });

    testWidgets('voltar ao preço da tabela desfaz o ajuste', (tester) async {
      await bombear(tester);
      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'cartao_0_higienizar');
      await ajustar(tester, 'cartao_0_higienizar_ajustar', '180',
          justificativa: 'desconto');

      await tester.tap(find.byKey(const Key('cartao_0_higienizar_ajustar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ajuste_voltar_tabela')));
      await tester.pumpAndSettle();

      final s = mudou.single.servicos.single;
      expect(s.valor, 200);
      expect(s.ajustado, isFalse);
      expect(s.justificativa, isNull);
      expect(find.byKey(const Key('cartao_0_higienizar_ajustado')), findsNothing);
    });

    testWidgets('peças de antes abrem e voltam iguais', (tester) async {
      // atendimento salvo pela #124: sofá sem variante, serviços sem a chave
      // servico, um avulso preso ao sofá; tapete com medidas
      final antes = [
        Peca.fromMap({
          'tipo': 'sofá',
          'quantidade': 1,
          'servicos': [
            {
              'nome': 'Higienização sofá 3 lugares',
              'unidade': 'peca',
              'valor': 180
            },
            {'nome': 'Remoção de odor', 'unidade': 'peca', 'valor': null},
          ],
        }),
        const Peca(tipo: 'tapete', largura: 2, comprimento: 3),
        const Peca(tipo: 'outro', quantidade: 2),
      ];
      await bombear(tester, pecas: antes);

      expect(texto(tester, 'cartao_0_higienizar_preco'), 'R\$ 180,00');
      expect(find.text('Remoção de odor'), findsOneWidget);
      expect(texto(tester, 'cartao_1_area'), '6 m²');

      // nenhum toque: nada muda; um toque neutro (mais e menos) devolve igual
      await tocar(tester, 'cartao_1_mais_largura');
      await tocar(tester, 'cartao_1_menos_largura');

      final sofa = mudou.firstWhere((p) => p.tipo == 'sofá');
      expect(sofa.variante, isNull);
      expect(sofa.servicos.map((s) => s.nome),
          ['Higienização sofá 3 lugares', 'Remoção de odor']);
      expect(sofa.servicos.first.valor, 180);
      expect(mudou.firstWhere((p) => p.tipo == 'tapete').area, 6);
      expect(mudou.firstWhere((p) => p.tipo == 'outro').quantidade, 2);
    });
  });
}
