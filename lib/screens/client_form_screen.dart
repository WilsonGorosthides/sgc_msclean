import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../models/endereco.dart';
import '../services/supabase_service.dart';
import '../utils/validators.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.service, this.cliente});

  // Nos testes injeta-se um service falso; em produção usa o real.
  final SupabaseService? service;

  // null = cadastro (RF-001); preenchido = edição (RF-002): campos
  // pré-preenchidos e salvamento via update, preservando o id.
  final ClientModel? cliente;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  late final _service = widget.service ?? SupabaseService();
  final _formKey = GlobalKey<FormState>();
  late final _nomeController =
      TextEditingController(text: widget.cliente?.nome ?? '');
  // Endereço estruturado (#65): um controller por campo, pré-preenchido na
  // edição a partir do Endereco do cliente. Todos opcionais.
  late final _logradouroController =
      TextEditingController(text: widget.cliente?.endereco.logradouro ?? '');
  late final _numeroController =
      TextEditingController(text: widget.cliente?.endereco.numero ?? '');
  late final _bairroController =
      TextEditingController(text: widget.cliente?.endereco.bairro ?? '');
  late final _complementoController =
      TextEditingController(text: widget.cliente?.endereco.complemento ?? '');
  late final _referenciaController =
      TextEditingController(text: widget.cliente?.endereco.referencia ?? '');
  // Um ou mais telefones (#62): um controller por número, começando com o(s)
  // do cliente (edição) ou um campo vazio (cadastro).
  late final List<TextEditingController> _telefoneControllers =
      _controllersIniciais();
  var _salvando = false;

  List<TextEditingController> _controllersIniciais() {
    final tels = widget.cliente?.telefones ?? const <String>[];
    if (tels.isEmpty) return [TextEditingController()];
    return tels.map((t) => TextEditingController(text: t)).toList();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    for (final c in _enderecoControllers) {
      c.dispose();
    }
    for (final c in _telefoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Todos os controllers do endereço, para dispose e leitura em bloco.
  List<TextEditingController> get _enderecoControllers => [
        _logradouroController,
        _numeroController,
        _bairroController,
        _complementoController,
        _referenciaController,
      ];

  Endereco _lerEndereco() => Endereco(
        logradouro: _logradouroController.text.trim(),
        numero: _numeroController.text.trim(),
        bairro: _bairroController.text.trim(),
        complemento: _complementoController.text.trim(),
        referencia: _referenciaController.text.trim(),
      );

  void _adicionarTelefone() {
    setState(() => _telefoneControllers.add(TextEditingController()));
  }

  void _removerTelefone(int indice) {
    setState(() => _telefoneControllers.removeAt(indice).dispose());
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final endereco = _lerEndereco();
    // endereço é opcional (#61): se nenhum campo foi preenchido, confirma
    // antes de gravar
    if (endereco.vazio) {
      final confirmado = await _confirmarSemEndereco();
      if (confirmado != true || !mounted) return;
    }
    setState(() => _salvando = true);
    final cliente = ClientModel(
      id: widget.cliente?.id,
      nome: _nomeController.text.trim(),
      endereco: endereco,
      telefones: _telefoneControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );
    try {
      if (widget.cliente == null) {
        await _service.addClient(cliente);
      } else {
        await _service.updateClient(cliente);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      // falha no insert (ex.: sem internet) não pode ser silenciosa:
      // avisa e mantém o formulário aberto com os dados digitados
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
      );
    }
  }

  // Aviso ao salvar sem endereço (#61): endereço é opcional, mas confirma
  // para evitar esquecimento acidental.
  Future<bool?> _confirmarSemEndereco() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('Cliente sem endereço. Deseja salvar mesmo assim?'),
        actions: [
          TextButton(
            key: const Key('cancelar_sem_endereco'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirmar_sem_endereco'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salvar mesmo assim'),
          ),
        ],
      ),
    );
  }

  // Campos do endereço estruturado (#65), todos opcionais e otimizados para
  // localizar via Google Maps: rua+número, bairro, complemento
  // (bloco/apto/condomínio) e ponto de referência. Sem campo de cidade — a
  // base é toda de Campo Grande - MS (âncora fixa em Endereco.consultaMaps).
  List<Widget> _camposEndereco() {
    Widget campo(
      String chave,
      TextEditingController controller,
      String label, {
      TextInputType? tipo,
      TextCapitalization capitalizacao = TextCapitalization.words,
    }) {
      return TextFormField(
        key: Key(chave),
        controller: controller,
        keyboardType: tipo,
        textCapitalization: capitalizacao,
        decoration: InputDecoration(labelText: label),
      );
    }

    return [
      const Align(
        alignment: Alignment.centerLeft,
        child: Text('Endereço (opcional)',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child:
                campo('campo_logradouro', _logradouroController, 'Rua / Avenida'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: campo('campo_numero', _numeroController, 'Número',
                tipo: TextInputType.text,
                capitalizacao: TextCapitalization.none),
          ),
        ],
      ),
      const SizedBox(height: 8),
      campo('campo_bairro', _bairroController, 'Bairro'),
      const SizedBox(height: 8),
      campo('campo_complemento', _complementoController,
          'Complemento (bloco, apto, torre)'),
      const SizedBox(height: 8),
      campo('campo_referencia', _referenciaController, 'Ponto de referência'),
    ];
  }

  // Campos de telefone (#62): um por número, com botão de remover quando há
  // mais de um, e um botão para adicionar outro.
  List<Widget> _camposTelefone() {
    final campos = <Widget>[];
    for (var i = 0; i < _telefoneControllers.length; i++) {
      campos.add(Row(
        children: [
          Expanded(
            child: TextFormField(
              key: Key('campo_telefone_$i'),
              controller: _telefoneControllers[i],
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: i == 0 ? 'Telefone' : 'Telefone ${i + 1}'),
              validator: Validadores.telefone,
            ),
          ),
          if (_telefoneControllers.length > 1)
            IconButton(
              key: Key('remover_telefone_$i'),
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent),
              tooltip: 'Remover telefone',
              onPressed: () => _removerTelefone(i),
            ),
        ],
      ));
      campos.add(const SizedBox(height: 8));
    }
    campos.add(Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('adicionar_telefone'),
        onPressed: _adicionarTelefone,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar telefone'),
      ),
    ));
    return campos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              key: const Key('campo_nome'),
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (valor) => Validadores.obrigatorio(valor, 'nome'),
            ),
            const SizedBox(height: 16),
            ..._camposEndereco(),
            const SizedBox(height: 16),
            ..._camposTelefone(),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('botao_salvar'),
              onPressed: _salvando ? null : _salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
