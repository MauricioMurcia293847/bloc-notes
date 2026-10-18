import 'package:bloc_notes/app/app.dart';
import 'package:bloc_notes/core/services/supabase_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const ProviderScope(child: BlocNotesApp()));
}
