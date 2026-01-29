import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/client_model.dart';
import '../utils/launcher_utils.dart'; // Importante adicionar este import
import 'client_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = SupabaseService();
  String _searchQuery = '';

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
            child: StreamBuilder<List<ClientModel>>(
              stream: _service.getClientsStream(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum cliente encontrado.'));
                }

                final clientes = snapshot.data!;

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    
                    final hasName = cliente.nome.trim().isNotEmpty;
                    final displayLetter = hasName ? cliente.nome[0].toUpperCase() : '?';
                    final displayName = hasName ? cliente.nome : "Sem Nome (${cliente.telefone})";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            displayLetter, 
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          displayName, 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(cliente.enderecoExibicao),
                        
                        // --- AQUI ESTÁ A MUDANÇA: ADICIONANDO OS BOTÕES ---
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, // Garante que os ícones fiquem juntos no canto
                          children: [
                            // Botão WhatsApp
                            IconButton(
                              icon: const Icon(Icons.message, color: Colors.green, size: 20),
                              onPressed: () => LauncherUtils.abrirWhatsApp(cliente.telefone),
                            ),
                            // Botão Maps
                            IconButton(
                              icon: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                              onPressed: () => LauncherUtils.abrirMaps(cliente.enderecoExibicao),
                            ),
                            // Ícone de seta para indicar que o card abre para edição
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientFormScreen(client: cliente),
                            ),
                          );
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}