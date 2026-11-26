import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../features/coach/coach_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/pricing/pricing_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/today/today_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.api, required this.onSignOut, super.key});

  final ApiClient api;
  final Future<void> Function() onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _selectedIndex = 0;

  static const _titles = ['Today', 'Goals', 'Progress', 'Coach', 'Profile'];

  Widget _currentPage() {
    switch (_selectedIndex) {
      case 1:
        return GoalsScreen(api: widget.api);
      case 2:
        return ProgressScreen(api: widget.api);
      case 3:
        return CoachScreen(api: widget.api);
      case 4:
        return ProfileScreen(api: widget.api, onSignOut: widget.onSignOut);
      default:
        return TodayScreen(api: widget.api);
    }
  }

  void _openPricing() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PricingScreen(api: widget.api)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/goalpath-logo.webp', width: 30, height: 30),
            const SizedBox(width: 10),
            Text(_titles[_selectedIndex]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pricing dan Premium',
            onPressed: _openPricing,
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
        ],
      ),
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
