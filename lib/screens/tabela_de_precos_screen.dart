import 'package:flutter/material.dart';

import '../models/familia.dart';
import '../models/item_de_preco.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/agenda.dart';
import 'sem_conexao.dart';

// Regra da proprietária (RF-013): impermeabilização não é extra de
// higienização. Fica à vista no topo da tabela.
const dicaServicosIndependentes =
    'Cada serviço é independente: a impermeabilização é um serviço completo, '
    'não um extra da higienização. Para o combo, escolha os dois no '
    'atendimento (o valor soma) ou cadastre o combo como mais um serviço.';

// Tabela de preços (RF-013, parte 1, issue #123), aberta pela barra da
// agenda. Lista os serviços com unidade e valor; adicionar, editar e remover
// vão direto ao banco e a stream é renovada ao voltar (como na lista de
// clientes, issue #57).
class TabelaDePrecosScreen extends StatefulWidget {
  const TabelaDePrecosScreen({super.key, this.service});

  final SupabaseService? service;

  @override
  State<TabelaDePrecosScreen> createState() => _TabelaDePrecosScreenState();
}

class _TabelaDePrecosScreenState extends State<TabelaDePrecosScreen> {
  late final _service = widget.service ?? SupabaseService();
  late Stream<List<ItemDePreco>> _precos = _service.getPrecosStream();
  List<ItemDePreco> _carregados = const [];

  void _renovar() => setState(() => _precos = _service.getPrecosStream());

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // Grava e renova a lista; sem internet, avisa e não perde a tela.
  Future<void> _gravar(Future<void> Function() escrita, {String? sucesso}) async {
    try {
      await escrita();
      if (!mounted) return;
      _renovar();
      if (sucesso != null) _avisar(sucesso);
    } catch (_) {
      if (!mounted) return;
      _avisar('Não foi possível salvar. Confira a conexão e tente de novo.');
    }
  }

  Future<void> _editar([ItemDePreco? item]) async {
    final proximaOrdem = _carregados.isEmpty
        ? 0
        : _carregados.map((i) => i.ordem).reduce((a, b) => a > b ? a : b) + 1;
    final gravado = await showDialog<ItemDePreco>(
      context: context,
      builder: (_) => _EditorDePreco(item: item, ordem: proximaOrdem),
    );
    if (gravado == null || !mounted) return;
    await _gravar(() => item == null
        ? _service.addPreco(gravado)
        : _service.updatePreco(gravado));
  }

