import 'package:flutter/material.dart';

import '../models/atendimento.dart';
import '../models/client_model.dart';
import '../models/peca.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/agenda.dart';
import '../utils/validators.dart';

// Formulário de atendimento (RF-005, entrega enxuta da issue #77). Parte de um
// dia da agenda: a data vem pronta e não se digita. Cliente e período são
// obrigatórios; hora, local, peças e valor são opcionais. O mesmo formulário
// edita um atendimento existente (hora alterável depois).
class AtendimentoFormScreen extends StatefulWidget {
  const AtendimentoFormScreen({
    super.key,
    this.service,
    required this.data,
    required this.clientes,
    this.atendimento,
  });

  // Nos testes injeta-se um service falso; em produção usa o real.
  final SupabaseService? service;

  // O dia selecionado na agenda (ou o do atendimento em edição).
  final DateTime data;

  // A lista já carregada pela agenda; o formulário não abre outra stream.
  final List<ClientModel> clientes;

  // null = novo; preenchido = edição (salva via update, preservando o id).
  final Atendimento? atendimento;

  @override
  State<AtendimentoFormScreen> createState() => _AtendimentoFormScreenState();
}

// Linha de peça em edição: controllers próprios para quantidade e medidas.
class _PecaEmEdicao {
  _PecaEmEdicao([Peca? p])
      : tipo = p?.tipo ?? Peca.tipos.first,
        quantidade = TextEditingController(text: '${p?.quantidade ?? 1}'),
        largura = TextEditingController(text: _numero(p?.largura)),
        comprimento = TextEditingController(text: _numero(p?.comprimento));

  String tipo;
  final TextEditingController quantidade;
  final TextEditingController largura;
  final TextEditingController comprimento;

  static String _numero(double? v) {
    if (v == null) return '';
    final texto = v == v.truncateToDouble() ? v.toInt().toString() : '$v';
    return texto.replaceAll('.', ',');
  }

  Peca paraPeca() {
    final medido = Peca.ehMedido(tipo);
    return Peca(
      tipo: tipo,
      quantidade: int.tryParse(quantidade.text.trim()) ?? 1,
      largura: medido ? lerValor(largura.text) : null,
      comprimento: medido ? lerValor(comprimento.text) : null,
    );
  }

  void dispose() {
    quantidade.dispose();
    largura.dispose();
    comprimento.dispose();
  }
}

class _AtendimentoFormScreenState extends State<AtendimentoFormScreen> {
  late final _service = widget.service ?? SupabaseService();
  final _formKey = GlobalKey<FormState>();

  // Cliente: ou um cadastrado, ou um nome novo (vira provisório ao salvar).
  ClientModel? _cliente;
  String? _nomeNovo;
  final _buscaController = TextEditingController();

  Periodo? _periodo;
  late final _horaController =
      TextEditingController(text: widget.atendimento?.hora ?? '');
  late final _localController =
      TextEditingController(text: widget.atendimento?.local ?? '');
  late final _valorController = TextEditingController(
      text: _PecaEmEdicao._numero(widget.atendimento?.valor));
  late final List<_PecaEmEdicao> _pecas = [
    for (final p in widget.atendimento?.pecas ?? const <Peca>[])
      _PecaEmEdicao(p),
  ];

  // Erros dos campos que não são TextFormField (cliente e período).
  bool _faltaCliente = false;
  bool _faltaPeriodo = false;
  var _salvando = false;

  bool get _editando => widget.atendimento != null;

  @override
  void initState() {
    super.initState();
    final a = widget.atendimento;
    if (a != null) {
      _periodo = a.periodo;
      for (final c in widget.clientes) {
        if (c.id == a.clienteId) _cliente = c;
      }
    }
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _horaController.dispose();
    _localController.dispose();
    _valorController.dispose();
    for (final p in _pecas) {
      p.dispose();
    }
    super.dispose();
  }

  void _escolherCliente(ClientModel c) => setState(() {
        _cliente = c;
        _nomeNovo = null;
        _faltaCliente = false;
        // Local vem do endereço cadastrado (mesmo resumo da lista), editável.
        if (!_editando) _localController.text = c.endereco.resumo;
      });

  void _anotarSoNome() => setState(() {
        _nomeNovo = _buscaController.text.trim();
        _cliente = null;
        _faltaCliente = false;
        if (!_editando) _localController.text = '';
      });

  void _trocarCliente() => setState(() {
        _cliente = null;
        _nomeNovo = null;
        _buscaController.clear();
      });

