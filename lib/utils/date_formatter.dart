import 'package:intl/intl.dart';

/// Utility class for Indonesian date and time formatting
/// 
/// Provides Indonesian locale-specific formatting for dates and times
/// according to Indonesian conventions.
/// 
/// Requirements: 11.5
class IndonesianDateFormatter {
  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _dayNames = [
    'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  ];

  static const List<String> _shortDayNames = [
    'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'
  ];

  /// Formats a DateTime to Indonesian long format
  /// Example: "15 Januari 2024, 14:30"
  static String formatLong(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthNames[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  /// Formats a DateTime to Indonesian short format
  /// Example: "15 Jan 2024"
  static String formatShort(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthNames[dateTime.month - 1].substring(0, 3);
    final year = dateTime.year;
    
    return '$day $month $year';
  }

  /// Formats a DateTime to Indonesian date only format
  /// Example: "15 Januari 2024"
  static String formatDateOnly(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthNames[dateTime.month - 1];
    final year = dateTime.year;
    
    return '$day $month $year';
  }

  /// Formats a DateTime to Indonesian time only format
  /// Example: "14:30"
  static String formatTimeOnly(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }

  /// Formats a DateTime with day name
  /// Example: "Senin, 15 Januari 2024"
  static String formatWithDayName(DateTime dateTime) {
    final dayName = _dayNames[dateTime.weekday % 7];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthNames[dateTime.month - 1];
    final year = dateTime.year;
    
    return '$dayName, $day $month $year';
  }

  /// Formats a DateTime for relative display
  /// Example: "Hari ini", "Besok", "2 hari lagi", "Kemarin"
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    final difference = targetDate.difference(today).inDays;
    
    if (difference == 0) {
      return 'Hari ini';
    } else if (difference == 1) {
      return 'Besok';
    } else if (difference == -1) {
      return 'Kemarin';
    } else if (difference > 1) {
      return '$difference hari lagi';
    } else {
      return '${-difference} hari yang lalu';
    }
  }

  /// Formats deadline text in Indonesian
  /// Used for deadline status display
  static String formatDeadlineText(int remainingDays, bool isOverdue) {
    if (isOverdue) {
      final overdueDays = -remainingDays;
      if (overdueDays == 1) {
        return 'Terlambat 1 hari';
      } else {
        return 'Terlambat $overdueDays hari';
      }
    } else if (remainingDays == 0) {
      return 'Hari ini';
    } else if (remainingDays == 1) {
      return 'Besok';
    } else {
      return '$remainingDays hari lagi';
    }
  }

  /// Gets Indonesian month name by index (1-12)
  static String getMonthName(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }
    return _monthNames[month - 1];
  }

  /// Gets Indonesian day name by weekday (1=Monday, 7=Sunday)
  static String getDayName(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError('Weekday must be between 1 and 7');
    }
    return _dayNames[weekday % 7];
  }

  /// Gets short Indonesian day name by weekday (1=Monday, 7=Sunday)
  static String getShortDayName(int weekday) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError('Weekday must be between 1 and 7');
    }
    return _shortDayNames[weekday % 7];
  }

  /// Formats duration in Indonesian
  /// Example: "2 jam 30 menit", "45 menit", "3 hari"
  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      if (hours > 0) {
        return '$days hari $hours jam';
      } else {
        return '$days hari';
      }
    } else if (hours > 0) {
      if (minutes > 0) {
        return '$hours jam $minutes menit';
      } else {
        return '$hours jam';
      }
    } else {
      return '$minutes menit';
    }
  }

  /// Creates a DateFormat instance for Indonesian locale
  /// This can be used with the intl package for more complex formatting
  static DateFormat createIndonesianDateFormat(String pattern) {
    return DateFormat(pattern, 'id_ID');
  }
}