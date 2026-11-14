// Funções puras de validação do formulário de cliente (RF-001/RF-002),
// testáveis sem montar widget. Retornam null quando o valor é válido,
// no contrato de TextFormField.validator.
class Validadores {
  // Campo obrigatório após trim(): vazio, nulo ou só espaços é rejeitado.
  static String? obrigatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o $campo';
    }
    return null;
  }

  // Telefone: apenas dígitos, espaços e os símbolos + ( ) -, com no mínimo
  // 8 dígitos — só dígitos contam no piso, que aceita fixo local sem DDD
  // (RF-001, decisão da issue #48).
  static String? telefone(String? valor) {
    final pendente = obrigatorio(valor, 'telefone');
    if (pendente != null) return pendente;
    if (!RegExp(r'^[\d\s()+\-]+$').hasMatch(valor!.trim())) {
      return 'Use apenas dígitos, espaços e + ( ) -';
    }
    if (valor.replaceAll(RegExp(r'\D'), '').length < 8) {
      return 'Telefone deve ter pelo menos 8 dígitos';
    }
    return null;
  }
  // Hora opcional do atendimento (RF-005): vazio é válido; preenchido tem que
  // ser algo que completarHora entenda.
  static String? hora(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    return completarHora(texto) == null
        ? 'Hora inválida. Ex.: 8, 830 ou 14:30'
        : null;
  }

  // Completa a digitação abreviada para HH:MM: "8" -> 08:00, "830" -> 08:30,
  // "1430" -> 14:30, "8h30" -> 08:30, "9:00" -> 09:00. Nulo se vazio ou se não
  // der uma hora válida (0-23) com minuto válido (0-59).
  static String? completarHora(String texto) {
    final t = texto.trim().toLowerCase().replaceAll('h', ':');
    int h;
    int m;
    final comSeparador = RegExp(r'^(\d{1,2}):(\d{0,2})$').firstMatch(t);
    if (comSeparador != null) {
      h = int.parse(comSeparador.group(1)!);
      final minuto = comSeparador.group(2)!;
      m = minuto.isEmpty ? 0 : int.parse(minuto);
    } else if (RegExp(r'^\d{1,2}$').hasMatch(t)) {
      h = int.parse(t);
      m = 0;
    } else if (RegExp(r'^\d{3,4}$').hasMatch(t)) {
      h = int.parse(t.substring(0, t.length - 2));
      m = int.parse(t.substring(t.length - 2));
    } else {
      return null;
    }
    if (h > 23 || m > 59) return null;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
