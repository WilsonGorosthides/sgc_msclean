import 'dart:async';

import 'package:flutter/material.dart';

import '../models/atendimento.dart';
import '../models/client_model.dart';
import '../models/item_de_preco.dart';
import '../models/peca.dart';
import '../services/contatos.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/agenda.dart';
import '../utils/calculo.dart';
import '../utils/telefone.dart';
import '../utils/validators.dart';
import '../widgets/rodape_do_total.dart';
import 'pecas_e_valor_screen.dart';

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
    this.contatos,
  });

  // Seletor de contatos do celular (RF-016); nos testes, um falso.
  final AgendaDoCelular? contatos;

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

class _AtendimentoFormScreenState extends State<AtendimentoFormScreen> {
  late final _service = widget.service ?? SupabaseService();
  final _formKey = GlobalKey<FormState>();

  // Cliente: ou um cadastrado, ou um nome novo (vira provisório ao salvar).
  ClientModel? _cliente;
  String? _nomeNovo;
  // Telefone do contato do celular (RF-016): com ele, o nome novo vira cliente
  // de verdade, não provisório.
  String? _telefoneNovo;
  late final _contatos = widget.contatos ?? ContatosDoAparelho();
  final _buscaController = TextEditingController();

  Periodo? _periodo;
  late final _horaController = TextEditingController(
    text: widget.atendimento?.hora ?? '',
  );
  late final _localController = TextEditingController(
    text: widget.atendimento?.local ?? '',
  );
  // Peças com os serviços e preços copiados (seletor de peças, #134).
  late List<Peca> _pecas = widget.atendimento?.pecas ?? const [];

  // Tabela de preços (RF-013, #124), do espelho no aparelho: funciona sem
  // internet. Só leitura; nada aqui grava na tabela.
  List<ItemDePreco> _tabela = const [];
  StreamSubscription<List<ItemDePreco>>? _assinaturaPrecos;

  // Valor informado por ela (desconto, combinado diferente); nulo = segue o
  // total calculado pela tabela (CT-091).
  double? _valorManual;

  // Erros dos campos que não são TextFormField (cliente e período).
  bool _faltaCliente = false;
  bool _faltaPeriodo = false;
  var _salvando = false;

  bool get _editando => widget.atendimento != null;

  // O dia do atendimento: vem da agenda; na edição, pode ser trocado (#106).
  late DateTime _data = widget.data;

