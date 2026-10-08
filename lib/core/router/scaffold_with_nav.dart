import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root scaffold with the Material 3 bottom navigation bar.
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school_rounded),
      label: 'Learn',
    ),
    NavigationDestination(
      icon: Icon(Icons.record_voice_over_outlined),
      selectedIcon: Icon(Icons.record_voice_over_rounded),
      label: 'Interview',
    ),
    NavigationDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz_rounded),
      label: 'Quiz',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          destinations: _destinations,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
    );
  }
}
