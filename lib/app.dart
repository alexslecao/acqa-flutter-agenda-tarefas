import 'package:material_ui/material_ui.dart';

import 'controllers/auth_controller.dart';
import 'controllers/task_controller.dart';
import 'screens/calendar_screen.dart';
import 'screens/login_screen.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';
import 'widgets/violet_backdrop.dart';

/// Raiz do aplicativo.
///
/// Cria o armazenamento local e os dois controladores de estado
/// ([AuthController] e [TaskController]) e decide qual tela mostrar:
/// carregamento, login/cadastro ou a área principal.
class AgendaApp extends StatefulWidget {
  const AgendaApp({super.key, this.store});

  /// Armazenamento alternativo (usado nos testes). Quando `null`, o app usa
  /// o armazenamento real do aparelho.
  final KeyValueStore? store;

  @override
  State<AgendaApp> createState() => _AgendaAppState();
}

class _AgendaAppState extends State<AgendaApp> {
  late final LocalStorageService _storage;
  late final AuthController _auth;
  late final TaskController _tasks;

  /// E-mail cujas tarefas estão carregadas no momento.
  String? _loadedEmail;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorageService(widget.store ?? SharedPreferencesStore());
    _auth = AuthController(_storage);
    _tasks = TaskController(_storage);
    _auth.addListener(_syncTasksWithSession);
    _auth.restoreSession();
  }

  @override
  void dispose() {
    _auth.removeListener(_syncTasksWithSession);
    _auth.dispose();
    _tasks.dispose();
    super.dispose();
  }

  /// Quando alguém entra ou sai, carrega ou limpa as tarefas dessa conta.
  void _syncTasksWithSession() {
    final email = _auth.currentUser?.email;
    if (email == _loadedEmail) return;
    _loadedEmail = email;
    if (email == null) {
      _tasks.clear();
    } else {
      _tasks.loadFor(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lavanda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          final Widget screen;
          if (_auth.isRestoring) {
            screen = const _SplashScreen(key: ValueKey<String>('splash'));
          } else if (_auth.currentUser == null) {
            screen = LoginScreen(
              key: const ValueKey<String>('login'),
              auth: _auth,
            );
          } else {
            screen = CalendarScreen(
              key: const ValueKey<String>('home'),
              auth: _auth,
              tasks: _tasks,
            );
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: screen,
          );
        },
      ),
    );
  }
}

/// Tela exibida enquanto o app verifica se havia uma sessão salva.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.deepViolet,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          VioletBackdrop(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppLogo(),
                SizedBox(height: 28),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
