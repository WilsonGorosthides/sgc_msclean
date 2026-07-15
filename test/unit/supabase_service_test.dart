import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/services/supabase_service.dart';

import '../mocks/mock_supabase_client.dart';

// Testes unitários do SupabaseService: filtro da busca (RF-004) sobre a
// função pura filtrarClientes, e ordenação da stream (RF-003) por
// verificação de interação — os nomes dos casos seguem
// docs/matriz-rastreabilidade.md.
void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue((List<Map<String, dynamic>> _) => <ClientModel>[]);
  });
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

    test('ordena por nome em ordem alfabética crescente', () {
      final client = MockSupabaseClient();
      final queryBuilder = MockSupabaseQueryBuilder();
      final streamBuilder = MockSupabaseStreamFilterBuilder();

      // thenAnswer porque SupabaseQueryBuilder implementa Future, e o
      // mocktail veta thenReturn com Future.
      when(() => client.from('clientes')).thenAnswer((_) => queryBuilder);
      // idem para os builders da stream, que estendem Stream
      when(() => queryBuilder.stream(primaryKey: any(named: 'primaryKey')))
          .thenAnswer((_) => streamBuilder);
      when(() =>
              streamBuilder.order(any(), ascending: any(named: 'ascending')))
          .thenAnswer((_) => streamBuilder);
      when(() => streamBuilder.map<List<ClientModel>>(any()))
          .thenAnswer((_) => const Stream<List<ClientModel>>.empty());

      SupabaseService(client: client).getClientsStream('');

      // RF-003: a ordenação pedida ao Supabase deve ser crescente (A→Z).
      // Sem ascending: true explícito, o padrão do .order() da stream do
      // supabase 2.10.2 é decrescente — bug registrado na issue #39.
      verify(() => streamBuilder.order('nome', ascending: true)).called(1);
    });
  });
}
