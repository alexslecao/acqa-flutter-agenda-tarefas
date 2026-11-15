import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../utils/date_helper.dart';

/// Dados digitados no formulário de nova tarefa.
class TaskDraft {
  const TaskDraft({required this.title, required this.description});

  final String title;
  final String description;
}

/// Abre o painel inferior de nova tarefa. Devolve `null` se for cancelado.
Future<TaskDraft?> showAddTaskSheet(
  BuildContext context, {
  required DateTime date,
}) {
  return showModalBottomSheet<TaskDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) => AddTaskSheet(date: date),
  );
}

/// Formulário de inclusão de tarefa, com validação de título obrigatório.
class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, required this.date});

  final DateTime date;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe um título para a tarefa.';
    }
    return null;
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    Navigator.of(context).pop(
      TaskDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.lavender,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Nova tarefa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.event_available_rounded,
                            size: 18,
                            color: AppColors.violet,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Para ${DateHelper.fullDate(widget.date)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _titleController,
                        autofocus: true,
                        maxLength: 60,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: _validateTitle,
                        // Depois do primeiro erro, a mensagem some assim que
                        // o usuário começa a digitar.
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: AppTheme.inputDecoration(
                          label: 'Título',
                          hint: 'Ex.: Estudar para a prova',
                          icon: Icons.edit_note_rounded,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 3,
                        maxLength: 160,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: AppTheme.inputDecoration(
                          label: 'Descrição (opcional)',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Adicionar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
