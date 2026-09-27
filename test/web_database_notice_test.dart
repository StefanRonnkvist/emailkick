import 'package:emailkick/app/main_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web database notice matches copy and can be dismissed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WebDatabaseNotice())),
    );

    expect(
      find.text(
        'PWA notice: database functions are not available on web builds. Data is temporary for this browser session only.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.warning_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss notice'));
    await tester.pump();

    expect(find.textContaining('PWA notice:'), findsNothing);
  });
}
