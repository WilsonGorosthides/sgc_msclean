import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/client_model.dart';
import 'client_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.service});

  // Nos testes injeta-se um service falso; em produção usa o real.
  final SupabaseService? service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _service = widget.service ?? SupabaseService();
  // Assinatura única da stream, viva enquanto a tela está em foco: não é
  // recriada por rebuild (ex.: tecla na busca — o churn derruba o realtime),
  // apenas renovada no retorno do formulário (issue #57: o projeto Supabase
  // não entrega eventos UPDATE; a renovação garante o reflexo da edição).
  late Stream<List<ClientModel>> _clientesStream = _service.getClientsStream();
  String _searchQuery = ''; // Guarda o que o usuário digita

  // Abre o formulário (cadastro ou edição) e renova a stream ao voltar.
  Future<void> _abrirFormulario({ClientModel? cliente}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClientFormScreen(service: _service, cliente: cliente),
    ));
    if (!mounted) return;
    setState(() => _clientesStream = _service.getClientsStream());
  }

  // Exclui um cliente (RF-008) após confirmação explícita. A lista é
  // renovada no sucesso — o reflexo não depende do evento DELETE do
  // realtime (issue #57), garantindo remoção imediata na tela.
  Future<void> _excluirCliente(ClientModel cliente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar exclusão?'),
        content: Text('Remover ${cliente.nome} da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await _service.deleteClient(cliente);
      if (!mounted) return;
      setState(() => _clientesStream = _service.getClientsStream());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente excluído')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MSClean - Clientes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // BARRA DE BUSCA (Requisito RF-004)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou rua...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // LISTA DE CLIENTES
          Expanded(
            child: StreamBuilder<List<ClientModel>>(
              stream: _clientesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // busca (RF-004) aplicada sobre a lista emitida, no widget
                final clientes = SupabaseService.filtrarClientes(
                    snapshot.data ?? [], _searchQuery);

                if (clientes.isEmpty) {
                  return const Center(
                    child: Text('Nenhum cliente encontrado.'),
                  );
                }

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(cliente.nome[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // endereço é opcional (#61) e estruturado (#65):
                        // resumo legível, ou placeholder discreto quando vazio
                        subtitle: cliente.endereco.vazio
                            ? Text('Sem endereço',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic))
                            : Text(cliente.endereco.resumo),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // EXCLUSÃO (RF-008): lixeira por item; a linha
                            // continua abrindo a edição no toque.
                            IconButton(
                              key: Key('excluir_${cliente.id}'),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Excluir',
                              onPressed: () => _excluirCliente(cliente),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        // EDIÇÃO (RF-002): abre o formulário pré-preenchido
                        onTap: () => _abrirFormulario(cliente: cliente),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // BOTÃO DE ADICIONAR (RF-001)
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}