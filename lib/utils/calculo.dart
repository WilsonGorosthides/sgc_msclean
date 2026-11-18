import '../models/familia.dart';
import '../models/item_de_preco.dart';
import '../models/peca.dart';
import 'agenda.dart';

// Valor do atendimento pela tabela de preços (RF-013, parte 2, issue #124).
// Funções puras: o formulário mostra o total enquanto ela informa as peças.

// Resultado da soma: o total e o que ficou de fora, para o aviso.
class CalculoDoValor {
  const CalculoDoValor({
    required this.total,
    this.semValor = const [],
    this.semMedida = const [],
    this.temServicos = false,
    this.temValor = false,
  });

  final double total;
  // Serviços escolhidos que ainda não têm valor na tabela.
  final List<String> semValor;
  // Serviços por m² numa peça sem largura ou comprimento.
  final List<String> semMedida;
  // Algum serviço foi escolhido.
  final bool temServicos;
  // Algum serviço entrou na soma.
  final bool temValor;
}

// Quanto um serviço da peça soma: por peça, valor × quantidade; por m²,
// largura × comprimento × valor do metro × quantidade. Nulo quando falta o
// valor ou, no m², uma medida.
double? subtotal(Peca peca, ItemDePreco servico) {
  final valor = servico.valor;
  if (valor == null) return null;
  if (servico.unidade == UnidadeDeCobranca.m2) {
    final area = peca.area;
    if (area == null) return null;
    return area * valor * peca.quantidade;
  }
  return valor * peca.quantidade;
}

CalculoDoValor calcularValor(List<Peca> pecas) {
  var total = 0.0;
  var temServicos = false;
  var temValor = false;
  final semValor = <String>[];
  final semMedida = <String>[];
  for (final peca in pecas) {
    for (final servico in peca.servicos) {
      temServicos = true;
      final parcela = subtotal(peca, servico);
      if (parcela != null) {
        total += parcela;
        temValor = true;
      } else if (servico.valor == null) {
        semValor.add(servico.nome);
      } else {
        semMedida.add(servico.nome);
      }
    }
  }
  return CalculoDoValor(
    total: total,
    semValor: semValor,
    semMedida: semMedida,
    temServicos: temServicos,
    temValor: temValor,
  );
}

// Preço de um serviço da peça (#134): a linha da tabela com a mesma peça,
// variante, retrátil e serviço, copiada para o registro. Sem essa linha, uma
// cópia sem valor com o nome da combinação — o total avisa, e nunca se usa o
// preço de outra variante.
ItemDePreco precoDoServico(List<ItemDePreco> tabela, Familia familia,
    String? variante, bool retratil, TipoDeServico servico) {
  for (final linha in tabela) {
    if (linha.peca == familia &&
        linha.servico == servico &&
        linha.variante == variante &&
        linha.retratil == retratil) {
      return linha.copia();
    }
  }
  return ItemDePreco(
    nome: nomeDoServico(familia, variante, retratil, servico),
    unidade: familia == Familia.tapete
        ? UnidadeDeCobranca.m2
        : UnidadeDeCobranca.peca,
    peca: familia,
    variante: variante,
    servico: servico,
    retratil: retratil,
  );
}

// Itens avulsos da tabela (sem peça), na ordem dela: quadro Outros.
List<ItemDePreco> avulsos(List<ItemDePreco> tabela) =>
    [for (final linha in tabela) if (linha.avulso) linha];

// Uma linha da lista detalhada do rodapé: serviço, legenda (a conta) e valor.
class LinhaDoTotal {
  const LinhaDoTotal(this.servico, this.legenda, this.valor);

  final String servico;
  final String legenda;
  final double? valor;
}

List<LinhaDoTotal> linhasDoTotal(List<Peca> pecas) => [
      for (final peca in pecas)
        for (final s in peca.servicos) _linha(peca, s),
    ];

LinhaDoTotal _linha(Peca peca, ItemDePreco servico) {
  final valor = subtotal(peca, servico);
  if (servico.valor == null) {
    return LinhaDoTotal(servico.nome, 'sem valor na tabela', null);
  }
  final preco = valorEmReais(servico.valor!);
  if (servico.unidade == UnidadeDeCobranca.m2) {
    final area = peca.area;
    if (area == null) return LinhaDoTotal(servico.nome, 'falta medida', null);
    final vezes = peca.quantidade > 1 ? '${peca.quantidade} × ' : '';
    return LinhaDoTotal(
        servico.nome, '$vezes${_numero(area)} m² × $preco', valor);
  }
  return LinhaDoTotal(servico.nome, '${peca.quantidade} × $preco', valor);
}

// 6.0 → "6"; 4.5 → "4,5".
String _numero(double v) {
  final texto = v == v.truncateToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return texto.replaceAll('.', ',');
}
