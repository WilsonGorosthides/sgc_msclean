import 'package:flutter/material.dart';

import 'demo/servico_de_demonstracao.dart';
import 'main.dart';

// Modo demonstração (#139): o app com dados fictícios em memória, sem .env e
// sem Supabase. Para os prints do README e para mostrar o app sem expor
// clientes reais:
//   fvm flutter run -d chrome -t lib/main_demo.dart
void main() {
  runApp(MyApp(inicio: telaDeDemonstracao()));
}
