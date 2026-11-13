import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/peca.dart';

// Testes unitários do modelo Atendimento e do value object Peca (RF-010):
// leitura da linha do banco e resumo legível das peças para o cartão da agenda.
void main() {
  group('atendimento_test:', () {
    test('lê a linha do banco', () {
      final a = Atendimento.fromMap({
        'id': 'abc',
        'data': '2026-11-11',
        'periodo': 'tarde',
        'hora': '14:30:00',
        'cliente_id': 'c1',
        'local': 'Rua das Flores, 10',
        'pecas': [
          {'tipo': 'sofá', 'quantidade': 2},
        ],
        'valor': 360,
        'criado_em': '2026-11-01T08:00:00+00:00',
      });

      expect(a.id, 'abc');
      expect(a.data, DateTime(2026, 11, 11));
      expect(a.periodo, Periodo.tarde);
      expect(a.hora, '14:30'); // o banco devolve HH:MM:SS; a agenda usa HH:MM
      expect(a.clienteId, 'c1');
      expect(a.local, 'Rua das Flores, 10');
      expect(a.pecas.single.tipo, 'sofá');
      expect(a.pecas.single.quantidade, 2);
      expect(a.valor, 360.0);
      expect(a.criadoEm, isNotNull);
    });

    test('campos opcionais ausentes viram vazio', () {
      final a = Atendimento.fromMap({
        'id': 'abc',
        'data': '2026-11-11',
        'periodo': 'manha',
        'cliente_id': 'c1',
      });

      expect(a.periodo, Periodo.manha);
      expect(a.hora, isNull);
      expect(a.local, '');
      expect(a.pecas, isEmpty);
      expect(a.valor, isNull);
    });

    test('período tem o rótulo exibido na agenda', () {
      expect(Periodo.manha.rotulo, 'Manhã');
      expect(Periodo.tarde.rotulo, 'Tarde');
    });
  });

  group('peca_test:', () {
    test('resumo de peça medida', () {
      expect(
        const Peca(tipo: 'tapete', largura: 8, comprimento: 4.5).resumo,
        'tapete 8 × 4,5',
      );
      expect(
        const Peca(tipo: 'tapete', quantidade: 2, largura: 3, comprimento: 2)
            .resumo,
        '2× tapete 3 × 2',
      );
    });

    test('resumo de peça contada', () {
      expect(const Peca(tipo: 'sofá', quantidade: 2).resumo, '2× sofá');
      expect(const Peca(tipo: 'poltrona').resumo, 'poltrona');
    });

    test('cortina conta folhas', () {
      expect(const Peca(tipo: 'cortina', quantidade: 6).resumo,
          '6 folhas de cortina');
      expect(const Peca(tipo: 'cortina').resumo, '1 folha de cortina');
    });

    test('lê o mapa do jsonb', () {
      final p = Peca.fromMap({
        'tipo': 'tapete',
        'quantidade': 1,
        'largura': 8,
        'comprimento': 4.5,
      });
      expect(p.largura, 8.0);
      expect(p.comprimento, 4.5);
    });
  });
}
