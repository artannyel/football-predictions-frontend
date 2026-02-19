import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return _ScaffoldWithBottomNavBar(
          navigationShell: navigationShell,
          onDestinationSelected: _goBranch,
        );
      } else {
        return _ScaffoldWithNavigationRail(
          navigationShell: navigationShell,
          onDestinationSelected: _goBranch,
        );
      }
    });
  }
}

class _ScaffoldWithBottomNavBar extends StatelessWidget {
  const _ScaffoldWithBottomNavBar({
    required this.navigationShell,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(label: 'Ligas', icon: Icon(Icons.sports_soccer)),
          NavigationDestination(label: 'Ranking', icon: Icon(Icons.emoji_events)),
          NavigationDestination(label: 'Competições', icon: Icon(Icons.list)),
          NavigationDestination(label: 'Perfil', icon: Icon(Icons.person)),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

class _ScaffoldWithNavigationRail extends StatelessWidget {
  const _ScaffoldWithNavigationRail({
    required this.navigationShell,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            groupAlignment: -1.0,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(label: Text('Ligas'), icon: Icon(Icons.sports_soccer)),
              NavigationRailDestination(label: Text('Ranking'), icon: Icon(Icons.emoji_events)),
              NavigationRailDestination(label: Text('Competições'), icon: Icon(Icons.list)),
              NavigationRailDestination(label: Text('Perfil'), icon: Icon(Icons.person)),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}