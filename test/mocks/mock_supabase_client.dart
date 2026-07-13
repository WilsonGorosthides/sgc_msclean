import 'package:mocktail/mocktail.dart';
import 'package:sgc_msclean/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks reutilizáveis da cadeia do Supabase (nomes conferidos no
// supabase 2.10.2) e do service do app, no padrão mocktail
// (`extends Mock implements ...`, sem geração de código).
//
// Atenção: `SupabaseStreamBuilder` (retorno de `.order()`) estende `Stream`,
// então mockar a cadeia completa `from → stream → order → map` exigiria
// stubar métodos de `Stream`. Por isso a lógica de filtro da busca vive na
// função pura `SupabaseService.filtrarClientes`, testada sem mock — e os
// testes de widget injetam `MockSupabaseService` direto na tela.

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockSupabaseStreamFilterBuilder extends Mock
    implements SupabaseStreamFilterBuilder {}

class MockSupabaseService extends Mock implements SupabaseService {}
