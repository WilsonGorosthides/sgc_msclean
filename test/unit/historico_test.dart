import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/peca.dart';
import 'package:sgc_msclean/utils/historico.dart';

// Histórico do cliente (RF-011, issue #81): funções puras, com o "hoje"
// injetado — roteiro em docs/casos-de-teste.md (CT-076 a CT-078).
void main() {
  final hoje = DateTime(2026, 11, 17);

  Atendimento at(String cliente, DateTime data, {double? valor}) =>
      Atendimento(
        data: data,
        periodo: Periodo.manha,
        clienteId: cliente,
        valor: valor,
        pecas: const [Peca(tipo: 'sofá')],
      );

  group('historico_test:', () {
    test('há quanto tempo, de hoje a anos', () {
      String antes(int dias) =>
          haQuantoTempo(DateTime(2026, 11, 17 - dias), hoje);
      expect(antes(0), 'hoje');
      expect(antes(1), 'ontem');
      expect(antes(5), 'há 5 dias');
      expect(antes(30), 'há 1 mês');
      expect(antes(95), 'há 3 meses');
      expect(antes(400), 'há 1 ano');
      expect(antes(800), 'há 2 anos');
      expect(dataCurta(DateTime(2026, 8, 12)), '12/08/26');
    });

    test('só os atendimentos do cliente até hoje, do mais recente ao mais antigo',
        () {
      final marco = at('7', DateTime(2026, 3, 10), valor: 250);
      final agosto = at('7', DateTime(2026, 8, 12));
      final hojeMesmo = at('7', hoje, valor: 90);
      final futuro = at('7', DateTime(2026, 11, 30), valor: 300);
      final outro = at('8', DateTime(2026, 9, 1), valor: 100);

      final historico =
          historicoDoCliente([marco, futuro, outro, hojeMesmo, agosto], '7', hoje);

      expect(historico, [hojeMesmo, agosto, marco]);
      expect(historicoDoCliente([outro], '7', hoje), isEmpty);
    });

    test('último valor é o do atendimento mais recente com valor', () {
      final marco = at('7', DateTime(2026, 3, 10), valor: 250);
      final agosto = at('7', DateTime(2026, 8, 12));
      final historico = historicoDoCliente([marco, agosto], '7', hoje);

      expect(ultimoComValor(historico), marco);
      expect(ultimoComValor([agosto]), isNull);
    });
  });
}
