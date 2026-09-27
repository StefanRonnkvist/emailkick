import 'package:emailkick/data/contact/contact_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('shows AAB and MSIX version numbers', (
    WidgetTester tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'EmailKick',
      packageName: 'com.example.emailkick',
      version: '0.4.10',
      buildNumber: '17',
      buildSignature: '',
    );

    await tester.pumpWidget(
      MaterialApp(home: createContactPage(serverUrl: 'https://example.com')),
    );
    await tester.pumpAndSettle();

    expect(find.text('0.4.10 (build 17)'), findsNWidgets(2));
  });
}
