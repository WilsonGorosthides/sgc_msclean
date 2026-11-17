import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/client_model.dart';
import 'package:sgc_msclean/utils/telefone.dart';

// Formato e comparação de telefone (RF-016, CT-075): o contato do celular
// chega em qualquer formato; a base importada usa "+55 67 99999-9999".
void main() {
  group('telefone_test:', () {
    test('formata no padrão da base, com 67 quando falta o DDD', () {
      expect(formatarTelefone('67993018496'), '+55 67 99301-8496');
      expect(formatarTelefone('+55 (67) 99301-8496'), '+55 67 99301-8496');
      expect(formatarTelefone('993018496'), '+55 67 99301-8496');
      expect(formatarTelefone('6733841234'), '+55 67 3384-1234');
      expect(formatarTelefone('067 99301-8496'), '+55 67 99301-8496');
      expect(formatarTelefone('+1 202 555 0100'), '+1 202 555 0100');
    });

    test('compara pelo DDD e os 8 últimos dígitos', () {
      expect(mesmoTelefone('+55 67 99301-8496', '67 9301-8496'), isTrue);
      expect(mesmoTelefone('+55 67 99301-8496', '(67) 99301-8496'), isTrue);
      expect(mesmoTelefone('+55 67 99301-8496', '99301-8496'), isTrue);
      expect(mesmoTelefone('+55 67 99301-8496', '+55 11 99301-8496'), isFalse);
      expect(mesmoTelefone('', ''), isFalse);
    });

    test('acha o cliente que já tem o telefone', () {
      final clientes = [
        ClientModel(id: '1', nome: 'Ana', telefones: const ['11 91111-1111']),
        ClientModel(
            id: '2',
            nome: 'Ivete',
            telefones: const ['67 3384-1234', '+55 67 99301-8496']),
      ];
      expect(clienteComTelefone(clientes, '67993018496')?.nome, 'Ivete');
      expect(clienteComTelefone(clientes, '67 98888-7777'), isNull);
    });
  });
}
