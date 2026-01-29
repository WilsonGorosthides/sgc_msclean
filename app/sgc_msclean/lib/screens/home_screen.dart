import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/client_model.dart';
import '../utils/launcher_utils.dart';
import 'client_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = SupabaseService();
  String _searchQuery = '';
  
  // Variáveis de controle de ordenação (Camadas)
  String _orderBy = 'nome'; 
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MSClean - Clientes'),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                // Lógica de camadas: Escolha do campo + Direção
                switch (value) {
                  case 'nome_asc': _orderBy = 'nome'; _ascending = true; break;
                  case 'nome_desc': _orderBy = 'nome'; _ascending = false; break;
                  case 'bairro_asc': _orderBy = 'bairro'; _ascending = true; break;
                  case 'bairro_desc': _orderBy = 'bairro'; _ascending = false; break;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(enabled: false, child: Text("ORDENAR POR NOME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              const PopupMenuItem(value: 'nome_asc', child: Text('Nome: A → Z')),
              const PopupMenuItem(value: 'nome_desc', child: Text('Nome: Z → A')),
              const PopupMenuDivider(),
              const PopupMenuItem(enabled: false, child: Text("ORDENAR POR ENDEREÇO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              const PopupMenuItem(value: 'bairro_asc', child: Text('Bairro: A → Z')),
              const PopupMenuItem(value: 'bairro_desc', child: Text('Bairro: Z → A')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
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
          Expanded(
            child: FutureBuilder<List<ClientModel>>(
              // Aqui chamamos a busca no servidor passando os filtros de camada
              future: _service.searchClients(
                _searchQuery, 
                orderBy: _orderBy, 
                ascending: _ascending
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum cliente encontrado.'));
                }

                final clientes = snapshot.data!;

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    
                    // Proteção contra dados vazios (Programação Defensiva)
                    final hasName = cliente.nome.trim().isNotEmpty;
                    final displayLetter = hasName ? cliente.nome[0].toUpperCase() : '?';
                    final displayName = hasName ? cliente.nome : "Sem Nome (${cliente.telefone})";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(displayLetter, style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(cliente.enderecoExibicao),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.green, size: 20),
                              onPressed: () => LauncherUtils.abrirWhatsApp(cliente.telefone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                              onPressed: () => LauncherUtils.abrirMaps(cliente.enderecoExibicao),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        onTap: () async {
                          // Aguarda o retorno da tela de edição
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientFormScreen(client: cliente),
                            ),
                          );
                          // Atualiza a lista quando voltar (importante para FutureBuilder)
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientFormScreen(),
            ),
          );
          setState(() {}); // Atualiza ao voltar do cadastro
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}