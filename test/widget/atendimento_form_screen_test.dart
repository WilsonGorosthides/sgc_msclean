import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/models/endereco.dart';
import 'package:sgc_msclean/models/item_de_preco.dart';
import 'package:sgc_msclean/models/peca.dart';
import 'package:sgc_msclean/screens/atendimento_form_screen.dart';
import 'package:sgc_msclean/services/contatos.dart';

import '../mocks/agenda_falsa.dart';
import '../mocks/mock_supabase_client.dart';

// Testes de widget do formulário de atendimento (RF-005 enxuto, issue #77),
// com MockSupabaseService injetado — roteiros CT-041, CT-043, CT-044, CT-045 e
// CT-047 em docs/casos-de-teste.md. A data vem pronta do dia da agenda.
void main() {
  late MockSupabaseService service;
  final dia = DateTime(2026, 11, 13);

  final ana = ClientModel(
      id: '1',
      nome: 'Ana Souza',
      endereco: const Endereco(
          logradouro: 'Rua das Flores', numero: '10', bairro: 'Jardim'),
      telefones: const ['11 91111-1111']);
  final bruno = ClientModel(
      id: '2', nome: 'Bruno Lima', telefones: const ['11 92222-2222']);
  final clientes = [ana, bruno];

  setUpAll(() {
    registerFallbackValue(Atendimento(
      data: DateTime(2026),
      periodo: Periodo.manha,
      clienteId: '',
    ));
    registerFallbackValue(
        const ItemDePreco(nome: '', unidade: UnidadeDeCobranca.peca));
  });

  // Tabela de preços (RF-013, #124): vazia, salvo nos testes do cálculo.
  var tabela = <ItemDePreco>[];

  setUp(() {
    service = MockSupabaseService();
    tabela = [];
    when(() => service.addAtendimento(any())).thenAnswer((_) async {});
    when(() => service.getPrecosStream())
        .thenAnswer((_) => Stream.value([...tabela]));
  });

  // [chave] distingue uma segunda montagem no mesmo teste: sem ela o Flutter
  // reaproveita o MaterialApp (e o Navigator já sem rota, após o pop).
  Future<void> bombear(WidgetTester tester,
      {Atendimento? atendimento, Key? chave, AgendaDoCelular? contatos}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      key: chave,
      home: AtendimentoFormScreen(
        service: service,
        data: dia,
        clientes: clientes,
        atendimento: atendimento,
        contatos: contatos,
      ),
    ));
    await tester.pump(); // a tabela de preços chega
  }

  Future<void> tocar(WidgetTester tester, String chave) async {
    await tester.tap(find.byKey(Key(chave)));
    await tester.pump();
  }

  Future<void> digitar(WidgetTester tester, String chave, String texto) =>
      tester.enterText(find.byKey(Key(chave)), texto);

  String textoDoCampo(WidgetTester tester, String chave) =>
      tester.widget<TextFormField>(find.byKey(Key(chave))).controller!.text;

  // Peças e valor ficam numa tela própria, aberta pela linha de resumo
  // (CT-101): "Pronto" volta ao formulário com o que foi marcado.
  Future<void> abrirPecas(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('abrir_pecas')));
    await tester.pumpAndSettle();
  }

  Future<void> fecharPecas(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('pecas_pronto')));
    await tester.pumpAndSettle();
  }

  Future<Atendimento> salvarECapturar(WidgetTester tester) async {
    await tocar(tester, 'botao_salvar');
    await tester.pump();
    return verify(() => service.addAtendimento(captureAny())).captured.single
        as Atendimento;
  }

  group('atendimento_form_screen_test:', () {
    testWidgets('exige cliente e período; hora é opcional', (tester) async {
      await bombear(tester);

      expect(textoDe(tester, 'data_atendimento'),
          'sexta-feira, 13 de novembro de 2026');

      await tocar(tester, 'botao_salvar');
      expect(find.text('Escolha um cliente'), findsOneWidget);
      expect(find.text('Escolha o período'), findsOneWidget);
      verifyNever(() => service.addAtendimento(any()));

      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_manha');
      expect(find.text('Escolha um cliente'), findsNothing);
      expect(find.text('Escolha o período'), findsNothing);

      final gravado = await salvarECapturar(tester);
      expect(gravado.clienteId, '1');
      expect(gravado.periodo, Periodo.manha);
      expect(gravado.hora, isNull);
      expect(gravado.data, dia);
    });

    testWidgets('hora inválida bloqueia; hora válida é gravada',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_tarde');

      await digitar(tester, 'campo_hora', 'nove');
      await tocar(tester, 'botao_salvar');
      verifyNever(() => service.addAtendimento(any()));

      // digitação abreviada: "830" é completado para 08:30
      await digitar(tester, 'campo_hora', '830');
      final gravado = await salvarECapturar(tester);
      expect(gravado.hora, '08:30');
    });

    testWidgets('busca filtra os clientes pelo nome', (tester) async {
      await bombear(tester);

      expect(find.byKey(const Key('escolher_cliente_1')), findsOneWidget);
      expect(find.byKey(const Key('escolher_cliente_2')), findsOneWidget);

      await digitar(tester, 'busca_cliente', 'bru');
      await tester.pump();

      expect(find.byKey(const Key('escolher_cliente_1')), findsNothing);
      expect(find.byKey(const Key('escolher_cliente_2')), findsOneWidget);
    });

    // CT-044 (#134): sem serviço, o valor é informado pelo rodapé.
    testWidgets('sem serviço, valor mudado com vírgula; vazio grava sem valor',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_manha');
      await abrirPecas(tester);
      expect(textoDe(tester, 'total_a_cobrar'), 'sem valor');

      await tocar(tester, 'mudar_valor');
      await tester.pumpAndSettle();
      await digitar(tester, 'campo_valor', '180,50');
      await tocar(tester, 'confirmar_valor');
      await tester.pumpAndSettle();
      expect(textoDe(tester, 'total_a_cobrar'), 'R\$ 180,50');
      await fecharPecas(tester);
      expect(textoDe(tester, 'resumo_valor'), 'R\$ 180,50');

      final comValor = await salvarECapturar(tester);
      expect(comValor.valor, 180.5);

      await bombear(tester, chave: const Key('segundo'));
      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_manha');

      final semValor = await salvarECapturar(tester);
      expect(semValor.valor, isNull);
    });

    testWidgets('nome não cadastrado cria cliente provisório só com o nome',
        (tester) async {
      await bombear(tester);
      expect(find.byKey(const Key('anotar_so_nome')), findsNothing);

      await digitar(tester, 'busca_cliente', 'Dona Ivete');
      await tester.pump();
      expect(find.byKey(const Key('anotar_so_nome')), findsOneWidget);

      final criada =
          ClientModel(id: 'novo', nome: 'Dona Ivete', telefones: const []);
      when(() => service.addClienteProvisorio('Dona Ivete'))
          .thenAnswer((_) async => criada);

      await tocar(tester, 'anotar_so_nome');
      expect(find.text('Dona Ivete'), findsOneWidget);
      expect(find.text('provisório'), findsOneWidget);

      await tocar(tester, 'escolher_tarde');
      final gravado = await salvarECapturar(tester);

      verify(() => service.addClienteProvisorio('Dona Ivete')).called(1);
      expect(gravado.clienteId, 'novo');
      expect(gravado.periodo, Periodo.tarde);
    });

    // RF-016 (#115), CT-074: contato do celular no atendimento.
    testWidgets('contato que já é cliente seleciona o cliente', (tester) async {
      await bombear(tester,
          contatos: AgendaFalsa(
              const Contato(nome: 'Aninha', telefone: '+55 11 91111-1111')));
      await tocar(tester, 'dos_contatos');
      await tester.pumpAndSettle();
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('provisório'), findsNothing);
    });

    testWidgets('contato novo vira cliente com telefone ao salvar',
        (tester) async {
      await bombear(tester,
          contatos: AgendaFalsa(
              const Contato(nome: 'Dona Ivete', telefone: '67993018496')));
      final criada = ClientModel(
          id: 'novo', nome: 'Dona Ivete', telefones: const ['+55 67 99301-8496']);
      when(() => service.addClienteDoContato('Dona Ivete', '+55 67 99301-8496'))
          .thenAnswer((_) async => criada);

      await tocar(tester, 'dos_contatos');
      await tester.pumpAndSettle();
      expect(find.text('Dona Ivete'), findsOneWidget);
      expect(find.text('provisório'), findsNothing);

      await tocar(tester, 'escolher_tarde');
      final gravado = await salvarECapturar(tester);

      verify(() =>
              service.addClienteDoContato('Dona Ivete', '+55 67 99301-8496'))
          .called(1);
      verifyNever(() => service.addClienteProvisorio(any()));
      expect(gravado.clienteId, 'novo');
    });

    testWidgets('local vem do endereço do cliente e pode ser alterado',
        (tester) async {
      await bombear(tester);

      await tocar(tester, 'escolher_cliente_1');
      expect(textoDoCampo(tester, 'campo_local'), 'Rua das Flores, 10 - Jardim');

      await digitar(tester, 'campo_local', 'Casa da filha, Rua B, 7');
      await tocar(tester, 'escolher_manha');
      final gravado = await salvarECapturar(tester);
      expect(gravado.local, 'Casa da filha, Rua B, 7');

      await bombear(tester, chave: const Key('segundo'));
      await tocar(tester, 'escolher_cliente_2');
      expect(textoDoCampo(tester, 'campo_local'), '');
    });

    testWidgets('trocar o cliente volta à busca', (tester) async {
      await bombear(tester);
      await tocar(tester, 'escolher_cliente_1');
      expect(find.byKey(const Key('busca_cliente')), findsNothing);

      await tocar(tester, 'trocar_cliente');

      expect(find.byKey(const Key('busca_cliente')), findsOneWidget);
      expect(find.byKey(const Key('escolher_cliente_2')), findsOneWidget);
    });

    testWidgets('edição abre preenchida e salva pelo update', (tester) async {
      final existente = Atendimento(
        id: 'a1',
        data: dia,
        periodo: Periodo.tarde,
        hora: '15:00',
        clienteId: '2',
        local: 'Loja do centro',
        pecas: const [Peca(tipo: 'poltrona', quantidade: 2)],
        valor: 120,
      );
      when(() => service.updateAtendimento(any())).thenAnswer((_) async {});
      await bombear(tester, atendimento: existente);

      expect(find.text('Editar atendimento'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsOneWidget);
      expect(textoDoCampo(tester, 'campo_hora'), '15:00');
      expect(textoDoCampo(tester, 'campo_local'), 'Loja do centro');
      expect(textoDe(tester, 'resumo_valor'), 'R\$ 120,00');
      expect(textoDe(tester, 'resumo_pecas'), '2× poltrona');

      await digitar(tester, 'campo_hora', '16:00');
      await tocar(tester, 'botao_salvar');
      await tester.pump();

      final gravado =
          verify(() => service.updateAtendimento(captureAny())).captured.single
              as Atendimento;
      expect(gravado.id, 'a1');
      expect(gravado.hora, '16:00');
      expect(gravado.pecas.single.tipo, 'poltrona');
      verifyNever(() => service.addAtendimento(any()));
    });

    testWidgets('falha ao salvar exibe erro e mantém o formulário aberto',
        (tester) async {
      when(() => service.addAtendimento(any())).thenThrow(Exception('rede'));
      await bombear(tester);
      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_manha');

      await tocar(tester, 'botao_salvar');
      await tester.pump();

      expect(find.text('Erro ao salvar. Tente novamente.'), findsOneWidget);
      expect(find.byType(AtendimentoFormScreen), findsOneWidget);
    });

    // ---- #106: trocar o dia e excluir, na edição ----

    Atendimento existente() => Atendimento(
          id: 'a1',
          data: dia,
          periodo: Periodo.manha,
          clienteId: '1',
          pecas: const [Peca(tipo: 'sofá', quantidade: 1)],
          valor: 200,
          feito: true,
        );

    testWidgets('na edição, trocar o dia leva a data nova ao update',
        (tester) async {
      when(() => service.updateAtendimento(any())).thenAnswer((_) async {});
      await bombear(tester, atendimento: existente());

      await tocar(tester, 'data_atendimento');
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(textoDe(tester, 'data_atendimento'),
          'sexta-feira, 20 de novembro de 2026');

      await tocar(tester, 'botao_salvar');
      await tester.pump();

      final gravado =
          verify(() => service.updateAtendimento(captureAny())).captured.single
              as Atendimento;
      expect(gravado.id, 'a1');
      expect(gravado.data, DateTime(2026, 11, 20));
      expect(gravado.pecas.single.tipo, 'sofá');
      expect(gravado.valor, 200);
    });

    testWidgets('no registro novo, a data não abre o calendário',
        (tester) async {
      await bombear(tester);

      await tocar(tester, 'data_atendimento');
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('excluir pede confirmação; cancelar não apaga, confirmar apaga',
        (tester) async {
      when(() => service.deleteAtendimento(any())).thenAnswer((_) async {});
      await bombear(tester, atendimento: existente());

      await tocar(tester, 'excluir_atendimento');
      await tester.pumpAndSettle();
      expect(find.text('Excluir atendimento?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(() => service.deleteAtendimento(any()));
      expect(find.byType(AtendimentoFormScreen), findsOneWidget);

      await tocar(tester, 'excluir_atendimento');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      verify(() => service.deleteAtendimento('a1')).called(1);
      expect(find.byType(AtendimentoFormScreen), findsNothing);
    });

    testWidgets('falha ao excluir avisa e mantém o formulário',
        (tester) async {
      when(() => service.deleteAtendimento(any()))
          .thenThrow(Exception('rede'));
      await bombear(tester, atendimento: existente());

      await tocar(tester, 'excluir_atendimento');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Erro ao excluir. Tente novamente.'), findsOneWidget);
      expect(find.byType(AtendimentoFormScreen), findsOneWidget);
    });

    testWidgets('registro novo não mostra o excluir', (tester) async {
      await bombear(tester);
      expect(find.byKey(const Key('excluir_atendimento')), findsNothing);
    });
  });

  // Seletor de peças e rodapé fixo (RF-013, issue #134).
  group('atendimento_form_screen_test:', () {
    ItemDePreco linha(String nome, Familia? peca, String? variante,
            TipoDeServico? servico, double? valor) =>
        ItemDePreco(
            id: nome,
            nome: nome,
            unidade: UnidadeDeCobranca.peca,
            valor: valor,
            peca: peca,
            variante: variante,
            servico: servico);

    final sofa3 = linha('Higienização sofá 3 lugares', Familia.sofa, '3',
        TipoDeServico.higienizar, 200);
    final poltrona = linha('Higienização poltrona', Familia.poltrona, null,
        TipoDeServico.higienizar, 90);

    Future<void> pronto(WidgetTester tester) async {
      await bombear(tester);
      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_manha');
    }

    // CT-101: o formulário é rápido; peças e valor numa tela própria.
    testWidgets('atendimento rápido: peças e valor numa linha que abre a tela',
        (tester) async {
      tabela = [sofa3];
      await pronto(tester);

      expect(find.byKey(const Key('familia_sofa')), findsNothing);
      expect(find.byKey(const Key('total_a_cobrar')), findsNothing);
      expect(textoDe(tester, 'resumo_pecas'), 'Adicionar peças e valor');

      await abrirPecas(tester);
      expect(find.text('Peças e valor'), findsOneWidget);
      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'cartao_0_higienizar');
      await fecharPecas(tester);

      expect(textoDe(tester, 'resumo_pecas'), 'sofá 3 lugares');
      expect(textoDe(tester, 'resumo_valor'), 'R\$ 200,00');
      final gravado = await salvarECapturar(tester);
      expect(gravado.valor, 200);
      expect(gravado.pecas.single.servicos.single.valor, 200);
    });

    testWidgets('voltar da tela de peças pela seta mantém o que foi marcado',
        (tester) async {
      tabela = [sofa3];
      await pronto(tester);
      await abrirPecas(tester);
      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'cartao_0_higienizar');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(textoDe(tester, 'resumo_valor'), 'R\$ 200,00');
      // reabrir mostra o que já estava marcado
      await abrirPecas(tester);
      expect(textoDe(tester, 'selo_familia_sofa'), '×1');
    });

    testWidgets('rodapé fixo: total, detalhes e salvar sem rolar',
        (tester) async {
      tabela = [sofa3];
      await pronto(tester);
      await abrirPecas(tester);

      // o rodapé não rola com a tela de peças
      expect(
          find.descendant(
              of: find.byType(Scrollable),
              matching: find.byKey(const Key('pecas_pronto'))),
          findsNothing);
      expect(tester.getRect(find.byKey(const Key('pecas_pronto'))).bottom,
          lessThanOrEqualTo(2400));

      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'cartao_0_higienizar');
      expect(textoDe(tester, 'total_a_cobrar'), 'R\$ 200,00');

      await tocar(tester, 'ver_detalhes');
      expect(textoDe(tester, 'linha_total_0_servico'),
          'Higienização sofá 3 lugares');
      expect(textoDe(tester, 'linha_total_0_legenda'), '1 × R\$ 200,00');
      expect(textoDe(tester, 'linha_total_0_valor'), 'R\$ 200,00');

      await fecharPecas(tester);
      final gravado = await salvarECapturar(tester);
      expect(gravado.valor, 200);
      expect(gravado.pecas.single.variante, '3');
      expect(gravado.pecas.single.servicos.single.valor, 200);
    });

    testWidgets('valor mudado prevalece; usar o calculado volta ao total',
        (tester) async {
      tabela = [poltrona];
      await pronto(tester);
      await abrirPecas(tester);
      await tocar(tester, 'familia_poltrona');
      await tocar(tester, 'cartao_0_higienizar');
      expect(textoDe(tester, 'total_a_cobrar'), 'R\$ 90,00');

      await tocar(tester, 'mudar_valor');
      await tester.pumpAndSettle();
      expect(textoDoCampo(tester, 'campo_valor'), '90,00');
      await digitar(tester, 'campo_valor', '80');
      await tocar(tester, 'confirmar_valor');
      await tester.pumpAndSettle();

      await tocar(tester, 'cartao_0_mais');
      expect(textoDe(tester, 'total_a_cobrar'), 'R\$ 80,00');
      expect(textoDe(tester, 'total_calculado'), 'calculado R\$ 180,00');

      await tocar(tester, 'usar_calculado');
      expect(textoDe(tester, 'total_a_cobrar'), 'R\$ 180,00');
      expect(find.byKey(const Key('usar_calculado')), findsNothing);

      await fecharPecas(tester);
      final gravado = await salvarECapturar(tester);
      expect(gravado.valor, 180);
      verifyNever(() => service.updatePreco(any()));
      verifyNever(() => service.addPreco(any()));
    });

    testWidgets('serviço sem valor aparece no aviso do rodapé', (tester) async {
      tabela = [sofa3];
      await pronto(tester);
      await abrirPecas(tester);
      await tocar(tester, 'familia_sofa');
      await tocar(tester, 'cartao_0_higienizar');
      await tocar(tester, 'cartao_0_mais_lugares');

      expect(textoDe(tester, 'aviso_sem_valor'),
          contains('Higienização sofá 4 lugares'));
      expect(textoDe(tester, 'total_a_cobrar'), 'sem valor');
    });

    testWidgets('atendimento da versão anterior abre e salva os mesmos preços',
        (tester) async {
      tabela = [sofa3]; // a tabela hoje cobra R$ 200
      final existente = Atendimento(
        id: 'a1',
        data: dia,
        periodo: Periodo.manha,
        clienteId: '1',
        pecas: [
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
        ],
        valor: 180,
      );
      when(() => service.updateAtendimento(any())).thenAnswer((_) async {});
      await bombear(tester, atendimento: existente);

      expect(textoDe(tester, 'resumo_valor'), 'R\$ 180,00');

      await tocar(tester, 'botao_salvar');
      await tester.pump();
      final gravado =
          verify(() => service.updateAtendimento(captureAny())).captured.single
              as Atendimento;
      expect(gravado.valor, 180);
      expect(gravado.pecas.single.servicos.map((s) => s.nome),
          ['Higienização sofá 3 lugares', 'Remoção de odor']);
      expect(gravado.pecas.single.servicos.first.valor, 180);
    });
  });
}

String textoDe(WidgetTester tester, String chave) =>
    tester.widget<Text>(find.byKey(Key(chave))).data!;
