import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/models/item_de_preco.dart';
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

    test('lê feito e pago; ausentes valem falso', () {
      final base = {
        'id': 'abc',
        'data': '2026-11-11',
        'periodo': 'manha',
        'cliente_id': 'c1',
      };
      final semColunas = Atendimento.fromMap(base);
      expect(semColunas.feito, isFalse);
      expect(semColunas.pago, isFalse);

      final marcado = Atendimento.fromMap({...base, 'feito': true, 'pago': false});
      expect(marcado.feito, isTrue);
      expect(marcado.pago, isFalse);
    });

    test('concluído só com os dois marcados', () {
      Atendimento com(bool feito, bool pago) => Atendimento(
            data: DateTime(2026, 11, 11),
            periodo: Periodo.manha,
            clienteId: 'c1',
            feito: feito,
            pago: pago,
          );
      expect(com(false, false).concluido, isFalse);
      expect(com(true, false).concluido, isFalse);
      expect(com(false, true).concluido, isFalse);
      expect(com(true, true).concluido, isTrue);

      // copyWith troca só o que foi pedido
      final soFeito = com(false, true).copyWith(feito: true);
      expect(soFeito.feito, isTrue);
      expect(soFeito.pago, isTrue);
      expect(com(true, true).copyWith(pago: false).feito, isTrue);
    });

    test('toMap não leva feito nem pago', () {
      // as marcas têm escrita própria (marcarConclusao): salvar o formulário
      // não pode apagar uma marca feita na agenda
      final mapa = Atendimento(
        data: DateTime(2026, 11, 11),
        periodo: Periodo.manha,
        clienteId: 'c1',
        feito: true,
        pago: true,
      ).toMap();
      expect(mapa.containsKey('feito'), isFalse);
      expect(mapa.containsKey('pago'), isFalse);
    });

    test('período tem o rótulo exibido na agenda', () {
      expect(Periodo.manha.rotulo, 'Manhã');
      expect(Periodo.tarde.rotulo, 'Tarde');
    });

    test('toMap grava a linha do banco, sem id e sem criado_em', () {
      final a = Atendimento(
        id: 'abc',
        data: DateTime(2026, 11, 13),
        periodo: Periodo.tarde,
        hora: '14:30',
        clienteId: 'c1',
        local: 'Rua das Flores, 10',
        pecas: const [Peca(tipo: 'sofá', quantidade: 2)],
        valor: 360,
      );

      expect(a.toMap(), {
        'data': '2026-11-13',
        'periodo': 'tarde',
        'hora': '14:30',
        'cliente_id': 'c1',
        'local': 'Rua das Flores, 10',
        'pecas': [
          {'tipo': 'sofá', 'quantidade': 2},
        ],
        'valor': 360.0,
      });
    });

    test('toMap de atendimento mínimo grava hora e valor nulos', () {
      final a = Atendimento(
        data: DateTime(2026, 1, 5),
        periodo: Periodo.manha,
        clienteId: 'c1',
      );
      final mapa = a.toMap();

      expect(mapa['data'], '2026-01-05');
      expect(mapa['hora'], isNull);
      expect(mapa['valor'], isNull);
      expect(mapa['local'], '');
      expect(mapa['pecas'], isEmpty);
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

    test('toMap de peça medida leva as medidas; contada só a quantidade', () {
      expect(
        const Peca(tipo: 'tapete', largura: 3, comprimento: 2).toMap(),
        {'tipo': 'tapete', 'quantidade': 1, 'largura': 3.0, 'comprimento': 2.0},
      );
      expect(
        const Peca(tipo: 'sofá', quantidade: 2).toMap(),
        {'tipo': 'sofá', 'quantidade': 2},
      );
    });

    // CT-087 (RF-013, #124): o preço do serviço é copiado para a peça.
    test('serviços da peça vão ao jsonb com o preço copiado', () {
      const peca = Peca(tipo: 'sofá', servicos: [
        ItemDePreco(
            id: 'p9',
            nome: 'Impermeabilização sofá 3 lugares',
            unidade: UnidadeDeCobranca.peca,
            valor: 150,
            ordem: 7),
        ItemDePreco(nome: 'Remoção de odor', unidade: UnidadeDeCobranca.peca),
      ]);

      final mapa = peca.toMap();
      expect(mapa['servicos'], [
        {
          'nome': 'Impermeabilização sofá 3 lugares',
          'unidade': 'peca',
          'valor': 150.0,
        },
        {'nome': 'Remoção de odor', 'unidade': 'peca', 'valor': null},
      ]);

      final lida = Peca.fromMap(mapa);
      expect(lida.servicos.map((s) => s.nome),
          ['Impermeabilização sofá 3 lugares', 'Remoção de odor']);
      expect(lida.servicos.first.valor, 150.0);
      expect(lida.servicos.last.valor, isNull);
      expect(Peca.fromMap({'tipo': 'sofá'}).servicos, isEmpty);
    });

    // CT-102 (#134): o preço ajustado só no registro leva o da tabela e a
    // justificativa junto; sem ajuste, o jsonb não muda.
    test('ajuste do serviço vai ao jsonb com o preço da tabela e a justificativa',
        () {
      const tabela = ItemDePreco(
          nome: 'Higienização sofá 2 lugares',
          unidade: UnidadeDeCobranca.peca,
          valor: 170,
          servico: TipoDeServico.higienizar);
      final ajustado = tabela.ajustar(220, 'tecido linho');
      expect(ajustado.valor, 220);
      expect(ajustado.valorDaTabela, 170);
      expect(ajustado.justificativa, 'tecido linho');
      expect(ajustado.ajustado, isTrue);
      // ajustar de novo guarda o preço da tabela, não o ajuste anterior
      expect(ajustado.ajustar(200, null).valorDaTabela, 170);
      expect(ajustado.ajustar(200, '  ').justificativa, isNull);

      final mapa = Peca(tipo: 'sofá', servicos: [ajustado]).toMap();
      expect(mapa['servicos'], [
        {
          'nome': 'Higienização sofá 2 lugares',
          'unidade': 'peca',
          'valor': 220.0,
          'servico': 'higienizar',
          'ajustado': true,
          'valor_tabela': 170.0,
          'justificativa': 'tecido linho',
        },
      ]);
      final lido = Peca.fromMap(mapa).servicos.single;
      expect(lido.ajustado, isTrue);
      expect(lido.valor, 220);
      expect(lido.valorDaTabela, 170);
      expect(lido.justificativa, 'tecido linho');

      final volta = lido.semAjuste();
      expect(volta.valor, 170);
      expect(volta.ajustado, isFalse);
      expect(volta.justificativa, isNull);
      expect(
          (Peca(tipo: 'sofá', servicos: [volta]).toMap()['servicos'] as List)
              .single,
          {
            'nome': 'Higienização sofá 2 lugares',
            'unidade': 'peca',
            'valor': 170.0,
            'servico': 'higienizar',
          });
      // a linha da tabela de preços não leva nada do ajuste
      expect(ajustado.toMap().containsKey('ajustado'), isFalse);
    });

    // CT-094/CT-099 (#134): variante e retrátil na peça; serviço antigo
    // (sem a chave servico) reconhecido pelo nome.
    test('peça guarda variante e retrátil; serviço antigo reconhecido pelo nome',
        () {
      const peca = Peca(
          tipo: 'sofá',
          variante: '3',
          retratil: true,
          servicos: [
            ItemDePreco(
                nome: 'Higienização sofá 3 lugares retrátil',
                unidade: UnidadeDeCobranca.peca,
                valor: 230,
                servico: TipoDeServico.higienizar),
          ]);
      final mapa = peca.toMap();
      expect(mapa['variante'], '3');
      expect(mapa['retratil'], isTrue);
      expect((mapa['servicos'] as List).single['servico'], 'higienizar');
      expect(const Peca(tipo: 'sofá').toMap().containsKey('variante'), isFalse);
      expect(const Peca(tipo: 'sofá').toMap().containsKey('retratil'), isFalse);

      final lida = Peca.fromMap(mapa);
      expect(lida.variante, '3');
      expect(lida.retratil, isTrue);
      expect(lida.servicos.single.servico, TipoDeServico.higienizar);

      final antiga = Peca.fromMap({
        'tipo': 'sofá',
        'quantidade': 1,
        'servicos': [
          {'nome': 'Higienização sofá 3 lugares', 'unidade': 'peca', 'valor': 180},
          {
            'nome': 'Impermeabilização sofá 3 lugares',
            'unidade': 'peca',
            'valor': 150
          },
          {'nome': 'Remoção de odor', 'unidade': 'peca', 'valor': null},
        ],
      });
      expect(antiga.variante, isNull);
      expect(antiga.servicos.map((s) => s.servico), [
        TipoDeServico.higienizar,
        TipoDeServico.impermeabilizar,
        null,
      ]);
      expect(antiga.servicos.first.valor, 180);
    });

    // CT-105 (#134): o grupo de cada serviço vai ao registro; a mão de obra é
    // o padrão e fica sem a chave.
    test('grupo do serviço vai ao jsonb; sem a chave, mão de obra', () {
      const peca = Peca(tipo: 'sofá', variante: '3', servicos: [
        ItemDePreco(
            nome: 'Impermeabilização sofá 3 lugares',
            unidade: UnidadeDeCobranca.peca,
            valor: 90,
            servico: TipoDeServico.impermeabilizar),
        ItemDePreco(
            nome: 'Impermeabilizante sofá 3 lugares',
            unidade: UnidadeDeCobranca.peca,
            valor: 190,
            servico: TipoDeServico.impermeabilizar,
            categoria: Categoria.produto),
        ItemDePreco(
            nome: 'Segunda lavagem',
            unidade: UnidadeDeCobranca.peca,
            valor: 60,
            categoria: Categoria.imprevisto),
      ]);

      final servicos = peca.toMap()['servicos'] as List;
      expect((servicos[0] as Map).containsKey('categoria'), isFalse);
      expect((servicos[1] as Map)['categoria'], 'produto');
      expect((servicos[2] as Map)['categoria'], 'imprevisto');

      final lida = Peca.fromMap(peca.toMap());
      expect(lida.servicos.map((s) => s.categoria), [
        Categoria.maoDeObra,
        Categoria.produto,
        Categoria.imprevisto,
      ]);
      expect(lida.servicos[1].servico, TipoDeServico.impermeabilizar);
      // gravado antes, sem a chave: mão de obra
      final antiga = Peca.fromMap({
        'tipo': 'outro',
        'servicos': [
          {'nome': 'Deslocamento', 'unidade': 'peca', 'valor': 20},
        ],
      });
      expect(antiga.servicos.single.categoria, Categoria.maoDeObra);
    });

    test('resumo leva lugares, tamanho e retrátil', () {
      expect(const Peca(tipo: 'sofá', variante: '3').resumo, 'sofá 3 lugares');
      expect(const Peca(tipo: 'sofá', variante: 'canto', retratil: true).resumo,
          'sofá de canto retrátil');
      expect(const Peca(tipo: 'colchão', quantidade: 2, variante: 'casal').resumo,
          '2× colchão casal');
    });

    test('tapete é o tipo medido por metragem; os demais são contados', () {
      expect(Peca.tipos, [
        'tapete',
        'sofá',
        'poltrona',
        'cortina',
        'colchão',
        'cadeira',
        'outro'
      ]);
      expect(Peca.ehMedido('tapete'), isTrue);
      for (final t in Peca.tipos.where((t) => t != 'tapete')) {
        expect(Peca.ehMedido(t), isFalse, reason: t);
      }
    });
  });
}
