import 'package:flutter/material.dart';

import '../models/item_de_preco.dart';
import '../models/peca.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/agenda.dart';
import '../utils/calculo.dart';

// Seletor de peças e serviços (RF-013, issue #134). Reutilizável: o
// atendimento (RF-005) usa agora e o orçamento (RF-017) vai usar o mesmo.
//
// Três passos, de cima para baixo: a família da peça em quadros grandes (com
// selo ×N), o ajuste da peça por − / + (sem digitar) e, em cada peça, os
// serviços Higienizar e Impermeabilizar — independentes, marcáveis juntos
// (combo) ou só um. O preço sai da tabela pela peça + variante + serviço e é
// copiado na peça: mudar a tabela depois não muda o que foi registrado.
//
// Não rola sozinho: vive dentro do formulário de quem o usa. Cada mudança
// devolve a lista inteira de peças por [aoMudar].
class SeletorDePecas extends StatefulWidget {
  const SeletorDePecas({
    super.key,
    required this.pecas,
    required this.tabela,
    required this.aoMudar,
  });

  // Peças iniciais (atendimento em edição); lidas uma vez, ao abrir.
  final List<Peca> pecas;
  final List<ItemDePreco> tabela;
  final ValueChanged<List<Peca>> aoMudar;

  @override
  State<SeletorDePecas> createState() => _SeletorDePecasState();
}

// Ícone e cores de cada família (design-system.md 2.5).
({IconData icone, Color cor, Color fundo}) visualDaFamilia(Familia f) =>
    switch (f) {
      Familia.sofa => (
          icone: Icons.weekend_outlined,
          cor: AppColors.sofa,
          fundo: AppColors.sofaFundo
        ),
      Familia.tapete => (
          icone: Icons.texture,
          cor: AppColors.tapete,
          fundo: AppColors.tapeteFundo
        ),
      Familia.poltrona => (
          icone: Icons.chair_outlined,
          cor: AppColors.poltrona,
          fundo: AppColors.poltronaFundo
        ),
      Familia.cortina => (
          icone: Icons.curtains_outlined,
          cor: AppColors.cortina,
          fundo: AppColors.cortinaFundo
        ),
      Familia.colchao => (
          icone: Icons.bed_outlined,
          cor: AppColors.colchao,
          fundo: AppColors.colchaoFundo
        ),
      Familia.cadeira => (
          icone: Icons.chair_alt_outlined,
          cor: AppColors.cadeira,
          fundo: AppColors.cadeiraFundo
        ),
      Familia.outros => (
          icone: Icons.more_horiz,
          cor: AppColors.tintaFraca,
          fundo: AppColors.fundo
        ),
    };

// Item avulso no cartão Outros: os serviços (um da tabela, ou os de uma peça
// "outro" gravada antes) e a quantidade.
class _Avulso {
  _Avulso(this.rotulo, this.itens, this.quantidade);

  final String rotulo;
  final List<ItemDePreco> itens;
  int quantidade;
}

// Uma peça em edição (no colchão, a grade inteira; em Outros, os avulsos).
class _Cartao {
  _Cartao(this.familia);

  final Familia familia;
  String? variante;
  bool retratil = false;
  int quantidade = 1;
  double? largura;
  double? comprimento;
  // Serviços marcados, com o preço copiado.
  final Map<TipoDeServico, ItemDePreco> marcados = {};
  // Serviços sem tipo presos à peça (gravados antes da #134): seguem juntos.
  final List<ItemDePreco> outros = [];
  // Colchão: quantidade por tamanho (nulo = gravado sem tamanho) e as cópias
  // de preço por tamanho e serviço.
  final Map<String?, int> tamanhos = {};
  final Map<String, ItemDePreco> copiasColchao = {};
  // Outros: os avulsos.
  final List<_Avulso> avulsos = [];

  int get selo => switch (familia) {
        Familia.colchao => tamanhos.values.fold(0, (a, b) => a + b),
        Familia.outros => avulsos.fold(0, (a, b) => a + b.quantidade),
        Familia.sofa || Familia.tapete => 1,
        _ => quantidade,
      };
}

