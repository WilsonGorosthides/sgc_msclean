import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/screens/atendimento_form_screen.dart';
import 'package:sgc_msclean/screens/client_form_screen.dart';

import '../mocks/mock_supabase_client.dart';

// Fim das telas acima da barra de navegação do sistema (RNF-001, CT-071,
// issue #118). Do Android 15 em diante o app é desenhado por baixo da barra;
// no celular da usuária, o Salvar ficava coberto por ela.
void main() {
  const altura = 480.0; // baixa: obriga a rolar
  const barra = 48.0;

  Future<void> rolarAteOFim(WidgetTester tester, Widget tela) async {
    tester.view.physicalSize = const Size(400, altura);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: barra);
    tester.view.viewPadding = const FakeViewPadding(bottom: barra);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: tela));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await tester.pumpAndSettle();
  }

  void salvarAcimaDaBarra(WidgetTester tester) {
    final salvar = tester.getRect(find.byKey(const Key('botao_salvar')));
    expect(salvar.bottom, lessThanOrEqualTo(altura - barra));
  }

  group('barra_do_sistema_test:', () {
    testWidgets('formulário de atendimento termina acima da barra',
        (tester) async {
      await rolarAteOFim(
          tester,
          AtendimentoFormScreen(
            // o formulário lê a tabela de preços (RF-013, #124)
            service: _comTabelaVazia(MockSupabaseService()),
            data: DateTime(2026, 11, 17),
            clientes: const [],
          ));
      salvarAcimaDaBarra(tester);
    });

    testWidgets('formulário de cliente termina acima da barra',
        (tester) async {
      await rolarAteOFim(
          tester, ClientFormScreen(service: MockSupabaseService()));
      salvarAcimaDaBarra(tester);
    });
  });
}

MockSupabaseService _comTabelaVazia(MockSupabaseService service) {
  when(() => service.getPrecosStream())
      .thenAnswer((_) => Stream.value(const []));
  return service;
}
