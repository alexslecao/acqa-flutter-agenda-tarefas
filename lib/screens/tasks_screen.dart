import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';
import '../widgets/violet_backdrop.dart';

/// Tela Lista de Tarefas do dia selecionado.
///
/// Mostra primeiro as pendentes e depois as concluídas (cada grupo em ordem
/// alfabética) e permite adicionar, concluir/desmarcar e excluir tarefas.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.tasks});

  final TaskController tasks;

  static const String _saveError =
      'Não foi possível salvar a alteração no aparelho.';

  void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addTask(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final date = tasks.selectedDate;

    final draft = await showAddTaskSheet(context, date: date);
    if (draft == null) return;

    final saved = await tasks.addTask(
      title: draft.title,
      description: draft.description,
      date: date,
    );
    _showMessage(messenger, saved ? 'Tarefa adicionada.' : _saveError);
  }

  Future<void> _toggleTask(BuildContext context, Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await tasks.toggleDone(task.id);
    if (!saved) _showMessage(messenger, _saveError);
  }

  Future<bool> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
        title: const Text('Excluir tarefa?'),
        content: Text('"${task.title}" será removida da lista.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Remove a tarefa (a confirmação já foi feita por quem chama).
  Future<void> _deleteTask(ScaffoldMessengerState messenger, Task task) async {
    final saved = await tasks.removeTask(task.id);
    _showMessage(messenger, saved ? 'Tarefa excluída.' : _saveError);
  }

  Future<void> _confirmAndDelete(BuildContext context, Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirmDelete(context, task);
    if (confirmed) await _deleteTask(messenger, task);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addTask(context),
          backgroundColor: AppColors.mango,
          foregroundColor: AppColors.ink,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Nova tarefa',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: ListenableBuilder(
          listenable: tasks,
          builder: (context, _) {
            final date = tasks.selectedDate;
            final today = DateHelper.dateOnly(DateTime.now());

            return Column(
              children: <Widget>[
                _TasksHeader(
                  date: date,
                  today: today,
                  summary: tasks.summaryFor(date),
                  onBack: () => Navigator.of(context).maybePop(),
                  onPreviousDay: () {
                    tasks.selectDate(DateHelper.addDays(date, -1));
                  },
                  onNextDay: () {
                    tasks.selectDate(DateHelper.addDays(date, 1));
                  },
                ),
                Expanded(child: _buildBody(context, date)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DateTime date) {
    if (tasks.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = tasks.loadError;
    if (error != null) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Algo deu errado',
        message: error,
        action: FilledButton.icon(
          onPressed: tasks.reload,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    // tasksFor já devolve a lista na ordem exigida; aqui ela só é separada
    // nos dois grupos para ganhar os títulos de seção.
    final all = tasks.tasksFor(date);
    final pending = all.where((task) => !task.isDone).toList();
    final done = all.where((task) => task.isDone).toList();

    if (all.isEmpty) {
      return const EmptyState(
        icon: Icons.event_note_rounded,
        title: 'Nenhuma tarefa neste dia',
        message: 'Toque em "Nova tarefa" para planejar o que precisa ser '
            'feito.',
      );
    }

    Widget tile(Task task) {
      return TaskTile(
        key: ValueKey<String>(task.id),
        task: task,
        onToggle: () => _toggleTask(context, task),
        onDeletePressed: () => _confirmAndDelete(context, task),
        confirmDismiss: () => _confirmDelete(context, task),
        onDismissed: () => _deleteTask(ScaffoldMessenger.of(context), task),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: <Widget>[
            _SectionHeader(
              label: 'Pendentes',
              count: pending.length,
              color: AppColors.mango,
            ),
            if (pending.isEmpty)
              const _SectionHint(text: 'Nada pendente. Tudo em dia!')
            else
              for (final task in pending) tile(task),
            const SizedBox(height: 10),
            _SectionHeader(
              label: 'Concluídas',
              count: done.length,
              color: AppColors.mint,
            ),
            if (done.isEmpty)
              const _SectionHint(
                text: 'As tarefas marcadas como feitas aparecem aqui.',
              )
            else
              for (final task in done) tile(task),
          ],
        ),
      ),
    );
  }
}

class _TasksHeader extends StatelessWidget {
  const _TasksHeader({
    required this.date,
    required this.today,
    required this.summary,
    required this.onBack,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final DateTime date;
  final DateTime today;
  final DaySummary summary;
  final VoidCallback onBack;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  String get _progressText {
    if (summary.isEmpty) return 'Nenhuma tarefa cadastrada';
    final done = summary.done == 1
        ? '1 concluída'
        : '${summary.done} concluídas';
    final pending = summary.pending == 1
        ? '1 pendente'
        : '${summary.pending} pendentes';
    return '$pending · $done';
  }

  @override
  Widget build(BuildContext context) {
    return VioletBackdrop(
      showAccents: false,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: onBack,
                    tooltip: 'Voltar ao calendário',
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        'Lista de tarefas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: onPreviousDay,
                    tooltip: 'Dia anterior',
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          DateHelper.relativeLabel(date, today),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateHelper.dayAndMonth(date)} de ${date.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.lavender,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onNextDay,
                    tooltip: 'Próximo dia',
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: summary.progress,
                        minHeight: 8,
                        backgroundColor: const Color(0x33FFFFFF),
                        color: AppColors.mango,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _progressText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Semantics(
        header: true,
        label: '$label: $count',
        excludeSemantics: true,
        child: Row(
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.violet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
      ),
    );
  }
}
