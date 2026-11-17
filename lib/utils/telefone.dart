import '../models/client_model.dart';

// Telefone vindo dos contatos do celular (RF-016, #115): chega em qualquer
// formato ("67993018496", "+55 (67) 99301-8496", "993018496"). A base
// importada da agenda usa "+55 67 99999-9999". A área de atendimento é
// Campo Grande: número sem DDD recebe o 67.
const dddPadrao = '67';

// Dígitos nacionais: DDD + número (10 ou 11 dígitos), ou null se não for um
// número brasileiro reconhecível.
String? _nacional(String bruto) {
  final texto = bruto.trim();
  var d = texto.replaceAll(RegExp(r'\D'), '');
  if (texto.startsWith('+')) {
    if (!d.startsWith('55')) return null; // internacional: fica como veio
    d = d.substring(2);
  } else {
    d = d.replaceFirst(RegExp(r'^0+'), ''); // 0 de longa distância
    if (d.length >= 12 && d.startsWith('55')) d = d.substring(2);
  }
  if (d.length == 8 || d.length == 9) d = '$dddPadrao$d';
  return d.length == 10 || d.length == 11 ? d : null;
}

String formatarTelefone(String bruto) {
  final d = _nacional(bruto);
  if (d == null) return bruto.trim();
  final numero = d.substring(2);
  final corte = numero.length - 4;
  return '+55 ${d.substring(0, 2)} ${numero.substring(0, corte)}-'
      '${numero.substring(corte)}';
}

// Mesmo número: DDD e os 8 últimos dígitos (com ou sem o nono dígito).
String? _chave(String telefone) {
  final d = _nacional(telefone);
  if (d == null) return null;
  return d.substring(0, 2) + d.substring(d.length - 8);
}

bool mesmoTelefone(String a, String b) {
  final ca = _chave(a);
  return ca != null && ca == _chave(b);
}

ClientModel? clienteComTelefone(List<ClientModel> clientes, String telefone) {
  for (final c in clientes) {
    if (c.telefones.any((t) => mesmoTelefone(t, telefone))) return c;
  }
  return null;
}