  Future<void> _salvar() async {
    final camposOk = _formKey.currentState!.validate();
    setState(() {
      _faltaCliente = _cliente == null && _nomeNovo == null;
      _faltaPeriodo = _periodo == null;
    });
    if (!camposOk || _faltaCliente || _faltaPeriodo) return;

    setState(() => _salvando = true);
    try {
      var clienteId = _cliente?.id;
      if (clienteId == null) {
        final criado = await _service.addClienteProvisorio(_nomeNovo!);
        clienteId = criado.id;
      }
      final hora = _horaController.text.trim();
      final atendimento = Atendimento(
        id: widget.atendimento?.id,
        data: widget.data,
        periodo: _periodo!,
        hora: hora.isEmpty ? null : _normalizarHora(hora),
        clienteId: clienteId!,
        local: _localController.text.trim(),
        pecas: _pecas.map((p) => p.paraPeca()).toList(),
        valor: lerValor(_valorController.text),
      );
      if (_editando) {
        await _service.updateAtendimento(atendimento);
      } else {
        await _service.addAtendimento(atendimento);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      // falha (ex.: sem internet) não pode ser silenciosa: avisa e mantém o
      // formulário aberto com o que foi preenchido
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
      );
    }
  }

  // "9:00" vira "09:00": a coluna é `time` e a ordenação do dia compara texto.
  static String _normalizarHora(String h) =>
      h.length == 4 ? '0$h' : h;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar atendimento' : 'Novo atendimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // DATA: vem do dia da agenda; não se digita (CT-040)
            Text(
              dataPorExtenso(widget.data),
              key: const Key('data_atendimento'),
              style: textos.titleMedium?.copyWith(color: AppColors.primaria),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Secao(titulo: 'Cliente', erro: _faltaCliente ? 'Escolha um cliente' : null),
            if (_cliente != null || _nomeNovo != null)
              _ClienteEscolhido(
                nome: _cliente?.nome ?? _nomeNovo!,
                provisorio: _cliente?.provisorio ?? true,
                aoTrocar: _trocarCliente,
              )
            else
              _EscolhaDeCliente(
                controller: _buscaController,
                clientes: widget.clientes,
                aoEscolher: _escolherCliente,
                aoAnotarSoNome: _anotarSoNome,
                aoDigitar: () => setState(() {}),
              ),
            const SizedBox(height: AppSpacing.xl),

            _Secao(titulo: 'Período', erro: _faltaPeriodo ? 'Escolha o período' : null),
            Row(
              children: [
                for (final p in Periodo.values) ...[
                  Expanded(
                    child: _CartaoPeriodo(
                      periodo: p,
                      selecionado: _periodo == p,
                      aoTocar: () => setState(() {
                        _periodo = p;
                        _faltaPeriodo = false;
                      }),
                    ),
                  ),
                  if (p != Periodo.values.last)
                    const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              key: const Key('campo_hora'),
              controller: _horaController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Hora (opcional)',
                hintText: '09:00',
              ),
              validator: Validadores.hora,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const Key('campo_local'),
              controller: _localController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Local (opcional)'),
            ),
            const SizedBox(height: AppSpacing.xl),

            const _Secao(titulo: 'Peças'),
            for (var i = 0; i < _pecas.length; i++)
              _LinhaDePeca(
                indice: i,
                peca: _pecas[i],
                aoMudarTipo: (t) => setState(() => _pecas[i].tipo = t),
                aoRemover: () => setState(() => _pecas.removeAt(i).dispose()),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('adicionar_peca'),
                onPressed: () => setState(() => _pecas.add(_PecaEmEdicao())),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar peça'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              key: const Key('campo_valor'),
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontFeatures: AppTypography.digitosTabulares),
              decoration: const InputDecoration(
                labelText: 'Valor combinado (opcional)',
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton.icon(
              key: const Key('botao_salvar'),
              onPressed: _salvando ? null : _salvar,
              icon: const Icon(Icons.check),
              label: Text(_editando ? 'Salvar' : 'Confirmar atendimento'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, this.erro});

  final String titulo;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(titulo, style: textos.titleMedium),
          if (erro != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(erro!,
                style: textos.bodySmall?.copyWith(color: AppColors.alerta)),
          ],
        ],
      ),
    );
  }
}

// Busca e lista de clientes; abaixo, a opção de anotar só o nome (CT-045).
class _EscolhaDeCliente extends StatelessWidget {
  const _EscolhaDeCliente({
    required this.controller,
    required this.clientes,
    required this.aoEscolher,
    required this.aoAnotarSoNome,
    required this.aoDigitar,
  });

