import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/supabase_service.dart';
import '../services/maps_launcher.dart';
import '../models/client_model.dart';
import '../models/endereco.dart';
import 'client_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.service, this.abrirMaps});

  // Nos testes injeta-se um service falso; em produção usa o real.
  final SupabaseService? service;

  // Abertura do endereço no mapa (RF-009); injetável nos testes, em produção
  // usa `abrirEnderecoNoMaps` (url_launcher).
  final Future<void> Function(Endereco)? abrirMaps;

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
  late final _abrirMaps = widget.abrirMaps ?? abrirEnderecoNoMaps;
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
          // Acao destrutiva recebe a cor de alerta: a cor carrega informacao
          // (design-system.md secao 2.3), e aqui ela avisa o que o toque faz.
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alerta),
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
      appBar: AppBar(title: const Text('MSClean - Clientes')),
      body: Column(
        children: [
          // BARRA DE BUSCA (Requisito RF-004)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              // Preenchimento, raio e bordas vem do InputDecorationTheme.
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou rua...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaria),
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
                      // Cor, raio, borda e elevacao vem do CardTheme; so a
                      // margem entre itens da lista fica com a tela.
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primariaFundo,
                          child: Text(
                            cliente.nome[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.primaria),
                          ),
                        ),
                        title: Text(cliente.nome,
                            style: Theme.of(context).textTheme.titleMedium),
                        // endereço é opcional (#61) e estruturado (#65):
                        // resumo legível, ou placeholder discreto quando vazio
                        subtitle: cliente.endereco.vazio
                            ? const Text('Sem endereço',
                                style: TextStyle(
                                    color: AppColors.tintaFraca,
                                    fontStyle: FontStyle.italic))
                            : Text(cliente.endereco.resumo),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ABRIR NO MAPA (RF-009, #66): só quando há
                            // endereço; abre o Google Maps na localização.
                            if (!cliente.endereco.vazio)
                              IconButton(
                                key: Key('abrir_maps_${cliente.id}'),
                                icon: const Icon(Icons.map_outlined,
                                    color: AppColors.primaria),
                                tooltip: 'Abrir no mapa',
                                onPressed: () => _abrirMaps(cliente.endereco),
                              ),
                            // EXCLUSÃO (RF-008): lixeira por item; a linha
                            // continua abrindo a edição no toque.
                            IconButton(
                              key: Key('excluir_${cliente.id}'),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.alerta),
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
        child: const Icon(Icons.person_add),
      ),
    );
  }
}