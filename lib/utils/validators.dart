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

  // Telefone: apenas dígitos, espaços e os símbolos + ( ) - (RF-001).
  static String? telefone(String? valor) {
    final pendente = obrigatorio(valor, 'telefone');
    if (pendente != null) return pendente;
    if (!RegExp(r'^[\d\s()+\-]+$').hasMatch(valor!.trim())) {
      return 'Use apenas dígitos, espaços e + ( ) -';
    }
    return null;
  }
}
