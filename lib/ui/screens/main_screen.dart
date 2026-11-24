// [ShelfMate Dev Step 1/2]: Create MainScreen shell with 5-tab NavigationBar
import 'package:material_ui/material_ui.dart';
import '../../state/app_state.dart';
import 'borrowers/borrowers_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'items/items_screen.dart';
import 'settings/settings_screen.dart';
import 'stats/stats_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    ItemsScreen(),
    BorrowersScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);

    return Scaffold(
      body: IndexedStack(
        index: appState.selectedNavIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.selectedNavIndex,
        onDestinationSelected: (index) => appState.setNavIndex(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Items',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Borrowers',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
