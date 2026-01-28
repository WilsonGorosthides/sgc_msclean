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
  late TextEditingController _endController;
  late TextEditingController _telController;

  @override
  void initState() {
    super.initState();
    // Inicializa os campos com os dados do cliente (se for edição) ou vazio
    _nomeController = TextEditingController(text: widget.client?.nome);
    _endController = TextEditingController(text: widget.client?.endereco);
    _telController = TextEditingController(text: widget.client?.telefone);
  }

  // --- FUNÇÃO 1: SALVAR ---
  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final novoCliente = ClientModel(
        id: widget.client?.id,
        nome: _nomeController.text,
        endereco: _endController.text,
        telefone: _telController.text,
      );

      try {
        if (widget.client == null) {
          await _service.saveClient(novoCliente);
        } else {
          await _service.updateClient(novoCliente);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

  // --- FUNÇÃO 2: CONFIRMAR EXCLUSÃO (O SEU PASSO 3) ---
  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Cliente?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteClient(widget.client!.id!);
              if (mounted) {
                Navigator.pop(ctx); // Fecha o alerta
                Navigator.pop(context); // Volta para a lista
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
          // O BOTÃO DE LIXEIRA QUE VOCÊ PERGUNTOU
          if (widget.client != null) 
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmarExclusao(context),
            ),
        ],
      ),
      body: Padding(
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
              TextFormField(
                controller: _endController,
                decoration: const InputDecoration(labelText: 'Endereço Completo'),
              ),
              TextFormField(
                controller: _telController,
                decoration: const InputDecoration(labelText: 'Telefone/WhatsApp'),
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