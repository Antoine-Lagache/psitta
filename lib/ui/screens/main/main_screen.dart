import 'package:flutter/material.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/ui/screens/home/home_screen.dart';
import 'package:psitta/ui/screens/settings/settings_screen.dart';
import 'package:psitta/ui/screens/statistics/statistics_screen.dart';

/// Hosts the main application sections and preserves their state between tabs.
class MainScreen extends StatefulWidget {
  final SessionController sessionController;

  const MainScreen({required this.sessionController, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final List<Widget> _screens;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(sessionController: widget.sessionController),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectScreen,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _selectScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
