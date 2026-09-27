import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:emailkick/app/splash_screen.dart';
import 'package:emailkick/core/storage/app_db.dart';
import 'package:emailkick/features/email_composer/presentation/email_composer_page.dart';

class WebDatabaseNotice extends StatefulWidget {
  const WebDatabaseNotice({super.key});

  @override
  State<WebDatabaseNotice> createState() => _WebDatabaseNoticeState();
}

class _WebDatabaseNoticeState extends State<WebDatabaseNotice> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    const Color noticeColor = Color(0xFFF8DDDD);
    const Color contentColor = Color(0xFF941E1B);

    return Material(
      color: noticeColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 78),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
          child: Row(
            children: <Widget>[
              const Icon(Icons.warning_rounded, color: contentColor, size: 34),
              const SizedBox(width: 18),
              const Expanded(
                child: Text(
                  'PWA notice: database functions are not available on web builds. Data is temporary for this browser session only.',
                  style: TextStyle(
                    color: contentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss notice',
                onPressed: () => setState(() => _isVisible = false),
                icon: const Icon(Icons.close, color: contentColor, size: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6F5C)),
        useMaterial3: true,
      ),
      home: SplashScreen(
        initialize: AppDb.instance.init,
        child: Column(
          children: <Widget>[
            if (kIsWeb) const WebDatabaseNotice(),
            const Expanded(child: EmailComposerPage()),
          ],
        ),
      ),
    );
  }
}
