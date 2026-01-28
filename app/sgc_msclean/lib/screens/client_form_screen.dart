import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/supabase_service.dart';

class ClientFormScreen extends StatefulWidget {
  final ClientModel? client;
  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();
  
  late TextEditingController _nomeController;
  late TextEditingController _ruaController;
  late TextEditingController _numController;
  late TextEditingController _bairroController;
  late TextEditingController _compController;
  late TextEditingController _telController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.client?.nome);
    _ruaController = TextEditingController(text: widget.client?.rua);
    _numController = TextEditingController(text: widget.client?.numero);
    _bairroController = TextEditingController(text: widget.client?.bairro);
    _compController = TextEditingController(text: widget.client?.complemento);
    _telController = TextEditingController(text: widget.client?.telefone);
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final clienteEditado = ClientModel(
        id: widget.client?.id,
        nome: _nomeController.text,
        rua: _ruaController.text,
        numero: _numController.text,
        bairro: _bairroController.text,
        complemento: _compController.text,
        telefone: _telController.text,
      );

      try {
        if (widget.client == null) {
          await _service.saveClient(clienteEditado);
        } else {
          await _service.updateClient(clienteEditado);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Cliente?'),
        content: const Text('Essa ação apagará permanentemente o cliente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteClient(widget.client!.id!);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Novo Cliente' : 'Editar Cliente'),
        actions: [
          if (widget.client != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmarExclusao(context),
            ),
        ],
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Cliente'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // MUDANÇA AQUI: Logradouro
                  Expanded(flex: 3, child: TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua / Logradouro'))),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: TextFormField(controller: _numController, decoration: const InputDecoration(labelText: 'Nº'))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // MUDANÇA AQUI: Bairro / Condomínio
                  Expanded(child: TextFormField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro / Condomínio'))),
                  const SizedBox(width: 10),
                  // MUDANÇA AQUI: Apto / Bloco
                  Expanded(child: TextFormField(controller: _compController, decoration: const InputDecoration(labelText: 'Apto / Bloco'))),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _telController,
                decoration: const InputDecoration(labelText: 'Telefone / WhatsApp'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('SALVAR ALTERAÇÕES'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}