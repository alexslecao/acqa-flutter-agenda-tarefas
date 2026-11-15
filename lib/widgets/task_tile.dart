import 'package:material_ui/material_ui.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// Cartão de uma tarefa na lista.
///
/// - Tocar no cartão ou na caixa marca/desmarca como concluída.
/// - O botão da lixeira pede a exclusão ([onDeletePressed]).
/// - Arrastar para a esquerda também exclui, depois de [confirmDismiss].
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDeletePressed,
    required this.confirmDismiss,
    required this.onDismissed,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDeletePressed;
  final Future<bool> Function() confirmDismiss;
  final VoidCallback onDismissed;

  Color get _accent {
    final sum = task.id.codeUnits.fold<int>(0, (total, unit) => total + unit);
    return AppColors.taskAccents[sum % AppColors.taskAccents.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone;
    final borderRadius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey<String>('task-${task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => confirmDismiss(),
        onDismissed: (_) => onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: borderRadius,
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: isDone ? const Color(0xFFFBF9FF) : Colors.white,
              child: InkWell(
                onTap: onToggle,
                child: Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                      child: Row(
                        children: <Widget>[
                          Checkbox(
                            value: isDone,
                            onChanged: (_) => onToggle(),
                            semanticLabel: task.title,
                            shape: const CircleBorder(),
                            activeColor: AppColors.mint,
                            checkColor: AppColors.ink,
                            side: const BorderSide(
                              color: AppColors.violet,
                              width: 2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: _TaskTexts(task: task),
                            ),
                          ),
                          IconButton(
                            onPressed: onDeletePressed,
                            tooltip: 'Excluir tarefa',
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                    // Faixa colorida na lateral do cartão.
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        color: isDone ? AppColors.lavender : _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskTexts extends StatelessWidget {
  const _TaskTexts({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone;
    final hasDescription = task.description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDone ? AppColors.inkSoft : AppColors.ink,
            decoration:
                isDone ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: AppColors.inkSoft,
          ),
        ),
        if (hasDescription) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            task.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ],
    );
  }
}