  Future<void> _remover(ItemDePreco item) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover serviço?'),
        content: Text('Tirar "${item.nome}" da tabela de preços?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alerta),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    await _gravar(() => _service.deletePreco(item.id!),
        sucesso: 'Serviço removido');
  }

  Future<void> _comecarComSugerida() =>
      _gravar(() => _service.addPrecos(ItemDePreco.listaSugerida()));

  @override
  Widget build(BuildContext context) {
    final fim = MediaQuery.paddingOf(context).bottom + AppSpacing.xxl * 3;
    return Scaffold(
      appBar: AppBar(title: const Text('Tabela de preços')),
      body: Column(
        children: [
          AvisoSemConexao(conectado: _service.conectado),
          Expanded(
            child: StreamBuilder<List<ItemDePreco>>(
              stream: _precos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final itens = snapshot.data ?? const <ItemDePreco>[];
                _carregados = itens;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, fim),
                  children: [
                    const _Dica(),
                    const SizedBox(height: AppSpacing.lg),
                    if (itens.isEmpty) ..._vazia(context),
                    for (final item in itens) _linha(context, item),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('novo_preco'),
        tooltip: 'Adicionar serviço',
        onPressed: _editar,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _vazia(BuildContext context) => [
        Text(
          'Nenhum serviço na tabela ainda.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Comece com uma lista de serviços comuns, sem valor, e complete '
          'os valores; ou adicione um por um.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.tintaFraca),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: FilledButton.icon(
            key: const Key('lista_sugerida'),
            onPressed: _comecarComSugerida,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Começar com a lista sugerida'),
          ),
        ),
      ];

  Widget _linha(BuildContext context, ItemDePreco item) {
    final textos = Theme.of(context).textTheme;
    return Card(
      key: Key('preco_${item.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(item.nome, style: textos.titleMedium),
        // a linha retrátil guarda só o acréscimo sobre a peça comum (#134)
        subtitle: Text(item.retratil
            ? 'acréscimo sobre o ${item.peca?.tipo ?? 'item'} comum'
            : item.unidade.rotulo),
        onTap: () => _editar(item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.semValor
                  ? 'sem valor'
                  : '${item.retratil ? '+ ' : ''}${valorEmReais(item.valor!)}',
              style: item.semValor
                  ? textos.bodyMedium?.copyWith(
                      color: AppColors.tarde, fontStyle: FontStyle.italic)
                  : textos.titleMedium,
            ),
            IconButton(
              key: Key('excluir_preco_${item.id}'),
              icon: const Icon(Icons.delete_outline, color: AppColors.alerta),
              tooltip: 'Remover',
              onPressed: () => _remover(item),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dica extends StatelessWidget {
  const _Dica();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primariaFundo,
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primaria),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              dicaServicosIndependentes,
              key: const Key('dica_servicos'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Adicionar ou editar um serviço: nome (obrigatório), unidade e valor
// (vazio = sem valor). Devolve o item pronto para gravar, ou nada.
class _EditorDePreco extends StatefulWidget {
  const _EditorDePreco({this.item, required this.ordem});

  final ItemDePreco? item;
  // Ordem de um serviço novo: depois do último.
  final int ordem;

  @override
  State<_EditorDePreco> createState() => _EditorDePrecoState();
}

class _EditorDePrecoState extends State<_EditorDePreco> {
  late final _nome = TextEditingController(text: widget.item?.nome ?? '');
  late final _valor = TextEditingController(
      text: widget.item?.valor == null
          ? ''
          : valorEmReais(widget.item!.valor!).substring(3)); // sem o "R$ "
  late var _unidade = widget.item?.unidade ?? UnidadeDeCobranca.peca;
  // A que o serviço corresponde no seletor de peças (#134); sem peça = avulso.
  late Familia? _peca = widget.item?.peca;
  late String? _variante = widget.item?.variante;
  late TipoDeServico? _servico = widget.item?.servico;
  late bool _retratil = widget.item?.retratil ?? false;
  // O nome se monta de peça, variante e serviço até ela digitar outro.
  late bool _nomeAutomatico = widget.item == null;
  String? _erroNome;

  void _escolher(VoidCallback mudanca) {
    setState(() {
      mudanca();
      final f = _peca;
      if (f == null) {
        _variante = null;
        _servico = null;
        _retratil = false;
      } else {
        if (!f.variantes.contains(_variante)) _variante = null;
        if (!f.retratil) _retratil = false;
        // tapete por m²; as demais peças, por peça (cortina por folha)
        _unidade = f == Familia.tapete
            ? UnidadeDeCobranca.m2
            : UnidadeDeCobranca.peca;
      }
      if (_nomeAutomatico && f != null && _servico != null) {
        _nome.text = nomeDoServico(f, _variante, _retratil, _servico!);
      }
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erroNome = 'Informe o nome');
      return;
    }
    Navigator.of(context).pop(ItemDePreco(
      id: widget.item?.id,
      nome: nome,
      unidade: _unidade,
      valor: lerValor(_valor.text),
      ordem: widget.item?.ordem ?? widget.ordem,
      peca: _peca,
      variante: _variante,
      servico: _peca == null ? null : _servico,
      retratil: _retratil,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Novo serviço' : 'Editar serviço'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('preco_nome'),
              controller: _nome,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Serviço',
                hintText: 'Ex.: Impermeabilização poltrona',
                errorText: _erroNome,
              ),
              onChanged: (_) {
                _nomeAutomatico = false;
                if (_erroNome != null) setState(() => _erroNome = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Peça', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final f in Familia.values)
                  ChoiceChip(
                    key: Key('preco_peca_${f.codigo ?? 'avulso'}'),
                    label: Text(f.codigo == null ? 'Avulso' : f.rotulo),
                    selected: _peca == f ||
                        (f.codigo == null && _peca == null),
                    onSelected: (_) =>
                        _escolher(() => _peca = f.codigo == null ? null : f),
                  ),
              ],
            ),
            if (_peca != null && _peca!.variantes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final v in _peca!.variantes)
                    ChoiceChip(
                      key: Key('preco_variante_$v'),
                      label: Text(_peca!.nomeDaVariante(v)),
                      selected: _variante == v,
                      onSelected: (_) => _escolher(() => _variante = v),
                    ),
                ],
              ),
            ],
            if (_peca != null) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final t in TipoDeServico.values)
                    ChoiceChip(
                      key: Key('preco_servico_${t.codigo}'),
                      label: Text(t.rotulo),
                      selected: _servico == t,
                      onSelected: (_) => _escolher(() => _servico = t),
                    ),
                ],
              ),
            ],
            if (_peca?.retratil ?? false)
              SwitchListTile(
                key: const Key('preco_retratil'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Retrátil / reclinável'),
                value: _retratil,
                onChanged: (v) => _escolher(() => _retratil = v),
              ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final u in UnidadeDeCobranca.values)
                  ChoiceChip(
                    key: Key('unidade_${u.codigo}'),
                    label: Text(u.rotulo),
                    selected: _unidade == u,
                    onSelected: (_) => setState(() => _unidade = u),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('preco_valor'),
              controller: _valor,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              // retrátil: só a diferença sobre a peça comum (#134)
              decoration: InputDecoration(
                labelText: _retratil
                    ? 'Acréscimo do retrátil'
                    : _unidade == UnidadeDeCobranca.m2
                        ? 'Valor do m²'
                        : 'Valor da peça',
                prefixText: _retratil ? '+ R\$ ' : 'R\$ ',
                hintText: 'sem valor',
                helperText: _retratil
                    ? 'Soma ao preço da mesma peça comum.'
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('salvar_preco'),
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
