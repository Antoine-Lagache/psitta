import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'statistic_screen.dart';
import 'setting_screen.dart';


class MainRouter extends StatefulWidget {
  const MainRouter({super.key});

  @override
  State<MainRouter> createState() => _MainRouterState();
  
} 

class _MainRouterState extends State<MainRouter> {
  int _currentIndex = 0;

  final List<Widget> _page = const [
    HomeScreen(),
    StatisticScreen(),
    SettingScreen()
  ];

  final List<PreferredSizeWidget Function(BuildContext)> _pageAppBars = [
  buildHomeAppBar,
  buildStatisticAppBar,
  buildSettingAppBar,
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _pageAppBars[_currentIndex](context),
      body: _page[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {_currentIndex = index;});
          },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "statistique"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "paramètre")
        ],
      )
    );
    
  }
}