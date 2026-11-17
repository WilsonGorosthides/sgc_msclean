import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Contatos do celular (RF-016, #115). O seletor é o do próprio Android
// (ACTION_PICK no número de telefone): o app recebe só o contato que ela
// tocou, sem permissão de ler a agenda inteira.
class Contato {
  const Contato({required this.nome, required this.telefone});

  final String nome;
  final String telefone; // como está no celular; formatar ao usar
}

abstract class AgendaDoCelular {
  // Fora do Android não há seletor: o botão não aparece.
  bool get disponivel;

  // null quando ela volta sem escolher.
  Future<Contato?> escolher();
}

// Android: canal com a MainActivity (Kotlin), sem plugin — mesmo molde da
// liberação de bateria (#101).
class ContatosDoAparelho implements AgendaDoCelular {
  static const _canal = MethodChannel('msclean/contatos');

  @override
  bool get disponivel =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<Contato?> escolher() async {
    if (!disponivel) return null;
    try {
      final r = await _canal.invokeMapMethod<String, String>('escolher');
      if (r == null) return null;
      final telefone = (r['telefone'] ?? '').trim();
      if (telefone.isEmpty) return null;
      return Contato(nome: (r['nome'] ?? '').trim(), telefone: telefone);
    } catch (_) {
      return null; // aparelho sem o seletor: fica a digitação
    }
  }
}
