import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/client_model.dart';
import '../utils/launcher_utils.dart';
import 'client_form_screen.dart';
import 'client_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = SupabaseService();
  String _searchQuery = '';
  String _orderBy = 'nome'; 
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('MSClean - Clientes', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            color: const Color(0xFF2C2C2C),
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'nome_asc': _orderBy = 'nome'; _ascending = true; break;
                  case 'nome_desc': _orderBy = 'nome'; _ascending = false; break;
                  case 'bairro_asc': _orderBy = 'bairro'; _ascending = true; break;
                  case 'bairro_desc': _orderBy = 'bairro'; _ascending = false; break;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(enabled: false, child: Text("ORDENAR", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
              const PopupMenuItem(value: 'nome_asc', child: Text('Nome: A → Z', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'nome_desc', child: Text('Nome: Z → A', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'bairro_asc', child: Text('Bairro: A → Z', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'bairro_desc', child: Text('Bairro: Z → A', style: TextStyle(color: Colors.white))),
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou rua...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ClientModel>>(
              future: _service.searchClients(_searchQuery, orderBy: _orderBy, ascending: _ascending),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }
                
                // --- AQUI ESTÁ A MÁGICA PARA ESCONDER O ERRO FEIO ---
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white24, size: 60),
                        const SizedBox(height: 16),
                        const Text(
                          'Ops! Verifique sua conexão.',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {}), // Recarrega a tela
                          child: const Text('Tentar novamente', style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum cliente encontrado.', style: TextStyle(color: Colors.white70)));
                }

                final clientes = snapshot.data!;

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    final hasName = cliente.nome.trim().isNotEmpty;
                    final displayName = hasName ? cliente.nome : "Sem Nome";

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(cliente.enderecoExibicao, style: const TextStyle(color: Colors.white70)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ClientDetailsScreen(client: cliente)),
                          );
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
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientFormScreen()));
          setState(() {}); 
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}