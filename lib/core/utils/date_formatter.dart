import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateOnly = DateFormat('d MMM yyyy', 'pl_PL');
  static final DateFormat _monthYear = DateFormat('MMM yyyy', 'pl_PL');
  static final DateFormat _full = DateFormat('d MMM yyyy, HH:mm', 'pl_PL');
  static final DateFormat _inputDate = DateFormat('yyyy-MM-dd');

  static String dateOnly(DateTime date) => _dateOnly.format(date.toLocal());
  static String monthYear(DateTime date) => _monthYear.format(date.toLocal());
  static String full(DateTime date) => _full.format(date.toLocal());
  static String inputDate(DateTime date) => _inputDate.format(date.toLocal());

  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDate = date.toLocal();
    final targetDay = DateTime(localDate.year, localDate.month, localDate.day);
    final diff = today.difference(targetDay);

    if (diff.isNegative) {
      return dateOnly(localDate);
    }

    if (diff.inDays == 0) return 'Dzisiaj';
    if (diff.inDays == 1) return 'Wczoraj';
    if (diff.inDays < 7) return '${diff.inDays} dni temu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tyg. temu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} mies. temu';
    return '${(diff.inDays / 365).floor()} lat temu';
  }
}
