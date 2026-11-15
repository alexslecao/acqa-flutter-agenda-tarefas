import '../utils/date_helper.dart';

/// Uma tarefa vinculada a um dia do calendário.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.date,
    required this.createdAt,
    this.description = '',
    this.isDone = false,
  });

  /// Identificador único da tarefa.
  final String id;

  final String title;

  /// Descrição opcional (string vazia quando não informada).
  final String description;

  /// Dia ao qual a tarefa pertence (apenas ano, mês e dia são relevantes).
  final DateTime date;

  /// `true` = concluída, `false` = pendente.
  final bool isDone;

  final DateTime createdAt;

  Task copyWith({
    String? title,
    String? description,
    DateTime? date,
    bool? isDone,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'date': DateHelper.keyOf(date),
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Lê uma tarefa gravada. Devolve `null` quando o registro está incompleto
  /// ou corrompido, para que um dado ruim não derrube o app.
  static Task? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final dateRaw = json['date'];
    if (id is! String || title is! String || dateRaw is! String) return null;

    final date = DateHelper.parseKey(dateRaw);
    if (date == null) return null;

    final description = json['description'];
    final createdRaw = json['createdAt'];
    final createdAt = createdRaw is String ? DateTime.tryParse(createdRaw) : null;

    return Task(
      id: id,
      title: title,
      description: description is String ? description : '',
      date: date,
      isDone: json['isDone'] == true,
      createdAt: createdAt ?? date,
    );
  }

  /// Regra de ordenação exigida:
  /// 1. pendentes antes das concluídas;
  /// 2. dentro de cada grupo, título em ordem alfabética crescente, sem
  ///    diferenciar maiúsculas de minúsculas.
  static int compare(Task a, Task b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;

    final byTitle =
        normalizeForSorting(a.title).compareTo(normalizeForSorting(b.title));
    if (byTitle != 0) return byTitle;

    // Desempates apenas para a ordem ser sempre a mesma.
    final byRawTitle = a.title.compareTo(b.title);
    if (byRawTitle != 0) return byRawTitle;
    return a.createdAt.compareTo(b.createdAt);
  }

  /// Devolve uma cópia ordenada de [tasks] segundo [compare].
  static List<Task> sorted(Iterable<Task> tasks) {
    return tasks.toList()..sort(compare);
  }
}

const Map<String, String> _accentMap = <String, String>{
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

/// Chave de comparação alfabética: minúsculas e sem acentos, para que
/// "Água" venha antes de "Banco" e "almoço" fique junto de "Almoço".
String normalizeForSorting(String text) {
  final lower = text.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accentMap[char] ?? char);
  }
  return buffer.toString();
}
