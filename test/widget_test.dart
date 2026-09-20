// Basic Flutter widget test for Khedne Ma3ak app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lebanon_places/main.dart';

void main() {
  testWidgets('App loads and shows home content', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LebanonPlacesApp()));

    await tester.pumpAndSettle();

    expect(find.text('Lebanon Places'), findsOneWidget);
    expect(find.text('Discover places in Lebanon'), findsOneWidget);
  });
}
