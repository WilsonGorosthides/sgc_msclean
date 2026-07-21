import 'package:flutter/material.dart';
import '../models/client_model.dart';
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
  late final _enderecoController =
      TextEditingController(text: widget.cliente?.endereco ?? '');
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
    _enderecoController.dispose();
    for (final c in _telefoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _adicionarTelefone() {
    setState(() => _telefoneControllers.add(TextEditingController()));
  }

  void _removerTelefone(int indice) {
    setState(() => _telefoneControllers.removeAt(indice).dispose());
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    // endereço é opcional (#61): se vazio, confirma antes de gravar
    if (_enderecoController.text.trim().isEmpty) {
      final confirmado = await _confirmarSemEndereco();
      if (confirmado != true || !mounted) return;
    }
    setState(() => _salvando = true);
    final cliente = ClientModel(
      id: widget.cliente?.id,
      nome: _nomeController.text.trim(),
      endereco: _enderecoController.text.trim(),
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
            TextFormField(
              key: const Key('campo_endereco'),
              controller: _enderecoController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Endereço', hintText: 'Opcional'),
            ),
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
