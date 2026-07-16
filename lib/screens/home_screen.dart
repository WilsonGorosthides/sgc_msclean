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
  String _searchQuery = ''; // Guarda o que o usuário digita

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
              stream: _service.getClientsStream(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nenhum cliente encontrado.'),
                  );
                }

                final clientes = snapshot.data!;

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
                        subtitle: Text(cliente.endereco),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Aqui enviaremos para a tela de detalhes depois
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
      // BOTÃO DE ADICIONAR (RF-001)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ClientFormScreen(service: _service),
          ));
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}