import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/item_de_preco.dart';
import 'package:sgc_msclean/models/peca.dart';
import 'package:sgc_msclean/utils/calculo.dart';

// Valor calculado pela tabela de preços (RF-013, parte 2, issue #124).
// Roteiros CT-087 a CT-090 em docs/casos-de-teste.md.
void main() {
  const tapeteM2 = ItemDePreco(
      nome: 'Higienização de tapete', unidade: UnidadeDeCobranca.m2, valor: 12);
  const poltrona = ItemDePreco(
      nome: 'Higienização poltrona', unidade: UnidadeDeCobranca.peca, valor: 90);
  const higSofa = ItemDePreco(
      nome: 'Higienização sofá 3 lugares',
      unidade: UnidadeDeCobranca.peca,
      valor: 180);
  const impSofa = ItemDePreco(
      nome: 'Impermeabilização sofá 3 lugares',
      unidade: UnidadeDeCobranca.peca,
      valor: 150);
  const odor =
      ItemDePreco(nome: 'Remoção de odor', unidade: UnidadeDeCobranca.peca);

  group('calculo_test:', () {
    test('por m²: largura × comprimento × valor do metro', () {
      const tapete = Peca(
          tipo: 'tapete', largura: 8, comprimento: 4.5, servicos: [tapeteM2]);
      const dois = Peca(
          tipo: 'tapete',
          quantidade: 2,
          largura: 8,
          comprimento: 4.5,
          servicos: [tapeteM2]);

      expect(tapete.area, 36);
      expect(subtotal(tapete, tapeteM2), 432);
      expect(calcularValor([tapete]).total, 432);
      expect(subtotal(dois, tapeteM2), 864);
    });

    test('por m² sem medida não soma e avisa que falta medida', () {
      const semComprimento =
          Peca(tipo: 'tapete', largura: 8, servicos: [tapeteM2]);

      final calculo = calcularValor([semComprimento]);

      expect(semComprimento.area, isNull);
      expect(subtotal(semComprimento, tapeteM2), isNull);
      expect(calculo.total, 0);
      expect(calculo.semMedida, ['Higienização de tapete']);
      expect(calculo.temValor, isFalse);
    });

    test('por peça: valor × quantidade', () {
      const duas =
          Peca(tipo: 'poltrona', quantidade: 2, servicos: [poltrona]);

      expect(subtotal(duas, poltrona), 180);
      expect(calcularValor([duas]).total, 180);
    });

    test('serviço sozinho ou combo: o total é a soma', () {
      const soImpermeabilizacao = Peca(tipo: 'sofá', servicos: [impSofa]);
      const combo = Peca(tipo: 'sofá', servicos: [higSofa, impSofa]);

      expect(calcularValor([soImpermeabilizacao]).total, 150);
      expect(calcularValor([combo]).total, 330);
      expect(calcularValor([combo, soImpermeabilizacao]).total, 480);
    });

    test('serviço sem valor não entra na soma e é avisado', () {
      const sofa = Peca(tipo: 'sofá', servicos: [higSofa, odor]);

      final calculo = calcularValor([sofa]);

      expect(subtotal(sofa, odor), isNull);
      expect(calculo.total, 180);
      expect(calculo.semValor, ['Remoção de odor']);
      expect(calculo.temValor, isTrue);
      expect(calculo.temServicos, isTrue);
      expect(calcularValor(const [Peca(tipo: 'sofá')]).temServicos, isFalse);
    });

    test('serviços da peça: os do tipo dela; outro ou sem par mostra todos', () {
      final tabela = [tapeteM2, poltrona, higSofa, impSofa, odor];

      expect(servicosDoTipo(tabela, 'sofá').map((s) => s.nome),
          ['Higienização sofá 3 lugares', 'Impermeabilização sofá 3 lugares']);
      expect(servicosDoTipo(tabela, 'tapete').single.nome,
          'Higienização de tapete');
      expect(servicosDoTipo(tabela, 'outro'), tabela);
      expect(servicosDoTipo(tabela, 'colchão'), tabela);
    });
  });
}
