import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/local_storage_service.dart';
import '../utils/date_helper.dart';

/// Resumo das tarefas de um dia (usado no calendário e nos cabeçalhos).
class DaySummary {
  const DaySummary({required this.pending, required this.done});

  final int pending;
  final int done;

  int get total => pending + done;

  bool get isEmpty => total == 0;

  bool get hasPending => pending > 0;

  /// Há tarefas e todas estão concluídas.
  bool get allDone => total > 0 && pending == 0;

  /// Fração concluída, de 0 a 1.
  double get progress => total == 0 ? 0 : done / total;
}

/// Estado das tarefas do usuário conectado e do dia selecionado.
///
/// As telas escutam este controlador (ele é um [ChangeNotifier]) e se
/// redesenham quando algo muda. Cada alteração é gravada no aparelho.
class TaskController extends ChangeNotifier {
  TaskController(this._storage, {DateTime? initialDate})
      : _selectedDate = DateHelper.dateOnly(initialDate ?? DateTime.now());

  final LocalStorageService _storage;
  final List<Task> _tasks = <Task>[];
  final Random _random = Random();

  String? _ownerEmail;
  DateTime _selectedDate;
  bool _isLoading = false;
  String? _loadError;

  /// Dia selecionado no calendário.
  DateTime get selectedDate => _selectedDate;

  /// `true` enquanto as tarefas gravadas estão sendo lidas.
  bool get isLoading => _isLoading;

  /// Mensagem quando a leitura das tarefas falhou; `null` se deu certo.
  String? get loadError => _loadError;

  void selectDate(DateTime date) {
    final day = DateHelper.dateOnly(date);
    if (DateHelper.isSameDay(day, _selectedDate)) return;
    _selectedDate = day;
    notifyListeners();
  }

  /// Carrega as tarefas gravadas da conta [email].
  Future<void> loadFor(String email) async {
    _ownerEmail = email;
    _isLoading = true;
    _loadError = null;
    _tasks.clear();
    notifyListeners();

    List<Task>? loaded;
    String? error;
    try {
      loaded = await _storage.loadTasks(email);
    } catch (_) {
      error = 'Não foi possível carregar as tarefas salvas.';
    }

    // Se a conta mudou enquanto a leitura acontecia, descarta o resultado.
    if (_ownerEmail != email) return;

    if (loaded != null) {
      _tasks
        ..clear()
        ..addAll(loaded);
    }
    _loadError = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Tenta ler novamente as tarefas depois de uma falha.
  Future<void> reload() async {
    final email = _ownerEmail;
    if (email != null) await loadFor(email);
  }

  /// Limpa o estado quando o usuário sai da conta.
  void clear() {
    _ownerEmail = null;
    _tasks.clear();
    _isLoading = false;
    _loadError = null;
    _selectedDate = DateHelper.dateOnly(DateTime.now());
    notifyListeners();
  }

  /// Tarefas de [day], já na ordem exigida: pendentes primeiro, concluídas
  /// depois, e cada grupo em ordem alfabética (ver [Task.compare]).
  List<Task> tasksFor(DateTime day) {
    return Task.sorted(
      _tasks.where((task) => DateHelper.isSameDay(task.date, day)),
    );
  }

  List<Task> pendingFor(DateTime day) =>
      tasksFor(day).where((task) => !task.isDone).toList();

  List<Task> doneFor(DateTime day) =>
      tasksFor(day).where((task) => task.isDone).toList();

  DaySummary summaryFor(DateTime day) {
    var pending = 0;
    var done = 0;
    for (final task in _tasks) {
      if (!DateHelper.isSameDay(task.date, day)) continue;
      if (task.isDone) {
        done++;
      } else {
        pending++;
      }
    }
    return DaySummary(pending: pending, done: done);
  }

  /// Adiciona uma tarefa em [date] (ou no dia selecionado).
  ///
  /// Devolve `false` se o título estiver vazio ou se a gravação falhar.
  Future<bool> addTask({
    required String title,
    String description = '',
    DateTime? date,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return false;

    final now = DateTime.now();
    _tasks.add(
      Task(
        id: _newId(now),
        title: cleanTitle,
        description: description.trim(),
        date: DateHelper.dateOnly(date ?? _selectedDate),
        createdAt: now,
      ),
    );
    notifyListeners();
    return _persist();
  }

  /// Alterna entre pendente e concluída.
  Future<bool> toggleDone(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return false;
    final task = _tasks[index];
    _tasks[index] = task.copyWith(isDone: !task.isDone);
    notifyListeners();
    return _persist();
  }

  /// Exclui a tarefa. A lista em memória é atualizada imediatamente.
  Future<bool> removeTask(String id) async {
    final before = _tasks.length;
    _tasks.removeWhere((task) => task.id == id);
    if (_tasks.length == before) return false;
    notifyListeners();
    return _persist();
  }

  Future<bool> _persist() async {
    final email = _ownerEmail;
    if (email == null) return false;
    try {
      await _storage.saveTasks(email, List<Task>.of(_tasks));
      return true;
    } catch (_) {
      return false;
    }
  }

  String _newId(DateTime now) {
    final suffix = _random.nextInt(0x7fffffff).toRadixString(16);
    return '${now.microsecondsSinceEpoch}-$suffix';
  }
}
