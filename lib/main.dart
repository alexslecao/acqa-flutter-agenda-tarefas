import 'package:material_ui/material_ui.dart';

import 'app.dart';

/// Ponto de entrada do aplicativo Lavanda (calendário e tarefas diárias).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgendaApp());
}
