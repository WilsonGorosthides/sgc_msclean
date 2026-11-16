import 'package:shared_preferences/shared_preferences.dart';

// Onde o app guarda texto no próprio aparelho (RNF-007, #94): a última agenda,
// a última lista de clientes e a fila de envios. Interface mínima — chave e
// texto (JSON) — para os testes trocarem o shared_preferences por memória.
abstract class ArmazemLocal {
  Future<String?> ler(String chave);
  Future<void> gravar(String chave, String valor);
}

// Produção: shared_preferences (arquivo no Android, localStorage na web).
// A instância só é aberta no primeiro uso.
class ArmazemPreferencias implements ArmazemLocal {
  Future<SharedPreferences>? _prefs;

  Future<SharedPreferences> get _instancia =>
      _prefs ??= SharedPreferences.getInstance();

  @override
  Future<String?> ler(String chave) async =>
      (await _instancia).getString(chave);

  @override
  Future<void> gravar(String chave, String valor) async {
    await (await _instancia).setString(chave, valor);
  }
}

// Testes: um mapa em memória. Sobrevive ao EspelhoLocal que o usa, como o
// shared_preferences sobrevive a fechar o app.
class ArmazemEmMemoria implements ArmazemLocal {
  final Map<String, String> dados = {};

  @override
  Future<String?> ler(String chave) async => dados[chave];

  @override
  Future<void> gravar(String chave, String valor) async {
    dados[chave] = valor;
  }
}