  // Adiar ou corrigir o dia anotado errado (RF-005, CT-067). Só na edição: no
  // registro novo a data é a do dia selecionado (CT-040).
  Future<void> _trocarDia() async {
    final escolhido = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Escolha o novo dia',
    );
    if (escolhido != null) setState(() => _data = soData(escolhido));
  }

  // Excluir (RF-005, CT-068): cliente que desmarcou ou anotação errada.
  Future<void> _excluir() async {
    final a = widget.atendimento!;
    final nome = _cliente?.nome ?? 'este cliente';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Excluir atendimento?'),
        content: Text(
          'Remover o atendimento de $nome em ${dataPorExtenso(a.data)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alerta),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await _service.deleteAtendimento(a.id!);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir. Tente novamente.')),
      );
    }
  }

  // Ao sair do campo, a hora abreviada ("8", "830") vira HH:MM na tela.
  late final FocusNode _horaFoco = FocusNode()
    ..addListener(() {
      if (_horaFoco.hasFocus) return;
      final completa = Validadores.completarHora(_horaController.text);
      if (completa != null) _horaController.text = completa;
    });

  @override
  void initState() {
    super.initState();
    final a = widget.atendimento;
    if (a != null) {
      _periodo = a.periodo;
      for (final c in widget.clientes) {
        if (c.id == a.clienteId) _cliente = c;
      }
      // Valor registrado diferente do calculado (ou sem serviços): foi
      // combinado à mão e fica como está.
      final calculo = calcularValor(a.pecas);
      if (a.valor != null && (!calculo.temValor || a.valor != calculo.total)) {
        _valorManual = a.valor;
      }
    }
    _assinaturaPrecos = _service.getPrecosStream().listen(
      (dados) {
        if (mounted) setState(() => _tabela = dados);
      },
      onError: (Object _) {}, // sem tabela, o valor é só digitado
    );
  }

  @override
  void dispose() {
    _assinaturaPrecos?.cancel();
    _buscaController.dispose();
    _horaFoco.dispose();
    _horaController.dispose();
    _localController.dispose();
    super.dispose();
  }

  void _escolherCliente(ClientModel c) => setState(() {
    _cliente = c;
    _nomeNovo = null;
    _telefoneNovo = null;
    _faltaCliente = false;
    // Local vem do endereço cadastrado (mesmo resumo da lista), editável.
    if (!_editando) _localController.text = c.endereco.resumo;
  });

  void _anotarSoNome() => setState(() {
    _nomeNovo = _buscaController.text.trim();
    _telefoneNovo = null;
    _cliente = null;
    _faltaCliente = false;
    if (!_editando) _localController.text = '';
  });

  // Contato do celular (RF-016, CT-074): se o número já é de um cliente,
  // escolhe esse cliente; senão, anota nome e telefone para criar ao salvar.
  Future<void> _trazerDosContatos() async {
    final contato = await _contatos.escolher();
    if (contato == null || !mounted) return;
    final existente = clienteComTelefone(widget.clientes, contato.telefone);
    if (existente != null) {
      _escolherCliente(existente);
      return;
    }
    final telefone = formatarTelefone(contato.telefone);
    setState(() {
      _nomeNovo = contato.nome.isEmpty ? telefone : contato.nome;
      _telefoneNovo = telefone;
      _cliente = null;
      _faltaCliente = false;
      if (!_editando) _localController.text = '';
    });
  }

  void _trocarCliente() => setState(() {
    _cliente = null;
    _nomeNovo = null;
    _telefoneNovo = null;
    _buscaController.clear();
  });

  Future<void> _abrirPecas() async {
    final resultado = await Navigator.of(context).push<PecasEValor>(
      MaterialPageRoute(
        builder: (_) => PecasEValorScreen(
          pecas: _pecas,
          tabela: _tabela,
          valorManual: _valorManual,
        ),
      ),
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _pecas = resultado.pecas;
      _valorManual = resultado.valorManual;
    });
  }

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
        final criado = _telefoneNovo == null
            ? await _service.addClienteProvisorio(_nomeNovo!)
            : await _service.addClienteDoContato(_nomeNovo!, _telefoneNovo!);
        clienteId = criado.id;
      }
      final hora = _horaController.text.trim();
      final atendimento = Atendimento(
        id: widget.atendimento?.id,
        data: _data,
        periodo: _periodo!,
        hora: Validadores.completarHora(hora),
        clienteId: clienteId!,
        local: _localController.text.trim(),
        pecas: _pecas,
        valor: RodapeDoTotal.valorACobrar(_pecas, _valorManual),
      );
      if (_editando) {
        await _service.updateAtendimento(atendimento);
      } else {
        await _service.addAtendimento(atendimento);
      }
      if (!mounted) return;
      // dia trocado: a agenda vai para o dia novo
      Navigator.of(context).pop(_data != widget.data ? _data : null);
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

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar atendimento' : 'Novo atendimento'),
        actions: [
          if (_editando)
            IconButton(
              key: const Key('excluir_atendimento'),
              icon: const Icon(Icons.delete_outline, color: AppColors.alerta),
              tooltip: 'Excluir atendimento',
              onPressed: _excluir,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Do Android 15 em diante a tela vai por baixo da barra de
          // navegação; sem somar a barra, o Salvar fica coberto (#118).
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            // DATA: vem do dia da agenda; não se digita (CT-040). Na edição,
            // toca-se para trocar o dia (CT-067).
            InkWell(
              onTap: _editando ? _trocarDia : null,
              borderRadius: BorderRadius.circular(AppRadius.pequeno),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dataPorExtenso(_data),
                      key: const Key('data_atendimento'),
                      style: textos.titleMedium?.copyWith(
                        color: AppColors.primaria,
                      ),
                    ),
                  ),
                  if (_editando)
                    const Icon(
                      Icons.edit_calendar_outlined,
                      color: AppColors.primaria,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Secao(
              titulo: 'Cliente',
              erro: _faltaCliente ? 'Escolha um cliente' : null,
            ),
            if (_cliente != null || _nomeNovo != null)
              _ClienteEscolhido(
                nome: _cliente?.nome ?? _nomeNovo!,
                provisorio: _cliente?.provisorio ?? _telefoneNovo == null,
                aoTrocar: _trocarCliente,
              )
            else
              _EscolhaDeCliente(
                controller: _buscaController,
                clientes: widget.clientes,
                aoEscolher: _escolherCliente,
                aoAnotarSoNome: _anotarSoNome,
                aoTrazerDosContatos: _contatos.disponivel
                    ? _trazerDosContatos
                    : null,
                aoDigitar: () => setState(() {}),
              ),
            const SizedBox(height: AppSpacing.xl),

            _Secao(
              titulo: 'Período',
              erro: _faltaPeriodo ? 'Escolha o período' : null,
            ),
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
              focusNode: _horaFoco,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Hora (opcional)',
                hintText: '8, 830 ou 14:30',
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

            // PEÇAS E VALOR (#134, CT-101): uma linha de resumo; o seletor
            // fica numa tela própria, para anotar continuar rápido.
            const _Secao(titulo: 'Peças e valor'),
            _ResumoDePecas(
              pecas: _pecas,
              valor: RodapeDoTotal.valorACobrar(_pecas, _valorManual),
              aoTocar: _abrirPecas,
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton.icon(
              key: const Key('botao_salvar'),
              onPressed: _salvando ? null : _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar atendimento'),
            ),
          ],
        ),
      ),
    );
  }
}

