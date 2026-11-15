import 'package:material_ui/material_ui.dart';

import '../controllers/task_controller.dart';
import '../theme/app_theme.dart';
import '../utils/date_helper.dart';

/// Calendário mensal próprio do app (sem pacote externo).
///
/// Permite navegar entre meses pelas setas ou arrastando para os lados, e
/// selecionar um dia. Cada dia mostra um ponto quando tem tarefas: laranja se
/// há pendências, verde se todas estão concluídas.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.today,
    required this.summaryOf,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.onGoToToday,
  });

  /// Qualquer dia do mês exibido.
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime today;

  /// Resumo das tarefas de um dia, para desenhar os marcadores.
  final DaySummary Function(DateTime day) summaryOf;

  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onGoToToday;

  void _changeMonth(int delta) {
    onMonthChanged(DateHelper.addMonths(visibleMonth, delta));
  }

  @override
  Widget build(BuildContext context) {
    final days = DateHelper.calendarGrid(visibleMonth);
    final weeks = <List<DateTime>>[
      for (var start = 0; start < days.length; start += 7)
        days.sublist(start, start + 7),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthHeader(
          month: visibleMonth,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
          onGoToToday: onGoToToday,
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (final initial in DateHelper.weekdayInitials)
              Expanded(
                child: ExcludeSemantics(
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -150) {
              _changeMonth(1);
            } else if (velocity > 150) {
              _changeMonth(-1);
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey<String>(
                '${visibleMonth.year}-${visibleMonth.month}',
              ),
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final week in weeks)
                  Row(
                    children: <Widget>[
                      for (final day in week)
                        Expanded(
                          child: _DayCell(
                            day: day,
                            isInVisibleMonth:
                                DateHelper.isSameMonth(day, visibleMonth),
                            isSelected: DateHelper.isSameDay(day, selectedDate),
                            isToday: DateHelper.isSameDay(day, today),
                            summary: summaryOf(day),
                            onTap: () => onDaySelected(day),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onGoToToday,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onGoToToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateHelper.monthName(month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${month.year}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onGoToToday,
          child: const Text('Hoje'),
        ),
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Mês anterior',
          onPressed: onPrevious,
        ),
        const SizedBox(width: 4),
        _RoundIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Próximo mês',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: AppColors.violet,
      style: IconButton.styleFrom(backgroundColor: AppColors.mist),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isInVisibleMonth,
    required this.isSelected,
    required this.isToday,
    required this.summary,
    required this.onTap,
  });

  final DateTime day;
  final bool isInVisibleMonth;
  final bool isSelected;
  final bool isToday;
  final DaySummary summary;
  final VoidCallback onTap;

  String get _semanticLabel {
    final buffer = StringBuffer(DateHelper.fullDate(day));
    if (isToday) buffer.write(', hoje');
    if (summary.isEmpty) {
      buffer.write(', sem tarefas');
    } else if (summary.allDone) {
      buffer.write(', todas as tarefas concluídas');
    } else {
      buffer.write(
        summary.pending == 1
            ? ', 1 tarefa pendente'
            : ', ${summary.pending} tarefas pendentes',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (isSelected) {
      background = AppColors.violet;
      foreground = Colors.white;
    } else if (isToday) {
      background = AppColors.lavender;
      foreground = AppColors.violet;
    } else {
      background = Colors.transparent;
      foreground =
          isInVisibleMonth ? AppColors.ink : const Color(0xFFB4A9D1);
    }

    final Color markerColor;
    if (summary.isEmpty) {
      markerColor = Colors.transparent;
    } else if (summary.hasPending) {
      markerColor = AppColors.mango;
    } else {
      markerColor = AppColors.mint;
    }

    final borderRadius = BorderRadius.circular(14);

    return Semantics(
      button: true,
      selected: isSelected,
      label: _semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: background,
                borderRadius: borderRadius,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
