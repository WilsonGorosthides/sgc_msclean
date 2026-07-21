import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/endereco.dart';
import 'package:sgc_msclean/services/maps_launcher.dart';

// Testes unitários da montagem da URL do Google Maps (RF-009, #66): função
// pura, verificável sem o plugin url_launcher.
void main() {
  group('maps_launcher_test:', () {
    test('urlMaps monta a busca do Google Maps a partir do endereço', () {
      const e = Endereco(
          logradouro: 'Rua das Flores', numero: '10', bairro: 'Centro');

      final url = urlMaps(e);

      expect(url, isNotNull);
      expect(url!.host, 'www.google.com');
      expect(url.path, '/maps/search/');
      expect(url.queryParameters['api'], '1');
      // usa consultaMaps: campos de chegar + a âncora fixa Campo Grande - MS
      expect(url.queryParameters['query'],
          'Rua das Flores, 10, Centro, Campo Grande - MS');
    });

    test('urlMaps de endereço vazio é nula (nada a abrir)', () {
      expect(urlMaps(const Endereco()), isNull);
    });
  });
}
