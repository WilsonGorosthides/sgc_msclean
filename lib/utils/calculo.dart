import '../models/item_de_preco.dart';
import '../models/peca.dart';
import 'texto.dart';

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

// Serviços oferecidos numa peça: os que citam o tipo dela no nome ("sofá" →
// os de sofá). "Outro", ou um tipo sem nenhum serviço na tabela, mostra todos.
List<ItemDePreco> servicosDoTipo(List<ItemDePreco> tabela, String tipo) {
  if (tipo == 'outro') return tabela;
  final termo = paraBusca(tipo);
  final doTipo = [
    for (final s in tabela)
      if (paraBusca(s.nome).contains(termo)) s,
  ];
  return doTipo.isEmpty ? tabela : doTipo;
}
