import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/client_model.dart';

// Testes unitários do ClientModel (cobertura prevista em
// docs/plano-de-testes.md §2.2): toMap para o insert do RF-001 e
// ida e volta toMap/fromMap. Telefone passa a ser uma lista (#62).
void main() {
  group('client_model_test:', () {
    test('toMap exporta nome, endereço e telefones sem id', () {
      final cliente = ClientModel(
        id: 'uuid-que-nao-deve-ir',
        nome: 'Ana Souza',
        endereco: 'Rua das Flores, 10',
        telefones: ['11 91111-1111', '11 95555-5555'],
      );

      final map = cliente.toMap();

      expect(map, {
        'nome': 'Ana Souza',
        'endereco': 'Rua das Flores, 10',
        'telefones': ['11 91111-1111', '11 95555-5555'],
      });
      // o id é gerado pelo Supabase; não deve ser enviado no insert
      expect(map.containsKey('id'), isFalse);
    });

    test('ida e volta toMap/fromMap preserva os dados', () {
      final original = ClientModel(
        nome: 'Bruno Lima',
        endereco: 'Avenida Central, 200',
        telefones: ['+55 (11) 92222-2222', '11 93333-3333'],
      );

      final reconstruido = ClientModel.fromMap(original.toMap());

      expect(reconstruido.nome, original.nome);
      expect(reconstruido.endereco, original.endereco);
      expect(reconstruido.telefones, original.telefones);
    });

    test('fromMap com campos ausentes ou nulos usa vazio', () {
      final cliente = ClientModel.fromMap({'nome': null});

      expect(cliente.id, isNull);
      expect(cliente.nome, '');
      expect(cliente.endereco, '');
      expect(cliente.telefones, isEmpty);
    });

    test('fromMap aceita o campo legado telefone (transição de migração)', () {
      // segurança durante a migração: uma linha antiga com 'telefone' string
      // é lida como lista de um item.
      final cliente = ClientModel.fromMap({
        'nome': 'Carla Dias',
        'endereco': 'Rua das Flores, 30',
        'telefone': '11 94444-4444',
      });

      expect(cliente.telefones, ['11 94444-4444']);
    });
  });
}
