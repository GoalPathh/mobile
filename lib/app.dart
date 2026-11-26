import 'package:flutter/material.dart';

import 'data/api_client.dart';
import 'features/auth/login_screen.dart';
import 'navigation/app_shell.dart';
import 'theme/app_theme.dart';

class GoalPathApp extends StatefulWidget {
  const GoalPathApp({super.key});

  @override
  State<GoalPathApp> createState() => _GoalPathAppState();
}

class _GoalPathAppState extends State<GoalPathApp> {
  final _api = ApiClient();
  var _checkingSession = true;
  var _authenticated = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final hasSession = await _api.hasSession();
    if (!mounted) return;
    setState(() {
      _authenticated = hasSession;
      _checkingSession = false;
    });
  }

  void _onAuthenticated() => setState(() => _authenticated = true);

  Future<void> _onSignOut() async {
    await _api.signOut();
    if (mounted) setState(() => _authenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoalPath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: _checkingSession
          ? const _StartupScreen()
          : _authenticated
          ? AppShell(api: _api, onSignOut: _onSignOut)
          : LoginScreen(api: _api, onAuthenticated: _onAuthenticated),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/goalpath-logo.webp', width: 72, height: 72),
            const SizedBox(height: 18),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text('Memuat GoalPath…'),
          ],
        ),
      ),
    );
  }
}
