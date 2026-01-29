import 'package:url_launcher/url_launcher.dart';

class LauncherUtils {
  // Abrir WhatsApp
  static Future<void> abrirWhatsApp(String telefone) async {
    // Limpa o número para garantir que só tenha dígitos
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse("https://wa.me/$numeroLimpo");
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o WhatsApp');
    }
  }

  // Abrir Google Maps
  static Future<void> abrirMaps(String endereco) async {
    final query = Uri.encodeComponent(endereco);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o Maps');
    }
  }
}