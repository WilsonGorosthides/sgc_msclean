import 'package:url_launcher/url_launcher.dart';
import '../models/endereco.dart';

// Abertura do endereço no Google Maps (RF-009, #66). A montagem da URL é uma
// função pura (`urlMaps`), testável sem o plugin; `abrirEnderecoNoMaps` faz o
// disparo real via url_launcher.

// URL de busca do Google Maps para o endereço, ou null quando não há o que
// abrir (endereço sem os campos de "chegar"). Universal (Android + web).
Uri? urlMaps(Endereco endereco) {
  final consulta = endereco.consultaMaps;
  if (consulta.isEmpty) return null;
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': consulta,
  });
}

// Abre o endereço no Google Maps em app externo; no-op silencioso quando não
// há endereço a abrir.
Future<void> abrirEnderecoNoMaps(Endereco endereco) async {
  final url = urlMaps(endereco);
  if (url == null) return;
  await launchUrl(url, mode: LaunchMode.externalApplication);
}
