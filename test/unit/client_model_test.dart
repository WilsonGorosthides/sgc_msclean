import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/client_model.dart';

// Testes unitários do ClientModel (cobertura prevista em
// docs/plano-de-testes.md §2.2): toMap para o insert do RF-001 e
// ida e volta toMap/fromMap.
void main() {
  group('client_model_test:', () {
    test('toMap exporta nome, endereço e telefone sem id', () {
      final cliente = ClientModel(
        id: 'uuid-que-nao-deve-ir',
        nome: 'Ana Souza',
        endereco: 'Rua das Flores, 10',
        telefone: '11 91111-1111',
      );

      final map = cliente.toMap();

      expect(map, {
        'nome': 'Ana Souza',
        'endereco': 'Rua das Flores, 10',
        'telefone': '11 91111-1111',
      });
      // o id é gerado pelo Supabase; não deve ser enviado no insert
      expect(map.containsKey('id'), isFalse);
    });

    test('ida e volta toMap/fromMap preserva os dados', () {
      final original = ClientModel(
        nome: 'Bruno Lima',
        endereco: 'Avenida Central, 200',
        telefone: '+55 (11) 92222-2222',
      );

      final reconstruido = ClientModel.fromMap(original.toMap());

      expect(reconstruido.nome, original.nome);
      expect(reconstruido.endereco, original.endereco);
      expect(reconstruido.telefone, original.telefone);
    });

    test('fromMap com campos ausentes ou nulos usa vazio', () {
      final cliente = ClientModel.fromMap({'nome': null});

      expect(cliente.id, isNull);
      expect(cliente.nome, '');
      expect(cliente.endereco, '');
      expect(cliente.telefone, '');
    });
  });
}
