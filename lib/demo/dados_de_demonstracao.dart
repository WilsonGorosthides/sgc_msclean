import '../models/atendimento.dart';
import '../models/client_model.dart';
import '../models/endereco.dart';
import '../models/familia.dart';
import '../models/item_de_preco.dart';
import '../models/peca.dart';
import '../utils/calculo.dart';

// Dados fictícios do modo demonstração (#139): clientes, uma semana de
// agenda e a tabela de preços, montados em volta de "hoje". Nenhum dado é de
// cliente de verdade: nomes inventados, ruas de exemplo e telefones
// "(67) 90000-...". Servem aos prints do README (repositório público).
class DadosDeDemonstracao {
  DadosDeDemonstracao._(this.clientes, this.atendimentos, this.precos);

  final List<ClientModel> clientes;
  final List<Atendimento> atendimentos;
  final List<ItemDePreco> precos;

  static DadosDeDemonstracao gerar(DateTime hoje) {
    final dia = DateTime(hoje.year, hoje.month, hoje.day);
    final precos = _precos();
    final clientes = _clientes();
    return DadosDeDemonstracao._(
      clientes,
      _atendimentos(dia, clientes, precos),
      precos,
    );
  }

  static List<ClientModel> _clientes() {
    ClientModel c(
      int n,
      String nome,
      String rua,
      String numero,
      String bairro, {
      String complemento = '',
    }) => ClientModel(
      id: 'demo-c$n',
      nome: nome,
      telefones: ['(67) 90000-${(1000 + n * 111).toString()}'],
      endereco: Endereco(
        logradouro: rua,
        numero: numero,
        bairro: bairro,
        complemento: complemento,
      ),
    );
    return [
      c(1, 'Ana Souza', 'Rua das Flores', '120', 'Centro'),
      c(
        2,
        'Bruno Lima',
        'Rua dos Ipês',
        '45',
        'Jardim Primavera',
        complemento: 'Bloco B, apto 302',
      ),
      c(3, 'Carla Dias', 'Avenida das Palmeiras', '980', 'Vila Nova'),
      c(4, 'Diego Martins', 'Rua do Sol', '33', 'Jardim das Acácias'),
      c(
        5,
        'Eva Costa',
        'Rua da Esperança',
        '701',
        'Bela Vista',
        complemento: 'Condomínio Recanto, casa 12',
      ),
      c(6, 'Fernanda Rocha', 'Rua das Hortênsias', '58', 'Centro'),
      c(7, 'Gustavo Alves', 'Rua dos Girassóis', '210', 'Vila Nova'),
      c(8, 'Helena Prado', 'Avenida Central', '1500', 'Jardim Primavera'),
    ];
  }

  // A tabela sugerida do app com valores de exemplo (os de partida do app de
  // referência), o acréscimo do retrátil e os três grupos.
  static List<ItemDePreco> _precos() {
    const valores = <String, double>{
      'Higienização sofá 2 lugares': 170,
      'Higienização sofá 3 lugares': 200,
      'Higienização sofá 4 lugares': 250,
      'Higienização sofá de canto': 300,
      'Impermeabilização sofá 2 lugares': 90,
      'Impermeabilização sofá 3 lugares': 90,
      'Impermeabilização sofá 4 lugares': 120,
      'Impermeabilização sofá de canto': 120,
      'Impermeabilizante sofá 2 lugares': 190,
      'Impermeabilizante sofá 3 lugares': 190,
      'Impermeabilizante sofá 4 lugares': 250,
      'Impermeabilizante sofá de canto': 250,
      'Higienização poltrona': 90,
      'Impermeabilização poltrona': 150,
      'Higienização cadeira': 30,
      'Impermeabilização cadeira': 50,
      'Higienização de tapete': 25,
      'Impermeabilização de tapete': 40,
      'Higienização de cortina': 60,
      'Higienização colchão solteiro': 110,
      'Higienização colchão casal': 160,
      'Higienização colchão queen': 180,
      'Higienização colchão king': 210,
      'Remoção de odor': 70,
      'Remoção de mancha': 50,
      'Deslocamento': 20,
      'Neutralizador de odor': 40,
      'Tira-manchas': 35,
      'Hidratante de couro': 60,
      'Segunda lavagem (sujeira pesada)': 80,
      'Excesso de pelo de pet': 40,
      'Tratamento de mofo': 90,
      'Urina com odor': 60,
    };
    final sugerida = ItemDePreco.listaSugerida();
    final itens = <ItemDePreco>[
      for (final i in sugerida)
        ItemDePreco(
          id: 'demo-p${i.ordem}',
          nome: i.nome,
          unidade: i.unidade,
          valor: valores[i.nome],
          ordem: i.ordem,
          peca: i.peca,
          variante: i.variante,
          servico: i.servico,
          retratil: i.retratil,
          categoria: i.categoria,
        ),
    ];
    // retrátil: + R$ 30 na higienização do sofá
    var ordem = itens.length;
    for (final v in Familia.sofa.variantes) {
      itens.add(
        ItemDePreco(
          id: 'demo-p$ordem',
          nome: nomeDoServico(Familia.sofa, v, true, TipoDeServico.higienizar),
          unidade: UnidadeDeCobranca.peca,
          valor: 30,
          ordem: ordem++,
          peca: Familia.sofa,
          variante: v,
          servico: TipoDeServico.higienizar,
          retratil: true,
        ),
      );
    }
    return itens;
  }

