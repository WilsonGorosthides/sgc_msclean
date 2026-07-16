import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/utils/validators.dart';

// Testes unitários das funções puras de validação do formulário (RF-001):
// obrigatório após trim() e formato do telefone (CT-003).
void main() {
  group('validadores:', () {
    test('obrigatório rejeita vazio, nulo e só espaços', () {
      expect(Validadores.obrigatorio('', 'nome'), 'Informe o nome');
      expect(Validadores.obrigatorio('   ', 'endereço'), 'Informe o endereço');
      expect(Validadores.obrigatorio(null, 'telefone'), 'Informe o telefone');
      expect(Validadores.obrigatorio('Ana', 'nome'), isNull);
    });

    test('telefone aceita dígitos, espaços e + ( ) -', () {
      expect(Validadores.telefone('11 91234-5678'), isNull);
      expect(Validadores.telefone('+55 (11) 91234-5678'), isNull);
      expect(Validadores.telefone('1234'), isNull);
    });

    test('telefone rejeita caracteres inválidos', () {
      expect(Validadores.telefone('11 91234-5678a'), isNotNull);
      expect(Validadores.telefone('tel: 1234'), isNotNull);
      expect(Validadores.telefone('12#34'), isNotNull);
      // vazio/só espaços cai na regra de campo obrigatório
      expect(Validadores.telefone('  '), 'Informe o telefone');
    });
  });
}
