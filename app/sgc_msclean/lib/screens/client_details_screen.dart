import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../utils/launcher_utils.dart';
import 'client_form_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final ClientModel client;
  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  
  // Função que monta o endereço do jeito que você pediu
  String _montarEnderecoFormatado(ClientModel c) {
    List<String> linhas = [];

    // Linha 1: Rua e Número
    if (c.rua.trim().isNotEmpty) {
      String linhaRua = "rua ${c.rua}";
      if (c.numero.trim().isNotEmpty) {
        linhaRua += " N°${c.numero}";
      }
      linhas.add(linhaRua);
    } else if (c.numero.trim().isNotEmpty) {
      // Caso só tenha o número (raro, mas tratável)
      linhas.add("N°${c.numero}");
    }

    // Linha 2: Bairro / Condomínio
    if (c.bairro.trim().isNotEmpty) {
      linhas.add("(Bairro/condominio): ${c.bairro}");
    }

    // Linha 3: APT / Bloco
    if (c.complemento.trim().isNotEmpty) {
      linhas.add("APT/Bloco: ${c.complemento}");
    }

    return linhas.join('\n'); // Junta tudo pulando linha
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    final enderecoFormatado = _montarEnderecoFormatado(c);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Ficha do Cliente', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClientFormScreen(client: c)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Cabeçalho (Nome e Telefone)
            Card(
              elevation: 4,
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.nome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      c.telefone, 
                      style: const TextStyle(color: Colors.white70, fontSize: 16)
                    ),
                    const Divider(height: 30, color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.message,
                          label: 'WhatsApp',
                          color: Colors.greenAccent,
                          onTap: () => LauncherUtils.abrirWhatsApp(c.telefone),
                        ),
                        _buildActionButton(
                          icon: Icons.location_on,
                          label: 'Ver Mapa',
                          color: Colors.redAccent,
                          onTap: () => LauncherUtils.abrirMaps(c.enderecoExibicao),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              "Endereço Completo", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            const SizedBox(height: 12),
            
            // BLOCO DE ENDEREÇO REFORMULADO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                enderecoFormatado, // Texto inteligente aqui
                style: const TextStyle(
                  fontSize: 16, 
                  height: 1.6, // Espaçamento entre as linhas
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 40),
            
            const Center(
              child: Text(
                "--- Histórico Financeiro em breve ---",
                style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}