class _SeletorDePecasState extends State<SeletorDePecas> {
  late final List<_Cartao> _cartoes = _abrir(widget.pecas);

  // ---- peças ⇄ cartões ----

  static List<_Cartao> _abrir(List<Peca> pecas) {
    final cartoes = <_Cartao>[];
    _Cartao? colchao;
    _Cartao? outros;
    for (final p in pecas) {
      final f = Familia.deTipo(p.tipo);
      if (f == Familia.colchao) {
        final c = colchao ??= _Cartao(f);
        c.tamanhos[p.variante] = (c.tamanhos[p.variante] ?? 0) + p.quantidade;
        for (final s in p.servicos) {
          if (s.servico == null) {
            c.outros.add(s);
          } else {
            c.marcados[s.servico!] = s;
            c.copiasColchao['${p.variante}|${s.servico!.codigo}'] = s;
          }
        }
        continue;
      }
      if (f == Familia.outros) {
        final c = outros ??= _Cartao(f);
        c.avulsos.add(_Avulso(
            p.servicos.isEmpty ? 'outro' : p.servicos.first.nome,
            [...p.servicos],
            p.quantidade));
        continue;
      }
      final c = _Cartao(f)
        ..variante = p.variante
        ..retratil = p.retratil
        ..quantidade = p.quantidade
        ..largura = p.largura
        ..comprimento = p.comprimento;
      for (final s in p.servicos) {
        if (s.servico != null && !c.marcados.containsKey(s.servico)) {
          c.marcados[s.servico!] = s;
        } else {
          c.outros.add(s);
        }
      }
      cartoes.add(c);
    }
    if (colchao != null) cartoes.add(colchao);
    if (outros != null) cartoes.add(outros);
    _ordenar(cartoes);
    return cartoes;
  }

  // Na ordem das famílias; dentro da família, na ordem em que entraram.
  static void _ordenar(List<_Cartao> cartoes) {
    final ordem = {for (var i = 0; i < cartoes.length; i++) cartoes[i]: i};
    cartoes.sort((a, b) {
      final f = a.familia.index.compareTo(b.familia.index);
      return f != 0 ? f : ordem[a]!.compareTo(ordem[b]!);
    });
  }

  List<Peca> _pecas() {
    final pecas = <Peca>[];
    for (final c in _cartoes) {
      switch (c.familia) {
        case Familia.colchao:
          var primeiro = true;
          for (final e in c.tamanhos.entries) {
            if (e.value <= 0) continue;
            pecas.add(Peca(
              tipo: c.familia.tipo,
              quantidade: e.value,
              variante: e.key,
              servicos: [
                for (final t in TipoDeServico.values)
                  if (c.marcados.containsKey(t)) _copiaColchao(c, e.key, t),
                if (primeiro) ...c.outros,
              ],
            ));
            primeiro = false;
          }
        case Familia.outros:
          for (final a in c.avulsos) {
            if (a.quantidade <= 0) continue;
            pecas.add(Peca(
                tipo: c.familia.tipo,
                quantidade: a.quantidade,
                servicos: [...a.itens]));
          }
        default:
          final medido = c.familia == Familia.tapete;
          pecas.add(Peca(
            tipo: c.familia.tipo,
            quantidade: c.quantidade,
            variante: c.variante,
            retratil: c.retratil,
            largura: medido ? c.largura : null,
            comprimento: medido ? c.comprimento : null,
            servicos: [
              for (final t in TipoDeServico.values)
                if (c.marcados[t] != null) c.marcados[t]!,
              ...c.outros,
            ],
          ));
      }
    }
    return pecas;
  }

  ItemDePreco _copiaColchao(_Cartao c, String? tamanho, TipoDeServico t) =>
      c.copiasColchao.putIfAbsent('$tamanho|${t.codigo}',
          () => precoDoServico(widget.tabela, Familia.colchao, tamanho, false, t));

  void _mudou(VoidCallback mudanca) {
    setState(mudanca);
    widget.aoMudar(_pecas());
  }

