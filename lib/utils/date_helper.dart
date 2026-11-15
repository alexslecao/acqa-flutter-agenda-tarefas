/// Funções de data em português, escritas à mão para o app não depender de
/// pacotes de internacionalização.
abstract final class DateHelper {
  static const List<String> monthNames = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// Índice 0 = segunda-feira, seguindo `DateTime.weekday - 1`.
  static const List<String> weekdayNames = <String>[
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  /// Cabeçalho do calendário, com a semana começando no domingo.
  static const List<String> weekdayInitials = <String>[
    'D',
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
  ];

  /// Quantidade fixa de células do calendário (6 semanas), para a altura do
  /// componente não mudar de um mês para o outro.
  static const int gridCellCount = 42;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime firstDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// O construtor de [DateTime] normaliza valores fora do intervalo, então
  /// somar meses/dias aqui é seguro (inclusive na virada de ano).
  static DateTime addMonths(DateTime month, int delta) =>
      DateTime(month.year, month.month + delta);

  static DateTime addDays(DateTime date, int delta) =>
      DateTime(date.year, date.month, date.day + delta);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Chave `aaaa-mm-dd` usada para gravar a data da tarefa.
  static String keyOf(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Converte uma chave `aaaa-mm-dd` em data; devolve `null` se for inválida.
  static DateTime? parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  /// Dias exibidos no calendário de [month], incluindo o fim do mês anterior
  /// e o começo do seguinte para completar as semanas.
  static List<DateTime> calendarGrid(DateTime month) {
    final first = firstDayOfMonth(month);
    final leading = first.weekday % 7; // domingo = 0
    return List<DateTime>.generate(
      gridCellCount,
      (index) => DateTime(first.year, first.month, 1 - leading + index),
    );
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Ex.: `Novembro`.
  static String monthName(DateTime date) =>
      capitalize(monthNames[date.month - 1]);

  /// Ex.: `15 de novembro`.
  static String dayAndMonth(DateTime date) =>
      '${date.day} de ${monthNames[date.month - 1]}';

  /// Ex.: `domingo, 15 de novembro de 2026`.
  static String fullDate(DateTime date) =>
      '${weekdayNames[date.weekday - 1]}, ${dayAndMonth(date)} de ${date.year}';

  /// `Hoje`, `Amanhã`, `Ontem` ou o dia da semana.
  static String relativeLabel(DateTime date, DateTime today) {
    // Em UTC para a diferença em dias não ser afetada por horário de verão.
    final difference = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(today.year, today.month, today.day))
        .inDays;
    switch (difference) {
      case 0:
        return 'Hoje';
      case 1:
        return 'Amanhã';
      case -1:
        return 'Ontem';
      default:
        return capitalize(weekdayNames[date.weekday - 1]);
    }
  }

  static String greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}
