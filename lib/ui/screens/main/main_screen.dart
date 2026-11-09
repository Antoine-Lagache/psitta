import 'dart:async';

import 'package:flutter/material.dart';
import 'package:psitta/application/startup/content_release_state.dart';
import 'package:psitta/application/controllers/progress_controller.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/controllers/settings_controller.dart';
import 'package:psitta/application/controllers/statistic_controller.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/screens/home/home_screen.dart';
import 'package:psitta/ui/screens/settings/settings_screen.dart';
import 'package:psitta/ui/screens/statistics/statistics_screen.dart';
import 'package:psitta/ui/theme/app_theme.dart';

/// Hosts the main application sections and preserves their state between tabs.
class MainScreen extends StatefulWidget {
  final SessionController sessionController;
  final ProgressController progressController;
  final StatisticController statisticController;
  final SettingsController settingsController;
  final ContentRenderer contentRenderer;
  final ContentReleaseState contentReleaseState;
  final ValueNotifier<AppThemeVariant>? themeVariant;

  const MainScreen({
    required this.sessionController,
    required this.progressController,
    required this.statisticController,
    required this.settingsController,
    required this.contentRenderer,
    required this.contentReleaseState,
    this.themeVariant,
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _reviewLimitKey = 'sessions.reviews.max_count.v2';
  static const _legacyReviewLimitKey = 'sessions.reviews.max_count';

  final _statisticsRefreshSignal = ValueNotifier(0);
  final _homeRefreshSignal = ValueNotifier(0);
  int _selectedIndex = 0;
  bool _characterSessionsEnabled = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final savedEnabled = await widget.settingsController.get(
      'sessions.characters.enabled',
    );
    final values = await Future.wait([
      widget.settingsController.get('sessions.words.new_count'),
      widget.settingsController.get('sessions.sentences.new_count'),
      widget.settingsController.get('sessions.characters.new_count'),
      widget.settingsController.get(_reviewLimitKey),
      widget.settingsController.get(_legacyReviewLimitKey),
    ]);
    var reviewCount = int.tryParse(values[3] ?? '') ?? -1;
    if (values[3] == null && values[4] != null) {
      reviewCount = int.tryParse(values[4]!) ?? -1;
      if (reviewCount == 9999) reviewCount = -1;
      await widget.settingsController.set(_reviewLimitKey, '$reviewCount');
    }
    widget.sessionController.updateSessionLimits(
      newWordCount: int.tryParse(values[0] ?? '') ?? 4,
      newSentenceCount: int.tryParse(values[1] ?? '') ?? 3,
      newCharacterCount: int.tryParse(values[2] ?? '') ?? 5,
      reviewCount: reviewCount,
    );
    if (!mounted) return;
    setState(() {
      _characterSessionsEnabled = savedEnabled != 'false';
      _homeRefreshSignal.value++;
    });
  }

  @override
  void dispose() {
    _statisticsRefreshSignal.dispose();
    _homeRefreshSignal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildSelectedScreen(),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildSelectedScreen() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(
          key: const ValueKey('home'),
          sessionController: widget.sessionController,
          contentRenderer: widget.contentRenderer,
          contentReleaseState: widget.contentReleaseState,
          characterSessionsEnabled: _characterSessionsEnabled,
          refreshSignal: _homeRefreshSignal,
        ),
        StatisticsScreen(
          key: const ValueKey('statistics'),
          refreshSignal: _statisticsRefreshSignal,
          statisticController: widget.statisticController,
        ),
        SettingsScreen(
          key: const ValueKey('settings'),
          settingsController: widget.settingsController,
          sessionController: widget.sessionController,
          progressController: widget.progressController,
          themeVariant: widget.themeVariant,
          onCharacterSessionsChanged: (enabled) => setState(() {
            _characterSessionsEnabled = enabled;
          }),
          onSessionLimitsChanged: () => _homeRefreshSignal.value++,
          onProgressChanged: () {
            _homeRefreshSignal.value++;
            _statisticsRefreshSignal.value++;
          },
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
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
    );
  }

  void _selectScreen(int index) {
    if (index == 1) {
      _statisticsRefreshSignal.value++;
    }
    setState(() {
      _selectedIndex = index;
    });
  }
}