  static List<Atendimento> _atendimentos(
    DateTime hoje,
    List<ClientModel> clientes,
    List<ItemDePreco> precos,
  ) {
    const hig = TipoDeServico.higienizar;
    const imp = TipoDeServico.impermeabilizar;
    ItemDePreco avulso(String nome) =>
        precos.firstWhere((p) => p.nome == nome).copia();
    List<ItemDePreco> servicos(
      Familia f,
      String? v,
      List<TipoDeServico> ts, {
      bool retratil = false,
    }) => [
      for (final t in ts) ...[
        precoDoServico(precos, f, v, retratil, t),
        ...produtosDoServico(precos, f, v, t),
      ],
    ];
    Peca deslocamento() =>
        Peca(tipo: Familia.outros.tipo, servicos: [avulso('Deslocamento')]);

    // domingo da semana de hoje (a agenda começa no domingo)
    final domingo = hoje.subtract(Duration(days: hoje.weekday % 7));
    DateTime diaDaSemana(int n) =>
        DateTime(domingo.year, domingo.month, domingo.day + n);

    var n = 0;
    Atendimento at(
      DateTime data,
      Periodo periodo,
      int cliente,
      List<Peca> pecas, {
      String? hora,
    }) {
      n++;
      final passado = data.isBefore(hoje);
      // no passado: um pouco de tudo — concluído e feito sem pagamento (o
      // histórico já garante os dois, qualquer que seja o dia de hoje)
      final feito = passado;
      final pago = passado && n.isOdd;
      return Atendimento(
        id: 'demo-a$n',
        data: data,
        periodo: periodo,
        hora: hora,
        clienteId: clientes[cliente - 1].id!,
        local: clientes[cliente - 1].endereco.logradouro,
        pecas: pecas,
        valor: _valorCalculado(pecas),
        criadoEm: data.subtract(const Duration(days: 3)),
        feito: feito,
        pago: pago,
      );
    }

    return [
      // histórico: visitas antigas da Ana e da Carla (RF-011)
      at(hoje.subtract(const Duration(days: 180)), Periodo.manha, 1, [
        Peca(
          tipo: 'sofá',
          variante: '3',
          servicos: servicos(Familia.sofa, '3', [hig]),
        ),
      ]),
      at(hoje.subtract(const Duration(days: 95)), Periodo.tarde, 3, [
        Peca(
          tipo: 'colchão',
          variante: 'casal',
          servicos: servicos(Familia.colchao, 'casal', [hig]),
        ),
      ]),
      // a semana
      at(diaDaSemana(1), Periodo.manha, 2, [
        Peca(
          tipo: 'sofá',
          variante: '2',
          servicos: servicos(Familia.sofa, '2', [hig, imp]),
        ),
        deslocamento(),
      ], hora: '08:30'),
      at(diaDaSemana(1), Periodo.tarde, 4, [
        Peca(
          tipo: 'tapete',
          largura: 2,
          comprimento: 3,
          servicos: servicos(Familia.tapete, null, [hig]),
        ),
      ]),
      at(diaDaSemana(2), Periodo.manha, 5, [
        Peca(
          tipo: 'poltrona',
          quantidade: 2,
          servicos: servicos(Familia.poltrona, null, [hig]),
        ),
        Peca(
          tipo: 'cadeira',
          quantidade: 6,
          servicos: servicos(Familia.cadeira, null, [hig]),
        ),
        deslocamento(),
      ]),
      at(diaDaSemana(3), Periodo.manha, 1, [
        Peca(
          tipo: 'sofá',
          variante: '3',
          retratil: true,
          servicos: servicos(Familia.sofa, '3', [hig], retratil: true),
        ),
        deslocamento(),
      ], hora: '09:00'),
      at(diaDaSemana(3), Periodo.manha, 6, [
        Peca(
          tipo: 'colchão',
          variante: 'queen',
          servicos: servicos(Familia.colchao, 'queen', [hig]),
        ),
      ]),
      at(diaDaSemana(3), Periodo.tarde, 7, [
        Peca(
          tipo: 'sofá',
          variante: 'canto',
          servicos: servicos(Familia.sofa, 'canto', [hig, imp]),
        ),
        Peca(
          tipo: Familia.outros.tipo,
          servicos: [avulso('Excesso de pelo de pet')],
        ),
        deslocamento(),
      ], hora: '14:00'),
      at(diaDaSemana(4), Periodo.tarde, 8, [
        Peca(
          tipo: 'cortina',
          quantidade: 4,
          servicos: servicos(Familia.cortina, null, [hig]),
        ),
      ]),
      at(diaDaSemana(5), Periodo.manha, 3, [
        Peca(
          tipo: 'sofá',
          variante: '4',
          servicos: servicos(Familia.sofa, '4', [imp]),
        ),
        deslocamento(),
      ]),
      at(diaDaSemana(6), Periodo.manha, 2, [
        Peca(
          tipo: 'tapete',
          largura: 2.5,
          comprimento: 3.5,
          servicos: servicos(Familia.tapete, null, [hig, imp]),
        ),
      ], hora: '10:00'),
    ];
  }
}

// Valor a cobrar de exemplo: o calculado pela tabela.
double? _valorCalculado(List<Peca> pecas) {
  final c = calcularValor(pecas);
  return c.temValor ? c.total : null;
}
