import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/demo/dados_de_demonstracao.dart';
import 'package:sgc_msclean/demo/servico_de_demonstracao.dart';
import 'package:sgc_msclean/main.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/item_de_preco.dart';
import 'package:sgc_msclean/screens/agenda_screen.dart';

// Modo demonstração (#139): o app com dados fictícios em memória, para os
// prints do README sem expor clientes reais nem gravar no banco dela.
// O Supabase não é inicializado nestes testes: qualquer acesso ao banco
// quebraria o teste.
void main() {
  // quarta-feira: a semana vai de domingo 08/11 a sábado 14/11
  final hoje = DateTime(2026, 11, 11);

  group('modo_demonstracao_test:', () {
    test('dados fictícios: semana cheia, tabela com os três grupos', () {
      final dados = DadosDeDemonstracao.gerar(hoje);

      // de segunda a sábado da semana de hoje, ao menos um atendimento
      for (var d = 9; d <= 14; d++) {
        expect(dados.atendimentos.where((a) => a.data == DateTime(2026, 11, d)),
            isNotEmpty,
            reason: 'dia $d');
      }
      // todos os atendimentos apontam para um cliente da demonstração
      final ids = dados.clientes.map((c) => c.id).toSet();
      expect(dados.atendimentos.every((a) => ids.contains(a.clienteId)), isTrue);
      // telefones de exemplo, nunca de alguém de verdade
      for (final c in dados.clientes) {
        for (final t in c.telefones) {
          expect(t, startsWith('(67) 90000-'), reason: c.nome);
        }
      }
      // tabela com produto, mão de obra e imprevisto, e o impermeabilizante
      // que vem junto com a impermeabilização do sofá
      expect(dados.precos.map((p) => p.categoria).toSet(),
          Categoria.values.toSet());
      expect(
          dados.precos.where((p) =>
              p.produtoDoServico && p.peca == Familia.sofa),
          isNotEmpty);
      // há atendimento feito, pago e concluído para a agenda mostrar
      expect(dados.atendimentos.any((a) => a.concluido), isTrue);
      expect(dados.atendimentos.any((a) => a.feito && !a.pago), isTrue);
    });

    test('as ações ficam em memória, sem banco', () async {
      final servico = ServicoDeDemonstracao(hoje: hoje);
      final primeiro = (await servico.getAtendimentosStream().first).first;

      await servico.marcarConclusao(primeiro.id!, feito: true, pago: true);
      final depois = await servico.getAtendimentosStream().first;
      expect(depois.firstWhere((a) => a.id == primeiro.id).concluido, isTrue);

      final antes = depois.length;
      await servico.addAtendimento(Atendimento(
          data: hoje, periodo: Periodo.tarde, clienteId: primeiro.clienteId));
      expect((await servico.getAtendimentosStream().first).length, antes + 1);

      final novo = await servico.addClienteProvisorio('Cliente de exemplo');
      expect(novo.id, isNotNull);
      expect((await servico.getClientsStream().first).map((c) => c.nome),
          contains('Cliente de exemplo'));

      const item = ItemDePreco(nome: 'Item de exemplo', unidade: UnidadeDeCobranca.peca);
      await servico.addPreco(item);
      expect((await servico.getPrecosStream().first).map((p) => p.nome),
          contains('Item de exemplo'));
      expect(servico.conectado.value, isTrue);
    });

    testWidgets('abre a agenda com os clientes fictícios, sem o banco',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MyApp(inicio: telaDeDemonstracao(hoje: hoje)));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AgendaScreen), findsOneWidget);
      final dados = DadosDeDemonstracao.gerar(hoje);
      final deHoje = dados.atendimentos.where((a) => a.data == hoje).first;
      final cliente =
          dados.clientes.firstWhere((c) => c.id == deHoje.clienteId);
      expect(find.textContaining(cliente.nome), findsWidgets);
    });
  });
}