  final TextEditingController controller;
  final List<ClientModel> clientes;
  final void Function(ClientModel) aoEscolher;
  final VoidCallback aoAnotarSoNome;
  final VoidCallback aoDigitar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final termo = controller.text.trim();
    final filtrados = SupabaseService.filtrarClientes(clientes, termo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('busca_cliente'),
          controller: controller,
          onChanged: (_) => aoDigitar(),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Buscar cliente pelo nome...',
            prefixIcon: Icon(Icons.search, color: AppColors.primaria),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Lista limitada: o formulário já é longo; a busca refina.
        for (final c in filtrados.take(6))
          ListTile(
            key: Key('escolher_cliente_${c.id}'),
            dense: true,
            leading: CircleAvatar(
              backgroundColor: AppColors.primariaFundo,
              child: Text(c.nome.isEmpty ? '?' : c.nome[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primaria)),
            ),
            title: Text(c.nome),
            subtitle: c.endereco.vazio ? null : Text(c.endereco.resumo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => aoEscolher(c),
          ),
        if (termo.isNotEmpty)
          ListTile(
            key: const Key('anotar_so_nome'),
            dense: true,
            leading: const CircleAvatar(
              backgroundColor: AppColors.tardeFundo,
              child: Icon(Icons.person_add_alt, color: AppColors.tarde),
            ),
            title: Text('Anotar só o nome: "$termo"'),
            subtitle: Text('Cria cliente provisório — telefone e endereço depois',
                style: textos.bodySmall?.copyWith(color: AppColors.tintaFraca)),
            onTap: aoAnotarSoNome,
          ),
      ],
    );
  }
}

class _ClienteEscolhido extends StatelessWidget {
  const _ClienteEscolhido({
    required this.nome,
    required this.provisorio,
    required this.aoTrocar,
  });

  final String nome;
  final bool provisorio;
  final VoidCallback aoTrocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              provisorio ? AppColors.tardeFundo : AppColors.primariaFundo,
          child: Text(nome.isEmpty ? '?' : nome[0].toUpperCase(),
              style: TextStyle(
                  color: provisorio ? AppColors.tarde : AppColors.primaria)),
        ),
        title: Text(nome, style: textos.titleMedium),
        subtitle: provisorio
            ? Text('provisório',
                style: textos.labelSmall?.copyWith(color: AppColors.tarde))
            : null,
        trailing: TextButton(
          key: const Key('trocar_cliente'),
          onPressed: aoTrocar,
          child: const Text('Trocar'),
        ),
      ),
    );
  }
}

// Manhã e tarde com as cores de papel do design system (2.2).
class _CartaoPeriodo extends StatelessWidget {
  const _CartaoPeriodo({
    required this.periodo,
    required this.selecionado,
    required this.aoTocar,
  });

  final Periodo periodo;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cor = periodo == Periodo.manha ? AppColors.primaria : AppColors.tarde;
    final fundo =
        periodo == Periodo.manha ? AppColors.primariaFundo : AppColors.tardeFundo;
    return Material(
      key: Key('escolher_${periodo.name}'),
      color: selecionado ? fundo : AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medio),
        side: BorderSide(
          color: selecionado ? cor : AppColors.borda,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medio),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(periodo.rotulo,
                  style: textos.titleMedium?.copyWith(color: cor)),
              Text(
                periodo == Periodo.manha ? 'até o meio-dia' : 'depois do almoço',
                style: textos.bodySmall?.copyWith(color: AppColors.tintaFraca),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Uma peça: chips de tipo, quantidade e, para tipo medido, as medidas (CT-043).
class _LinhaDePeca extends StatelessWidget {
  const _LinhaDePeca({
    required this.indice,
    required this.peca,
    required this.aoMudarTipo,
    required this.aoRemover,
  });

  final int indice;
  final _PecaEmEdicao peca;
  final void Function(String) aoMudarTipo;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    Widget numero(String chave, TextEditingController c, String rotulo) {
      return TextFormField(
        key: Key(chave),
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontFeatures: AppTypography.digitosTabulares),
        decoration: InputDecoration(labelText: rotulo),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final t in Peca.tipos)
                        ChoiceChip(
                          key: Key('peca_${indice}_tipo_$t'),
                          label: Text(t),
                          selected: peca.tipo == t,
                          onSelected: (_) => aoMudarTipo(t),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('remover_peca_$indice'),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.alerta),
                  tooltip: 'Remover peça',
                  onPressed: aoRemover,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: numero('peca_${indice}_quantidade', peca.quantidade,
                      'Quantidade'),
                ),
                if (Peca.ehMedido(peca.tipo)) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: numero(
                        'peca_${indice}_largura', peca.largura, 'Largura (m)'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: numero('peca_${indice}_comprimento',
                        peca.comprimento, 'Comprimento (m)'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
