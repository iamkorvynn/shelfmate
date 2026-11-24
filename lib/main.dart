// [ShelfMate Dev Step 1/2]: Create main entry point with MultiProvider and AppState
import 'package:material_ui/material_ui.dart';
import 'state/app_state.dart';
import 'ui/screens/main_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();

  runApp(ShelfMateApp(appState: appState));
}

class ShelfMateApp extends StatelessWidget {
  final AppState? appState;

  const ShelfMateApp({super.key, this.appState});

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      appState: appState ?? AppState(),
      child: MaterialApp(
        title: 'ShelfMate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}
