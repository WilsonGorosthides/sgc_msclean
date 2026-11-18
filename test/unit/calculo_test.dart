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

    // CT-096 (#134): o preço casa peça + variante + retrátil + serviço.
    group('preço pela tabela:', () {
      const sofa3 = ItemDePreco(
          id: 's3',
          nome: 'Higienização sofá 3 lugares',
          unidade: UnidadeDeCobranca.peca,
          valor: 200,
          peca: Familia.sofa,
          variante: '3',
          servico: TipoDeServico.higienizar);
      const sofa3Retratil = ItemDePreco(
          id: 's3r',
          nome: 'Higienização sofá 3 lugares retrátil',
          unidade: UnidadeDeCobranca.peca,
          peca: Familia.sofa,
          variante: '3',
          servico: TipoDeServico.higienizar,
          retratil: true);
      const casal = ItemDePreco(
          id: 'cc',
          nome: 'Higienização colchão casal',
          unidade: UnidadeDeCobranca.peca,
          valor: 150,
          peca: Familia.colchao,
          variante: 'casal',
          servico: TipoDeServico.higienizar);
      const tapete = ItemDePreco(
          id: 'tp',
          nome: 'Higienização de tapete',
          unidade: UnidadeDeCobranca.m2,
          valor: 12,
          peca: Familia.tapete,
          servico: TipoDeServico.higienizar);
      const deslocamento = ItemDePreco(
          id: 'dl',
          nome: 'Deslocamento',
          unidade: UnidadeDeCobranca.peca,
          valor: 30);
      final tabela = [sofa3, sofa3Retratil, casal, tapete, deslocamento];

      test('linha da tabela por peça, variante, retrátil e serviço', () {
        final achado = precoDoServico(
            tabela, Familia.sofa, '3', false, TipoDeServico.higienizar);
        expect(achado.nome, 'Higienização sofá 3 lugares');
        expect(achado.valor, 200);
        expect(achado.servico, TipoDeServico.higienizar);
        expect(achado.id, isNull); // é cópia, não a linha

        expect(
            precoDoServico(
                    tabela, Familia.colchao, 'casal', false, TipoDeServico.higienizar)
                .valor,
            150);
        expect(
            precoDoServico(
                    tabela, Familia.tapete, null, false, TipoDeServico.higienizar)
                .unidade,
            UnidadeDeCobranca.m2);
        expect(avulsos(tabela).single.nome, 'Deslocamento');
      });

      test('sem linha, ou sem valor, fica sem valor; nunca outra variante', () {
        final quatro = precoDoServico(
            tabela, Familia.sofa, '4', false, TipoDeServico.higienizar);
        expect(quatro.valor, isNull);
        expect(quatro.nome, 'Higienização sofá 4 lugares');

        final retratil = precoDoServico(
            tabela, Familia.sofa, '3', true, TipoDeServico.higienizar);
        expect(retratil.valor, isNull);
        expect(retratil.nome, 'Higienização sofá 3 lugares retrátil');

        final imp = precoDoServico(
            tabela, Familia.sofa, '3', false, TipoDeServico.impermeabilizar);
        expect(imp.valor, isNull);
        expect(imp.nome, 'Impermeabilização sofá 3 lugares');
        expect(
            precoDoServico(tabela, Familia.tapete, null, false,
                    TipoDeServico.impermeabilizar)
                .unidade,
            UnidadeDeCobranca.m2);
      });

      test('linhas do total com legenda e valor', () {
        final linhas = linhasDoTotal([
          const Peca(
              tipo: 'colchão',
              quantidade: 2,
              variante: 'casal',
              servicos: [casal]),
          const Peca(
              tipo: 'tapete', largura: 2, comprimento: 3, servicos: [tapete]),
          Peca(tipo: 'sofá', variante: '4', servicos: [
            precoDoServico(
                tabela, Familia.sofa, '4', false, TipoDeServico.higienizar),
          ]),
        ]);

        expect(linhas.map((l) => l.servico), [
          'Higienização colchão casal',
          'Higienização de tapete',
          'Higienização sofá 4 lugares',
        ]);
        expect(linhas[0].legenda, '2 × R\$ 150,00');
        expect(linhas[0].valor, 300);
        expect(linhas[1].legenda, '6 m² × R\$ 12,00');
        expect(linhas[1].valor, 72);
        expect(linhas[2].legenda, 'sem valor na tabela');
        expect(linhas[2].valor, isNull);
      });
    });
  });
}
