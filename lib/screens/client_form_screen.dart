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
  late final _telefoneController =
      TextEditingController(text: widget.cliente?.telefone ?? '');
  var _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final cliente = ClientModel(
      id: widget.cliente?.id,
      nome: _nomeController.text.trim(),
      endereco: _enderecoController.text.trim(),
      telefone: _telefoneController.text.trim(),
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
              decoration: const InputDecoration(labelText: 'Endereço'),
              validator: (valor) => Validadores.obrigatorio(valor, 'endereço'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('campo_telefone'),
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
              validator: Validadores.telefone,
            ),
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
