import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/endereco.dart';

// Testes unitários do value object Endereco (endereço estruturado, #65):
// ida e volta jsonb e os getters derivados usados pela lista (resumo), pela
// busca (buscavel) e pelo Google Maps (consultaMaps).
void main() {
  group('endereco_test:', () {
    test('ida e volta toMap/fromMap preserva os campos', () {
      const original = Endereco(
        logradouro: 'Rua das Flores',
        numero: '10',
        bairro: 'Centro',
        complemento: 'Bloco B, apto 42',
        referencia: 'Ao lado da padaria',
      );

      final reconstruido = Endereco.fromMap(original.toMap());

      expect(reconstruido, original);
    });

    test('fromMap com nulo ou campos ausentes usa vazio', () {
      expect(Endereco.fromMap(null), const Endereco());

      final parcial = Endereco.fromMap({'logradouro': 'Rua A'});
      expect(parcial.logradouro, 'Rua A');
      expect(parcial.numero, '');
      expect(parcial.bairro, '');
    });

    test('vazio é true só quando todos os campos estão em branco', () {
      expect(const Endereco().vazio, isTrue);
      expect(const Endereco(bairro: '   ').vazio, isTrue); // só espaços
      expect(const Endereco(bairro: 'Centro').vazio, isFalse);
    });

    test('resumo monta uma linha legível a partir das partes', () {
      const completo = Endereco(
          logradouro: 'Rua das Flores', numero: '10', bairro: 'Centro');
      expect(completo.resumo, 'Rua das Flores, 10 - Centro');

      const soRua = Endereco(logradouro: 'Rua das Flores', numero: '10');
      expect(soRua.resumo, 'Rua das Flores, 10');
    });

    test('buscavel concatena os campos em minúsculas', () {
      const e = Endereco(
          logradouro: 'Rua das Flores',
          bairro: 'Centro',
          referencia: 'Perto da Padaria');
      expect(e.buscavel, contains('flores'));
      expect(e.buscavel, contains('centro'));
      expect(e.buscavel, contains('padaria'));
    });

    test('consultaMaps usa os campos de chegar, sem complemento/referência', () {
      const e = Endereco(
        logradouro: 'Rua das Flores',
        numero: '10',
        bairro: 'Centro',
        complemento: 'Bloco B, apto 42',
        referencia: 'Ao lado da padaria',
      );

      // Campo Grande - MS entra como âncora fixa: a base é toda da cidade e,
      // sem ela, o endereço fica ambíguo no Maps.
      expect(e.consultaMaps, 'Rua das Flores, 10, Centro, Campo Grande - MS');
      expect(e.consultaMaps, isNot(contains('Bloco B')));
      expect(e.consultaMaps, isNot(contains('padaria')));
    });

    test('consultaMaps de endereço vazio é vazia (sem âncora sozinha)', () {
      expect(const Endereco().consultaMaps, '');
    });
  });
}
