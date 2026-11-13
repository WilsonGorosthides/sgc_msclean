import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/models/endereco.dart';
import 'package:sgc_msclean/models/peca.dart';
import 'package:sgc_msclean/screens/atendimento_form_screen.dart';

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
  });

  setUp(() {
    service = MockSupabaseService();
    when(() => service.addAtendimento(any())).thenAnswer((_) async {});
  });

  // [chave] distingue uma segunda montagem no mesmo teste: sem ela o Flutter
  // reaproveita o MaterialApp (e o Navigator já sem rota, após o pop).
  Future<void> bombear(WidgetTester tester,
      {Atendimento? atendimento, Key? chave}) async {
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
      ),
    ));
  }

  Future<void> tocar(WidgetTester tester, String chave) async {
    await tester.tap(find.byKey(Key(chave)));
    await tester.pump();
  }

  Future<void> digitar(WidgetTester tester, String chave, String texto) =>
      tester.enterText(find.byKey(Key(chave)), texto);

  String textoDoCampo(WidgetTester tester, String chave) =>
      tester.widget<TextFormField>(find.byKey(Key(chave))).controller!.text;

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

      await digitar(tester, 'campo_hora', '14:30');
      final gravado = await salvarECapturar(tester);
      expect(gravado.hora, '14:30');
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

    testWidgets('peças: tipo medido mostra as medidas; a lista é gravada',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_manha');

      await tocar(tester, 'adicionar_peca');
      // a primeira peça nasce como tapete (o serviço mais comum), que é medido
      expect(find.byKey(const Key('peca_0_largura')), findsOneWidget);
      expect(find.byKey(const Key('peca_0_comprimento')), findsOneWidget);
      await digitar(tester, 'peca_0_largura', '3');
      await digitar(tester, 'peca_0_comprimento', '2,5');

      await tocar(tester, 'adicionar_peca');
      await tocar(tester, 'peca_1_tipo_sofá');
      expect(find.byKey(const Key('peca_1_largura')), findsNothing);
      await digitar(tester, 'peca_1_quantidade', '2');

      final gravado = await salvarECapturar(tester);
      expect(gravado.pecas, hasLength(2));
      expect(gravado.pecas[0].tipo, 'tapete');
      expect(gravado.pecas[0].quantidade, 1);
      expect(gravado.pecas[0].largura, 3);
      expect(gravado.pecas[0].comprimento, 2.5);
      expect(gravado.pecas[1].tipo, 'sofá');
      expect(gravado.pecas[1].quantidade, 2);
      expect(gravado.pecas[1].largura, isNull);
    });

    testWidgets('remover peça tira a linha', (tester) async {
      await bombear(tester);
      await tocar(tester, 'adicionar_peca');
      await tocar(tester, 'adicionar_peca');
      expect(find.byKey(const Key('peca_1_quantidade')), findsOneWidget);

      await tocar(tester, 'remover_peca_1');

      expect(find.byKey(const Key('peca_1_quantidade')), findsNothing);
      expect(find.byKey(const Key('peca_0_quantidade')), findsOneWidget);
    });

    testWidgets('valor digitado com vírgula; campo vazio grava sem valor',
        (tester) async {
      await bombear(tester);
      await tocar(tester, 'escolher_cliente_1');
      await tocar(tester, 'escolher_manha');
      await digitar(tester, 'campo_valor', '180,50');

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
      expect(textoDoCampo(tester, 'campo_valor'), '120');
      expect(textoDoCampo(tester, 'peca_0_quantidade'), '2');

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
  });
}

String textoDe(WidgetTester tester, String chave) =>
    tester.widget<Text>(find.byKey(Key(chave))).data!;
