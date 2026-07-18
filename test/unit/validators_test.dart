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
      expect(Validadores.telefone('12345678'), isNull);
    });

    test('telefone exige no mínimo 8 dígitos, contando só dígitos', () {
      const mensagem = 'Telefone deve ter pelo menos 8 dígitos';
      // Menos de 8 dígitos: rejeitado (símbolos e espaços não contam).
      expect(Validadores.telefone('1234'), mensagem);
      expect(Validadores.telefone('192'), mensagem);
      expect(Validadores.telefone('(12) 3456-7'), mensagem);
      // 8 dígitos ou mais: aceito (fixo local sem DDD é hábito legítimo).
      expect(Validadores.telefone('3456-7890'), isNull);
      expect(Validadores.telefone('+55 (11) 91234-5678'), isNull);
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
