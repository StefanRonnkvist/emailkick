import 'dart:async';

import 'package:flutter/material.dart';

/// Holds the splash screen until initialization and a minimum display time end.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.initialize,
    required this.child,
    this.minimumDuration = const Duration(milliseconds: 1400),
    super.key,
  });

  final Future<void> Function() initialize;
  final Widget child;
  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    unawaited(_initialize());
  }

  /// Runs initialization and the display timer concurrently, exposing retry UI.
  Future<void> _initialize() async {
    setState(() => _hasError = false);

    try {
      await Future.wait<void>(<Future<void>>[
        widget.initialize(),
        Future<void>.delayed(widget.minimumDuration),
      ]);
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _isReady ? widget.child : _buildSplash(),
    );
  }

  Widget _buildSplash() {
    const Color ink = Color(0xFF13231F);
    const Color green = Color(0xFF1E6F5C);
    const Color mint = Color(0xFFBFE3D5);

    return Scaffold(
      key: const ValueKey<String>('splash'),
      backgroundColor: ink,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FadeTransition(
                  opacity: Tween<double>(begin: 0.72, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x5534B48F),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/play_store_512.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'eMail Kick',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _hasError
                      ? 'Could not finish starting the app.'
                      : 'Loading...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: mint,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 26),
                if (_hasError)
                  FilledButton.icon(
                    onPressed: _initialize,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ink,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  )
                else
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: green,
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
