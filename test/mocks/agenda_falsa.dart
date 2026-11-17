import 'package:sgc_msclean/services/contatos.dart';

// Seletor de contatos do Android trocado por um falso (RF-016): devolve o
// contato combinado no teste, ou nada (ela desistiu de escolher).
class AgendaFalsa implements AgendaDoCelular {
  AgendaFalsa([this.contato]);

  Contato? contato;
  int aberturas = 0;

  @override
  bool get disponivel => true;

  @override
  Future<Contato?> escolher() async {
    aberturas++;
    return contato;
  }
}