// Linha de resumo das peças e do valor: abre a tela Peças e valor.
class _ResumoDePecas extends StatelessWidget {
  const _ResumoDePecas({
    required this.pecas,
    required this.valor,
    required this.aoTocar,
  });

  final List<Peca> pecas;
  final double? valor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final vazio = pecas.isEmpty && valor == null;
    return Card(
      key: const Key('abrir_pecas'),
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: aoTocar,
        leading: Icon(
          vazio ? Icons.add_circle_outline : Icons.weekend_outlined,
          color: AppColors.primaria,
        ),
        title: Text(
          vazio
              ? 'Adicionar peças e valor'
              : pecas.isEmpty
              ? 'Sem peças'
              : pecas.map((p) => p.resumo).join(', '),
          key: const Key('resumo_pecas'),
          style: vazio
              ? textos.titleMedium?.copyWith(color: AppColors.primaria)
              : textos.titleMedium,
        ),
        subtitle: vazio
            ? Text(
                'opcional — dá para anotar só o cliente e o período',
                style: textos.bodySmall?.copyWith(color: AppColors.tintaFraca),
              )
            : Text(
                valor == null ? 'sem valor' : valorEmReais(valor!),
                key: const Key('resumo_valor'),
                style: textos.titleSmall?.copyWith(
                  color: valor == null ? AppColors.tarde : AppColors.tinta,
                ),
              ),
        trailing: const Icon(Icons.chevron_right),
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
            Text(
              erro!,
              style: textos.bodySmall?.copyWith(color: AppColors.alerta),
            ),
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
    this.aoTrazerDosContatos,
  });

  final VoidCallback? aoTrazerDosContatos;
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
              child: Text(
                c.nome.isEmpty ? '?' : c.nome[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primaria),
              ),
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
            subtitle: Text(
              'Cria cliente provisório — telefone e endereço depois',
              style: textos.bodySmall?.copyWith(color: AppColors.tintaFraca),
            ),
            onTap: aoAnotarSoNome,
          ),
        if (aoTrazerDosContatos != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('dos_contatos'),
              onPressed: aoTrazerDosContatos,
              icon: const Icon(Icons.contacts_outlined),
              label: const Text('Dos contatos do celular'),
            ),
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
          backgroundColor: provisorio
              ? AppColors.tardeFundo
              : AppColors.primariaFundo,
          child: Text(
            nome.isEmpty ? '?' : nome[0].toUpperCase(),
            style: TextStyle(
              color: provisorio ? AppColors.tarde : AppColors.primaria,
            ),
          ),
        ),
        title: Text(nome, style: textos.titleMedium),
        subtitle: provisorio
            ? Text(
                'provisório',
                style: textos.labelSmall?.copyWith(color: AppColors.tarde),
              )
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
    final fundo = periodo == Periodo.manha
        ? AppColors.primariaFundo
        : AppColors.tardeFundo;
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
              Text(
                periodo.rotulo,
                style: textos.titleMedium?.copyWith(color: cor),
              ),
              Text(
                periodo == Periodo.manha
                    ? 'até o meio-dia'
                    : 'depois do almoço',
                style: textos.bodySmall?.copyWith(color: AppColors.tintaFraca),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
