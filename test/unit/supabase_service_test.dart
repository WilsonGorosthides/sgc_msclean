import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/services/supabase_service.dart';

// Testes unitários do filtro da busca (RF-004), sobre a função pura
// SupabaseService.filtrarClientes — os nomes dos casos seguem
// docs/matriz-rastreabilidade.md.
void main() {
  final linhas = [
    {
      'id': '1',
      'nome': 'Ana Souza',
      'endereco': 'Rua das Flores, 10',
      'telefone': '11 91111-1111',
    },
    {
      'id': '2',
      'nome': 'Bruno Lima',
      'endereco': 'Avenida Central, 200',
      'telefone': '11 92222-2222',
    },
    {
      'id': '3',
      'nome': 'Carla Dias',
      'endereco': 'Rua das Flores, 30',
      'telefone': '11 93333-3333',
    },
  ];

  group('supabase_service_test:', () {
    test('filtro por nome ou endereço', () {
      final porNome = SupabaseService.filtrarClientes(linhas, 'Bruno');
      expect(porNome.map((c) => c.nome), ['Bruno Lima']);

      final porEndereco = SupabaseService.filtrarClientes(linhas, 'Flores');
      expect(porEndereco.map((c) => c.nome), ['Ana Souza', 'Carla Dias']);

      final semCorrespondencia =
          SupabaseService.filtrarClientes(linhas, 'inexistente');
      expect(semCorrespondencia, isEmpty);

      final buscaVazia = SupabaseService.filtrarClientes(linhas, '');
      expect(buscaVazia.length, 3);
    });

    test('filtro case-insensitive', () {
      final maiusculas = SupabaseService.filtrarClientes(linhas, 'BRUNO');
      expect(maiusculas.map((c) => c.nome), ['Bruno Lima']);

      final minusculas =
          SupabaseService.filtrarClientes(linhas, 'avenida central');
      expect(minusculas.map((c) => c.nome), ['Bruno Lima']);

      final misturadas = SupabaseService.filtrarClientes(linhas, 'fLoReS');
      expect(misturadas.map((c) => c.nome), ['Ana Souza', 'Carla Dias']);
    });
  });
}