  // Lugares, tamanho ou retrátil mudaram: os serviços marcados trocam de preço.
  void _reprecificar(_Cartao c) {
    for (final t in [...c.marcados.keys]) {
      c.marcados[t] =
          precoDoServico(widget.tabela, c.familia, c.variante, c.retratil, t);
    }
  }

  // ---- ações ----

  void _tocarFamilia(Familia f) => _mudou(() {
        final existente = _cartoes.where((c) => c.familia == f).firstOrNull;
        switch (f) {
          case Familia.sofa || Familia.tapete:
            _novo(f);
          case Familia.colchao || Familia.outros:
            if (existente == null) _novo(f);
          default:
            if (existente == null) {
              _novo(f);
            } else {
              existente.quantidade++;
            }
        }
      });

  void _novo(Familia f) {
    final c = _Cartao(f);
    if (f == Familia.sofa) c.variante = '3';
    _cartoes.add(c);
    _ordenar(_cartoes);
  }

  void _alternar(_Cartao c, TipoDeServico t) => _mudou(() {
        if (c.marcados.containsKey(t)) {
          c.marcados.remove(t);
          c.copiasColchao.removeWhere((k, _) => k.endsWith('|${t.codigo}'));
        } else {
          c.marcados[t] =
              precoDoServico(widget.tabela, c.familia, c.variante, c.retratil, t);
        }
      });

  void _trocarVariante(_Cartao c, int passo) {
    final vs = c.familia.variantes;
    final i = c.variante == null ? -1 : vs.indexOf(c.variante!);
    final novo = (i + passo).clamp(0, vs.length - 1);
    if (i == novo) return;
    _mudou(() {
      c.variante = vs[novo];
      _reprecificar(c);
    });
  }

  // Medida do tapete, de 0,5 em 0,5 m; abaixo de 0,5 fica sem medida.
  double? _medir(double? atual, int passo) {
    final novo = (atual ?? 0) + passo * 0.5;
    return novo < 0.5 ? null : novo;
  }

