import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/familia.dart';
import 'package:sgc_msclean/models/item_de_preco.dart';

// Serviço da tabela de preços (RF-013, parte 1, issue #123). Roteiros CT-080,
// CT-084 e CT-085 em docs/casos-de-teste.md.
void main() {
  group('item_de_preco_test:', () {
    test('lê nome, unidade e valor; valor nulo é sem valor', () {
      final sofa = ItemDePreco.fromMap({
        'id': 'p1',
        'nome': 'Higienização sofá 3 lugares',
        'unidade': 'peca',
        'valor': 180,
        'ordem': 2,
        'criado_em': '2026-11-17T10:00:00Z',
      });
      final tapete = ItemDePreco.fromMap({
        'id': 'p2',
        'nome': 'Higienização de tapete',
        'unidade': 'm2',
        'valor': null,
        'ordem': 3,
      });

      expect(sofa.id, 'p1');
      expect(sofa.nome, 'Higienização sofá 3 lugares');
      expect(sofa.unidade, UnidadeDeCobranca.peca);
      expect(sofa.valor, 180.0);
      expect(sofa.semValor, isFalse);
      expect(sofa.ordem, 2);
      expect(tapete.unidade, UnidadeDeCobranca.m2);
      expect(tapete.valor, isNull);
      expect(tapete.semValor, isTrue);
    });

    test('unidade desconhecida vale peça; rótulos por peça e por m²', () {
      final item = ItemDePreco.fromMap({'id': 'p', 'nome': 'X', 'unidade': '?'});

      expect(item.unidade, UnidadeDeCobranca.peca);
      expect(item.ordem, 0);
      expect(UnidadeDeCobranca.peca.rotulo, 'por peça');
      expect(UnidadeDeCobranca.m2.rotulo, 'por m²');
    });

    test('toMap leva nome, unidade, valor e ordem, sem id nem criado_em', () {
      const item = ItemDePreco(
        id: 'p1',
        nome: 'Impermeabilização de tapete',
        unidade: UnidadeDeCobranca.m2,
        valor: 25.5,
        ordem: 4,
      );

      expect(item.toMap(), {
        'nome': 'Impermeabilização de tapete',
        'unidade': 'm2',
        'valor': 25.5,
        'ordem': 4,
        // sem peça, variante e serviço: item avulso (#134)
        'peca': null,
        'variante': null,
        'servico': null,
        'retratil': false,
      });
      expect(
          const ItemDePreco(nome: 'Odor', unidade: UnidadeDeCobranca.peca)
              .toMap()['valor'],
          isNull);
    });

    test('lista sugerida: higienização e impermeabilização separadas', () {
      final nomes = ItemDePreco.listaSugerida().map((i) => i.nome).toList();

      for (final peca in [
        'sofá 2 lugares',
        'sofá 3 lugares',
        'sofá 4 lugares',
        'sofá de canto',
        'poltrona',
        'cadeira',
        'tapete',
      ]) {
        // as linhas de retrátil (#134) ficam de fora desta conta
        bool comum(String n) => n.contains(peca) && !n.contains('retrátil');
        expect(nomes.where((n) => n.startsWith('Higienização') && comum(n)),
            hasLength(1), reason: 'higienização de $peca');
        expect(nomes.where((n) => n.startsWith('Impermeabilização') && comum(n)),
            hasLength(1),
            reason: 'impermeabilização de $peca');
      }
      expect(nomes.where((n) => n.toLowerCase().contains('extra')), isEmpty);
      expect(nomes.where((n) => n.toLowerCase().contains('colchão')).length,
          greaterThanOrEqualTo(3));
      for (final outro in ['cortina', 'odor', 'mancha', 'deslocamento']) {
        expect(nomes.any((n) => n.toLowerCase().contains(outro)), isTrue,
            reason: outro);
      }
    });

    // CT-100 (#134): colunas de peça, variante, serviço e retrátil.
    test('colunas peca, variante, servico e retratil vão e voltam', () {
      final item = ItemDePreco.fromMap({
        'id': 'p7',
        'nome': 'Impermeabilização sofá 4 lugares retrátil',
        'unidade': 'peca',
        'valor': 260,
        'ordem': 9,
        'peca': 'sofa',
        'variante': '4',
        'servico': 'impermeabilizar',
        'retratil': true,
      });

      expect(item.peca, Familia.sofa);
      expect(item.variante, '4');
      expect(item.servico, TipoDeServico.impermeabilizar);
      expect(item.retratil, isTrue);
      expect(item.toMap(), {
        'nome': 'Impermeabilização sofá 4 lugares retrátil',
        'unidade': 'peca',
        'valor': 260.0,
        'ordem': 9,
        'peca': 'sofa',
        'variante': '4',
        'servico': 'impermeabilizar',
        'retratil': true,
      });

      final avulso = ItemDePreco.fromMap(
          {'nome': 'Deslocamento', 'unidade': 'peca', 'peca': '?'});
      expect(avulso.peca, isNull);
      expect(avulso.servico, isNull);
      expect(avulso.retratil, isFalse);
    });

    test('lista sugerida com peça, variante e serviço; retrátil sem valor',
        () {
      final lista = ItemDePreco.listaSugerida();
      ItemDePreco? achar(Familia f, String? v, TipoDeServico s,
              {bool retratil = false}) =>
          lista
              .where((i) =>
                  i.peca == f &&
                  i.variante == v &&
                  i.servico == s &&
                  i.retratil == retratil)
              .firstOrNull;

      for (final v in ['2', '3', '4', 'canto']) {
        for (final s in TipoDeServico.values) {
          expect(achar(Familia.sofa, v, s), isNotNull, reason: 'sofá $v $s');
          expect(achar(Familia.sofa, v, s, retratil: true), isNotNull,
              reason: 'sofá $v $s retrátil');
        }
      }
      expect(achar(Familia.sofa, '3', TipoDeServico.higienizar)!.nome,
          'Higienização sofá 3 lugares');
      expect(
          achar(Familia.sofa, 'canto', TipoDeServico.impermeabilizar,
                  retratil: true)!
              .nome,
          'Impermeabilização sofá de canto retrátil');
      expect(achar(Familia.poltrona, null, TipoDeServico.impermeabilizar,
              retratil: true),
          isNotNull);
      for (final t in ['solteiro', 'casal', 'queen', 'king']) {
        expect(achar(Familia.colchao, t, TipoDeServico.higienizar), isNotNull,
            reason: t);
      }
      expect(achar(Familia.tapete, null, TipoDeServico.impermeabilizar)!.unidade,
          UnidadeDeCobranca.m2);
      // cortina por folha (decisão de 2026-11-17)
      expect(achar(Familia.cortina, null, TipoDeServico.higienizar)!.unidade,
          UnidadeDeCobranca.peca);
      // avulsos: sem peça nem serviço
      final avulsos = lista.where((i) => i.peca == null).map((i) => i.nome);
      expect(avulsos, containsAll(['Remoção de odor', 'Deslocamento']));
      expect(lista.where((i) => i.peca == null && i.servico != null), isEmpty);
      expect(lista.where((i) => i.retratil).every((i) => i.valor == null),
          isTrue);
    });

    test('lista sugerida vem sem valor, com ordem crescente e tapete por m²',
        () {
      final lista = ItemDePreco.listaSugerida();

      expect(lista.every((i) => i.valor == null && i.id == null), isTrue);
      expect([for (final i in lista) i.ordem],
          [for (var k = 0; k < lista.length; k++) k]);
      expect(
          lista
              .where((i) => i.nome.contains('tapete'))
              .every((i) => i.unidade == UnidadeDeCobranca.m2),
          isTrue);
      expect(
          lista
              .where((i) => i.nome.contains('sofá'))
              .every((i) => i.unidade == UnidadeDeCobranca.peca),
          isTrue);
    });
  });
}
