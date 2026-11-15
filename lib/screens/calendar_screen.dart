import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';
import '../widgets/month_calendar.dart';
import '../widgets/violet_backdrop.dart';
import 'tasks_screen.dart';

/// Tela principal: saudação, data selecionada, calendário e acesso à lista
/// de tarefas do dia.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.auth, required this.tasks});

  final AuthController auth;
  final TaskController tasks;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Mês que o calendário está exibindo (pode ser diferente do mês do dia
  /// selecionado enquanto o usuário navega).
  late DateTime _visibleMonth;
  late DateTime _lastSelected;

  @override
  void initState() {
    super.initState();
    _lastSelected = widget.tasks.selectedDate;
    _visibleMonth = DateHelper.firstDayOfMonth(_lastSelected);
    widget.tasks.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    widget.tasks.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    if (!mounted) return;
    setState(() {
      // Se o dia selecionado mudou (aqui ou na tela de tarefas), o calendário
      // acompanha e passa a mostrar o mês desse dia.
      final selected = widget.tasks.selectedDate;
      if (!DateHelper.isSameDay(selected, _lastSelected)) {
        _lastSelected = selected;
        _visibleMonth = DateHelper.firstDayOfMonth(selected);
      }
    });
  }

  void _goToToday() {
    final today = DateHelper.dateOnly(DateTime.now());
    setState(() => _visibleMonth = DateHelper.firstDayOfMonth(today));
    widget.tasks.selectDate(today);
  }

  void _openTasks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TasksScreen(tasks: widget.tasks),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Sair da conta?'),
        content: const Text(
          'Suas tarefas continuam salvas neste aparelho e voltam a aparecer '
          'no próximo login.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final now = DateTime.now();
    final today = DateHelper.dateOnly(now);
    final selected = tasks.selectedDate;
    final user = widget.auth.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HomeHeader(
                greeting: DateHelper.greetingFor(now),
                name: user?.firstName ?? 'visitante',
                selectedDate: selected,
                onSignOut: _confirmSignOut,
              ),
              // O conteúdo sobe um pouco para o calendário "encaixar" no
              // cabeçalho violeta.
              Transform.translate(
                offset: const Offset(0, -56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _CalendarCard(
                            child: MonthCalendar(
                              visibleMonth: _visibleMonth,
                              selectedDate: selected,
                              today: today,
                              summaryOf: tasks.summaryFor,
                              onDaySelected: tasks.selectDate,
                              onMonthChanged: (month) {
                                setState(() => _visibleMonth = month);
                              },
                              onGoToToday: _goToToday,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DayCard(
                            date: selected,
                            today: today,
                            isLoading: tasks.isLoading,
                            loadError: tasks.loadError,
                            summary: tasks.summaryFor(selected),
                            preview: tasks.tasksFor(selected),
                            onOpenTasks: _openTasks,
                            onRetry: tasks.reload,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.selectedDate,
    required this.onSignOut,
  });

  final String greeting;
  final String name;
  final DateTime selectedDate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return VioletBackdrop(
      showAccents: false,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 10, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$greeting,',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.lavender,
                          ),
                        ),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onSignOut,
                    tooltip: 'Sair da conta',
                    icon: const Icon(Icons.logout_rounded),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.event_available_rounded,
                        size: 20,
                        color: AppColors.mango,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          DateHelper.capitalize(
                            DateHelper.fullDate(selectedDate),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          child,
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: <Widget>[
                _LegendItem(color: AppColors.mango, label: 'Com pendências'),
                _LegendItem(color: AppColors.mint, label: 'Tudo concluído'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

/// Cartão com o resumo do dia selecionado e o botão que abre a lista.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.today,
    required this.isLoading,
    required this.loadError,
    required this.summary,
    required this.preview,
    required this.onOpenTasks,
    required this.onRetry,
  });

  static const int _previewLimit = 3;

  final DateTime date;
  final DateTime today;
  final bool isLoading;
  final String? loadError;
  final DaySummary summary;
  final List<Task> preview;
  final VoidCallback onOpenTasks;
  final VoidCallback onRetry;

  String get _summaryText {
    if (summary.isEmpty) return 'Nenhuma tarefa neste dia';
    if (summary.allDone) return 'Tudo concluído por aqui';
    return summary.pending == 1
        ? '1 tarefa pendente'
        : '${summary.pending} tarefas pendentes';
  }

  @override
  Widget build(BuildContext context) {
    final error = loadError;
    final shown = preview.take(_previewLimit).toList();
    final hidden = preview.length - shown.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${DateHelper.relativeLabel(date, today)} · '
                      '${DateHelper.dayAndMonth(date)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading ? 'Carregando tarefas…' : _summaryText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ProgressRing(summary: summary, isLoading: isLoading),
            ],
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ),
          ],
          if (shown.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            for (final task in shown) _PreviewLine(task: task),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 2),
                child: Text(
                  hidden == 1 ? '+ 1 outra tarefa' : '+ $hidden outras tarefas',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: onOpenTasks,
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Abrir lista de tarefas'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isDone ? AppColors.mint : AppColors.mango,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDone ? AppColors.inkSoft : AppColors.ink,
                decoration:
                    isDone ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anel de progresso "concluídas/total" do dia.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.summary, required this.isLoading});

  final DaySummary summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CircularProgressIndicator(
            value: isLoading ? null : summary.progress,
            strokeWidth: 6,
            backgroundColor: AppColors.lavender,
            color: summary.allDone ? AppColors.mint : AppColors.violet,
          ),
          if (!isLoading)
            Center(
              child: ExcludeSemantics(
                child: Text(
                  '${summary.done}/${summary.total}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