  // ---- tela ----

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[_quadros(context)];
    for (var i = 0; i < _cartoes.length; i++) {
      final c = _cartoes[i];
      widgets.add(_cartao(context, i, c));
      final ultimoDaFamilia =
          i == _cartoes.length - 1 || _cartoes[i + 1].familia != c.familia;
      if (ultimoDaFamilia && c.familia == Familia.sofa) {
        widgets.add(_porOutro('por_outro_sofa', 'Pôr outro sofá', Familia.sofa));
      }
      if (ultimoDaFamilia && c.familia == Familia.tapete) {
        widgets.add(
            _porOutro('por_outro_tapete', 'Pôr outro tapete', Familia.tapete));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _quadros(BuildContext context) {
    return LayoutBuilder(builder: (context, limites) {
      const colunas = 4;
      final largura =
          (limites.maxWidth - AppSpacing.sm * (colunas - 1)) / colunas;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final f in Familia.values)
            SizedBox(width: largura, child: _quadro(context, f)),
        ],
      );
    });
  }

  Widget _quadro(BuildContext context, Familia f) {
    final v = visualDaFamilia(f);
    final selo =
        _cartoes.where((c) => c.familia == f).fold(0, (a, c) => a + c.selo);
    final textos = Theme.of(context).textTheme;
    return Material(
      key: Key('familia_${f.name}'),
      color: selo > 0 ? v.fundo : AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medio),
        side: BorderSide(
            color: selo > 0 ? v.cor : AppColors.borda, width: selo > 0 ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medio),
        onTap: () => _tocarFamilia(f),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md, horizontal: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconeFamilia(familia: f),
                  const SizedBox(height: AppSpacing.xs),
                  Text(f.rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textos.labelLarge),
                ],
              ),
            ),
            if (selo > 0)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: v.cor,
                    borderRadius: BorderRadius.circular(AppRadius.pequeno),
                  ),
                  child: Text('×$selo',
                      key: Key('selo_familia_${f.name}'),
                      style: textos.labelSmall
                          ?.copyWith(color: AppColors.superficie)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _porOutro(String chave, String rotulo, Familia f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OutlinedButton.icon(
        key: Key(chave),
        onPressed: () => _mudou(() => _novo(f)),
        icon: const Icon(Icons.add),
        label: Text(rotulo),
      ),
    );
  }

  String _titulo(int i, _Cartao c) {
    final daFamilia = _cartoes.where((x) => x.familia == c.familia).toList();
    if (daFamilia.length < 2) return c.familia.rotulo;
    return '${c.familia.rotulo} ${daFamilia.indexOf(c) + 1}';
  }

  static String _legenda(Familia f) => switch (f) {
        Familia.sofa => 'quantos lugares',
        Familia.tapete => 'largura × comprimento',
        Familia.poltrona => 'quantas poltronas',
        Familia.cortina => 'quantas folhas',
        Familia.colchao => 'quantos de cada tamanho',
        Familia.cadeira => 'quantas cadeiras',
        Familia.outros => 'serviços avulsos da tabela',
      };

  Widget _cartao(BuildContext context, int i, _Cartao c) {
    final textos = Theme.of(context).textTheme;
    return Card(
      key: Key('cartao_$i'),
      margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _IconeFamilia(familia: c.familia),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_titulo(i, c), style: textos.titleMedium),
                      Text(_legenda(c.familia),
                          style: textos.bodySmall
                              ?.copyWith(color: AppColors.tintaFraca)),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('cartao_${i}_remover'),
                  tooltip: 'Tirar a peça',
                  icon: const Icon(Icons.close, color: AppColors.tintaFraca),
                  onPressed: () => _mudou(() => _cartoes.remove(c)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ..._ajuste(context, i, c),
            if (c.familia != Familia.outros) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (final t in TipoDeServico.values) ...[
                    if (t != TipoDeServico.values.first)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _botaoServico(context, i, c, t)),
                  ],
                ],
              ),
            ],
            if (c.outros.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final s in c.outros)
                    InputChip(
                      label: Text(s.nome),
                      onDeleted: () => _mudou(() => c.outros.remove(s)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _ajuste(BuildContext context, int i, _Cartao c) {
    final textos = Theme.of(context).textTheme;
    switch (c.familia) {
      case Familia.sofa:
        final v = c.variante;
        return [
          _linha(
            context,
            'Lugares',
            _Passos(
              chave: 'cartao_${i}_lugares',
              texto: v == null ? '—' : (v == 'canto' ? 'canto' : '$v lug.'),
              aoMenos: () => _trocarVariante(c, -1),
              aoMais: () => _trocarVariante(c, 1),
            ),
          ),
          _retratil(context, i, c),
        ];
      case Familia.poltrona:
        return [
          _linha(context, 'Quantidade', _quantidade(i, c)),
          _retratil(context, i, c),
        ];
      case Familia.cortina:
        return [_linha(context, 'Folhas', _quantidade(i, c))];
      case Familia.cadeira:
        return [_linha(context, 'Quantidade', _quantidade(i, c))];
      case Familia.tapete:
        final area = (c.largura ?? 0) * (c.comprimento ?? 0);
        return [
          _linha(
            context,
            'Largura',
            _Passos(
              chave: 'cartao_${i}_largura',
              texto: _metros(c.largura),
              aoMenos: () => _mudou(() => c.largura = _medir(c.largura, -1)),
              aoMais: () => _mudou(() => c.largura = _medir(c.largura, 1)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _linha(
            context,
            'Comprimento',
            _Passos(
              chave: 'cartao_${i}_comprimento',
              texto: _metros(c.comprimento),
              aoMenos: () =>
                  _mudou(() => c.comprimento = _medir(c.comprimento, -1)),
              aoMais: () =>
                  _mudou(() => c.comprimento = _medir(c.comprimento, 1)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              area > 0 ? '${_numero(area)} m²' : 'informe as medidas',
              key: Key('cartao_${i}_area'),
              style: area > 0
                  ? textos.titleMedium?.copyWith(
                      color: visualDaFamilia(c.familia).cor,
                      fontFeatures: AppTypography.digitosTabulares)
                  : textos.bodySmall?.copyWith(color: AppColors.tarde),
            ),
          ),
        ];
      case Familia.colchao:
        final tamanhos = [
          ...c.familia.variantes,
          // gravado antes sem tamanho: aparece enquanto tiver quantidade
          if ((c.tamanhos[null] ?? 0) > 0) null,
        ];
        return [
          LayoutBuilder(builder: (context, limites) {
            final largura = (limites.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in tamanhos)
                  SizedBox(
                    width: largura,
                    child: _tamanhoDeColchao(context, c, t),
                  ),
              ],
            );
          }),
        ];
      case Familia.outros:
        return _avulsos(context, c);
    }
  }

  Widget _tamanhoDeColchao(BuildContext context, _Cartao c, String? t) {
    final n = c.tamanhos[t] ?? 0;
    final rotulo = t == null
        ? 'Sem tamanho'
        : '${t[0].toUpperCase()}${t.substring(1)}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: n > 0 ? AppColors.colchaoFundo : AppColors.superficieAlt,
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
        border: Border.all(color: n > 0 ? AppColors.colchao : AppColors.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          _Passos(
            chave: 'colchao_${t}_quantidade',
            chaveMenos: 'colchao_${t}_menos',
            chaveMais: 'colchao_${t}_mais',
            texto: '$n',
            aoMenos: n == 0
                ? null
                : () => _mudou(() {
                      c.tamanhos[t] = n - 1;
                    }),
            aoMais: () => _mudou(() => c.tamanhos[t] = n + 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _avulsos(BuildContext context, _Cartao c) {
    final textos = Theme.of(context).textTheme;
    final daTabela = avulsos(widget.tabela);
    // os da tabela, na ordem dela, e os gravados que a tabela não tem mais
    final linhas = <_Avulso>[
      for (final item in daTabela)
        c.avulsos.where((a) => a.rotulo == item.nome).firstOrNull ??
            _Avulso(item.nome, [item.copia()], 0),
      for (final a in c.avulsos)
        if (!daTabela.any((item) => item.nome == a.rotulo)) a,
    ];
    if (linhas.isEmpty) {
      return [
        Text('Nenhum item avulso na tabela de preços.',
            style: textos.bodySmall?.copyWith(color: AppColors.tintaFraca)),
      ];
    }
    return [
      for (final a in linhas)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.rotulo, style: textos.bodyLarge),
                    Text(
                      _preco(a.itens.firstOrNull?.valor),
                      style:
                          textos.bodySmall?.copyWith(color: AppColors.tintaFraca),
                    ),
                  ],
                ),
              ),
              _Passos(
                chave: 'avulso_${a.rotulo}_quantidade',
                chaveMenos: 'avulso_${a.rotulo}_menos',
                chaveMais: 'avulso_${a.rotulo}_mais',
                texto: '${a.quantidade}',
                aoMenos: a.quantidade == 0
                    ? null
                    : () => _mudou(() => a.quantidade--),
                aoMais: () => _mudou(() {
                  if (!c.avulsos.contains(a)) c.avulsos.add(a);
                  a.quantidade++;
                }),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _quantidade(int i, _Cartao c) => _Passos(
        chave: 'cartao_${i}_quantidade',
        chaveMenos: 'cartao_${i}_menos',
        chaveMais: 'cartao_${i}_mais',
        texto: '${c.quantidade}',
        aoMenos: c.quantidade <= 1 ? null : () => _mudou(() => c.quantidade--),
        aoMais: () => _mudou(() => c.quantidade++),
      );

  Widget _retratil(BuildContext context, int i, _Cartao c) {
    return Row(
      children: [
        const Icon(Icons.open_in_full, size: AppSpacing.lg + AppSpacing.xs,
            color: AppColors.tintaFraca),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('Retrátil / reclinável',
              style: Theme.of(context).textTheme.bodyLarge),
        ),
        Switch(
          key: Key('cartao_${i}_retratil'),
          value: c.retratil,
          onChanged: (v) => _mudou(() {
            c.retratil = v;
            _reprecificar(c);
          }),
        ),
      ],
    );
  }

  Widget _linha(BuildContext context, String rotulo, Widget controle) {
    return Row(
      children: [
        Expanded(
          child: Text(rotulo, style: Theme.of(context).textTheme.bodyLarge),
        ),
        controle,
      ],
    );
  }

  // Botão de serviço: marca/desmarca e mostra o preço (o copiado, se
  // marcado; o da tabela, se não).
  Widget _botaoServico(
      BuildContext context, int i, _Cartao c, TipoDeServico t) {
    final textos = Theme.of(context).textTheme;
    final v = visualDaFamilia(c.familia);
    final marcado = c.marcados.containsKey(t);
    final String preco;
    if (c.familia == Familia.colchao) {
      preco = 'conforme o tamanho';
    } else {
      final item = c.marcados[t] ??
          precoDoServico(widget.tabela, c.familia, c.variante, c.retratil, t);
      preco = _preco(item.valor, m2: item.unidade == UnidadeDeCobranca.m2);
    }
    return Material(
      key: Key('cartao_${i}_${t.codigo}'),
      color: marcado ? v.fundo : AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
        side: BorderSide(
            color: marcado ? v.cor : AppColors.borda, width: marcado ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
        onTap: () => _alternar(c, t),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                marcado ? Icons.check_circle : Icons.radio_button_unchecked,
                color: marcado ? v.cor : AppColors.tintaFraca,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.rotulo, style: textos.titleSmall),
                    Text(
                      preco,
                      key: Key('cartao_${i}_${t.codigo}_preco'),
                      style: textos.bodySmall?.copyWith(
                          color: preco == 'sem valor'
                              ? AppColors.tarde
                              : AppColors.tintaFraca,
                          fontFeatures: AppTypography.digitosTabulares),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _preco(double? valor, {bool m2 = false}) {
    if (valor == null) return 'sem valor';
    return m2 ? '${valorEmReais(valor)}/m²' : valorEmReais(valor);
  }

  static String _metros(double? v) => v == null ? '—' : '${_numero(v)} m';

  static String _numero(double v) {
    final texto = v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return texto.replaceAll('.', ',');
  }
}

class _IconeFamilia extends StatelessWidget {
  const _IconeFamilia({required this.familia});

  final Familia familia;

  @override
  Widget build(BuildContext context) {
    final v = visualDaFamilia(familia);
    return Container(
      width: AppSpacing.xxl + AppSpacing.md,
      height: AppSpacing.xxl + AppSpacing.md,
      decoration: BoxDecoration(
        color: v.fundo,
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
      ),
      child: Icon(v.icone, color: v.cor),
    );
  }
}

// − valor +, com toques de 48 dp. Sem [aoMenos], o − fica desabilitado.
class _Passos extends StatelessWidget {
  const _Passos({
    required this.chave,
    required this.texto,
    required this.aoMais,
    this.aoMenos,
    this.chaveMenos,
    this.chaveMais,
  });

  // Chave do texto; as dos botões, se não vierem, são "<chave sem o fim>
  // menos/mais" (cartao_0_lugares → cartao_0_menos_lugares).
  final String chave;
  final String? chaveMenos;
  final String? chaveMais;
  final String texto;
  final VoidCallback? aoMenos;
  final VoidCallback aoMais;

  String _botao(String lado) {
    final i = chave.lastIndexOf('_');
    return '${chave.substring(0, i)}_${lado}_${chave.substring(i + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
        border: Border.all(color: AppColors.borda),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key(chaveMenos ?? _botao('menos')),
            tooltip: 'Menos',
            onPressed: aoMenos ?? () {},
            icon: Icon(Icons.remove,
                color: aoMenos == null
                    ? AppColors.tintaDesabilitada
                    : AppColors.primaria),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: AppSpacing.xxl * 2),
            child: Text(
              texto,
              key: Key(chave),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaria,
                  fontFeatures: AppTypography.digitosTabulares),
            ),
          ),
          IconButton(
            key: Key(chaveMais ?? _botao('mais')),
            tooltip: 'Mais',
            onPressed: aoMais,
            icon: const Icon(Icons.add, color: AppColors.primaria),
          ),
        ],
      ),
    );
  }
}
