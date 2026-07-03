import 'package:bloc_notes/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigates through the front-end base flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BlocNotesApp()));

    expect(find.text('Tus ideas, en calma'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesion').last);
    await tester.pumpAndSettle();
    expect(find.text('Mis notas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('RECIENTES'), findsOneWidget);
  });
}
