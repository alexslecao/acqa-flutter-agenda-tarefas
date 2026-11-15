import 'package:acqa_agenda_tarefas/app.dart';
import 'package:acqa_agenda_tarefas/controllers/auth_controller.dart';
import 'package:acqa_agenda_tarefas/controllers/task_controller.dart';
import 'package:acqa_agenda_tarefas/models/task.dart';
import 'package:acqa_agenda_tarefas/services/local_storage_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 11, 15);
  final nextDay = DateTime(2026, 11, 16);

  group('Ordenação das tarefas', () {
    Task task(String title, {bool done = false}) {
      return Task(
        id: title,
        title: title,
        date: day,
        createdAt: day,
        isDone: done,
      );
    }

    test('pendentes primeiro; cada grupo em ordem alfabética', () {
      final sorted = Task.sorted(<Task>[
        task('Zebra', done: true),
        task('banco'),
        task('Água'),
        task('aula', done: true),
        task('Compras'),
      ]);

      expect(
        sorted.map((item) => item.title).toList(),
        <String>['Água', 'banco', 'Compras', 'aula', 'Zebra'],
      );
    });
  });

  group('TaskController', () {
    late InMemoryStore store;
    late TaskController controller;

    setUp(() async {
      store = InMemoryStore();
      controller = TaskController(
        LocalStorageService(store),
        initialDate: day,
      );
      await controller.loadFor('ana@exemplo.com');
    });

    test('adiciona, conclui, desmarca e exclui', () async {
      expect(await controller.addTask(title: '  Estudar Flutter  '), isTrue);
      expect(await controller.addTask(title: '   '), isFalse);

      final added = controller.tasksFor(day);
      expect(added, hasLength(1));
      expect(added.single.title, 'Estudar Flutter');
      expect(added.single.isDone, isFalse);

      final id = added.single.id;
      await controller.toggleDone(id);
      expect(controller.tasksFor(day).single.isDone, isTrue);
      await controller.toggleDone(id);
      expect(controller.tasksFor(day).single.isDone, isFalse);

      expect(await controller.removeTask(id), isTrue);
      expect(controller.tasksFor(day), isEmpty);
    });

    test('ao concluir, a tarefa passa para depois das pendentes', () async {
      await controller.addTask(title: 'Academia');
      await controller.addTask(title: 'Mercado');
      final first = controller.tasksFor(day).first;
      expect(first.title, 'Academia');

      await controller.toggleDone(first.id);

      expect(
        controller.tasksFor(day).map((item) => item.title).toList(),
        <String>['Mercado', 'Academia'],
      );
      expect(controller.summaryFor(day).pending, 1);
      expect(controller.summaryFor(day).done, 1);
    });

    test('tarefas ficam salvas, separadas por dia e por conta', () async {
      await controller.addTask(title: 'Reunião');
      await controller.addTask(title: 'Dentista', date: nextDay);

      final reopened = TaskController(
        LocalStorageService(store),
        initialDate: day,
      );
      await reopened.loadFor('ana@exemplo.com');
      expect(
        reopened.tasksFor(day).map((item) => item.title).toList(),
        <String>['Reunião'],
      );
      expect(
        reopened.tasksFor(nextDay).map((item) => item.title).toList(),
        <String>['Dentista'],
      );

      await reopened.loadFor('bia@exemplo.com');
      expect(reopened.tasksFor(day), isEmpty);
    });
  });

  group('AuthController (login local demonstrativo)', () {
    test('cadastra, recusa e-mail repetido e confere a senha', () async {
      final store = InMemoryStore();
      final auth = AuthController(LocalStorageService(store));
      await auth.restoreSession();
      expect(auth.isRestoring, isFalse);
      expect(auth.currentUser, isNull);

      expect(
        await auth.signUp(
          name: 'Ana Souza',
          email: ' Ana@Exemplo.com ',
          password: 'segredo1',
        ),
        isNull,
      );
      expect(auth.currentUser?.email, 'ana@exemplo.com');
      expect(auth.currentUser?.firstName, 'Ana');

      expect(
        await auth.signUp(
          name: 'Outra Ana',
          email: 'ana@exemplo.com',
          password: 'outra123',
        ),
        isNotNull,
      );

      await auth.signOut();
      expect(auth.currentUser, isNull);

      expect(
        await auth.signIn(email: 'ana@exemplo.com', password: 'errada'),
        isNotNull,
      );
      expect(
        await auth.signIn(email: 'ANA@exemplo.com', password: 'segredo1'),
        isNull,
      );

      // A sessão é recuperada ao "reabrir" o app.
      final reopened = AuthController(LocalStorageService(store));
      await reopened.restoreSession();
      expect(reopened.currentUser?.email, 'ana@exemplo.com');

      // A senha não é gravada em texto puro.
      final rawUsers = await store.read('lavanda.users');
      expect(rawUsers, isNotNull);
      expect(rawUsers!.contains('segredo1'), isFalse);
    });
  });

  group('Interface', () {
    testWidgets('sem sessão salva, abre na tela de login', (tester) async {
      await tester.pumpWidget(AgendaApp(store: InMemoryStore()));
      await tester.pumpAndSettle();

      expect(find.text('Entrar na conta'), findsOneWidget);
      expect(find.text('Lavanda'), findsOneWidget);
    });

    testWidgets('cadastro abre o calendário e a lista aceita nova tarefa',
        (tester) async {
      await tester.pumpWidget(AgendaApp(store: InMemoryStore()));
      await tester.pumpAndSettle();

      // Cadastro.
      await tester.tap(find.text('Cadastro'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Ana Souza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'),
        'ana@exemplo.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'segredo1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar senha'),
        'segredo1',
      );
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      // Tela principal (calendário).
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Hoje'), findsWidgets);

      // Lista de tarefas.
      await tester.ensureVisible(find.text('Abrir lista de tarefas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir lista de tarefas'));
      await tester.pumpAndSettle();
      expect(find.text('Lista de tarefas'), findsOneWidget);
      expect(find.text('Nenhuma tarefa neste dia'), findsOneWidget);

      // Título vazio não é aceito.
      await tester.tap(find.text('Nova tarefa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe um título para a tarefa.'), findsOneWidget);

      // Com título, a tarefa entra na lista como pendente.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Estudar Flutter',
      );
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();

      expect(find.text('Estudar Flutter'), findsOneWidget);
      expect(find.text('Pendentes'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });
}
