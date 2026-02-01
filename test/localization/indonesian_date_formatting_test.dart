import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/date_formatter.dart';

/// Property-based tests for Indonesian date formatting
/// 
/// **Feature: academic-task-manager, Property 27: Indonesian date formatting**
/// **Validates: Requirements 11.5**
/// 
/// Tests that date and time displays follow Indonesian locale conventions
/// and use Indonesian month names and formatting patterns.
void main() {
  group('Indonesian Date Formatting Property Tests', () {
    /// **Feature: academic-task-manager, Property 27: Indonesian date formatting**
    /// **Validates: Requirements 11.5**
    /// 
    /// Property: For any date or time display, the format should follow 
    /// Indonesian locale conventions with Indonesian month names
    test('Property 27: Indonesian date formatting', () {
      // Test with multiple random dates to verify consistent formatting
      final testDates = [
        DateTime(2024, 1, 15, 14, 30),
        DateTime(2024, 6, 30, 9, 15),
        DateTime(2024, 12, 25, 23, 59),
        DateTime(2023, 3, 8, 0, 0),
        DateTime(2025, 7, 4, 12, 45),
        DateTime(2024, 2, 29, 18, 20), // Leap year
        DateTime(2024, 11, 11, 6, 5),
      ];

      for (final date in testDates) {
        // Test long format uses Indonesian month names
        final longFormat = IndonesianDateFormatter.formatLong(date);
        expect(longFormat, isNotEmpty);
        expect(longFormat, contains(RegExp(r'\d{2} \w+ \d{4}, \d{2}:\d{2}')));
        
        // Verify Indonesian month names are used (check for distinctly Indonesian months)
        final monthName = IndonesianDateFormatter.getMonthName(date.month);
        expect(longFormat, contains(monthName));
        
        // Verify distinctly Indonesian month names when applicable
        if (date.month == 1) expect(longFormat, contains('Januari'));
        if (date.month == 2) expect(longFormat, contains('Februari'));
        if (date.month == 3) expect(longFormat, contains('Maret'));
        if (date.month == 5) expect(longFormat, contains('Mei'));
        if (date.month == 6) expect(longFormat, contains('Juni'));
        if (date.month == 7) expect(longFormat, contains('Juli'));
        if (date.month == 8) expect(longFormat, contains('Agustus'));
        if (date.month == 10) expect(longFormat, contains('Oktober'));
        if (date.month == 12) expect(longFormat, contains('Desember'));
        
        // Verify English month abbreviations are not used as standalone words
        expect(longFormat, isNot(matches(r'\b(Jan|Feb|Mar|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b')));

        // Test short format
        final shortFormat = IndonesianDateFormatter.formatShort(date);
        expect(shortFormat, isNotEmpty);
        expect(shortFormat, contains(RegExp(r'\d{2} \w{3} \d{4}')));

        // Test date only format
        final dateOnly = IndonesianDateFormatter.formatDateOnly(date);
        expect(dateOnly, isNotEmpty);
        expect(dateOnly, contains(monthName));
        expect(dateOnly, isNot(contains(':')));

        // Test time only format
        final timeOnly = IndonesianDateFormatter.formatTimeOnly(date);
        expect(timeOnly, isNotEmpty);
        expect(timeOnly, matches(RegExp(r'^\d{2}:\d{2}$')));

        // Test with day name format
        final withDayName = IndonesianDateFormatter.formatWithDayName(date);
        expect(withDayName, isNotEmpty);
        expect(withDayName, contains(','));
        expect(withDayName, contains(monthName));
        
        // Verify Indonesian day names are used (check for distinctly Indonesian days)
        final dayName = IndonesianDateFormatter.getDayName(date.weekday);
        expect(withDayName, contains(dayName));
        
        // Verify distinctly Indonesian day names (check for abbreviations)
        expect(withDayName, isNot(matches(r'\b(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\b')));
      }
    });

    /// Test Indonesian month names are correct
    test('Property 27: Indonesian month names are correct', () {
      final expectedMonths = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];

      for (int i = 1; i <= 12; i++) {
        final monthName = IndonesianDateFormatter.getMonthName(i);
        expect(monthName, equals(expectedMonths[i - 1]));
        expect(monthName, isNot(isEmpty));
        
        // Verify it's not an English month name (check for distinctly English forms)
        expect(monthName, isNot(equals('January')));
        expect(monthName, isNot(equals('February')));
        expect(monthName, isNot(equals('March')));
        expect(monthName, isNot(equals('May')));
        expect(monthName, isNot(equals('June')));
        expect(monthName, isNot(equals('July')));
        expect(monthName, isNot(equals('August')));
        expect(monthName, isNot(equals('October')));
        expect(monthName, isNot(equals('December')));
        
        // Note: April, September, November are the same in both languages
      }
    });

    /// Test Indonesian day names are correct
    test('Property 27: Indonesian day names are correct', () {
      final expectedDays = [
        'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
      ];
      
      final expectedShortDays = [
        'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'
      ];

      for (int i = 1; i <= 7; i++) {
        final dayName = IndonesianDateFormatter.getDayName(i);
        final shortDayName = IndonesianDateFormatter.getShortDayName(i);
        
        expect(dayName, equals(expectedDays[i % 7]));
        expect(shortDayName, equals(expectedShortDays[i % 7]));
        expect(dayName, isNot(isEmpty));
        expect(shortDayName, isNot(isEmpty));
        
        // Verify it's not an English day name (check for distinctly English forms)
        expect(dayName, isNot(equals('Sunday')));
        expect(dayName, isNot(equals('Monday')));
        expect(dayName, isNot(equals('Tuesday')));
        expect(dayName, isNot(equals('Wednesday')));
        expect(dayName, isNot(equals('Thursday')));
        expect(dayName, isNot(equals('Friday')));
        expect(dayName, isNot(equals('Saturday')));
        
        expect(shortDayName, isNot(equals('Sun')));
        expect(shortDayName, isNot(equals('Mon')));
        expect(shortDayName, isNot(equals('Tue')));
        expect(shortDayName, isNot(equals('Wed')));
        expect(shortDayName, isNot(equals('Thu')));
        expect(shortDayName, isNot(equals('Fri')));
        expect(shortDayName, isNot(equals('Sat')));
      }
    });

    /// Test relative date formatting in Indonesian
    test('Property 27: Relative date formatting uses Indonesian terms', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Test today
      expect(IndonesianDateFormatter.formatRelative(today), equals('Hari ini'));
      
      // Test tomorrow
      final tomorrow = today.add(const Duration(days: 1));
      expect(IndonesianDateFormatter.formatRelative(tomorrow), equals('Besok'));
      
      // Test yesterday
      final yesterday = today.subtract(const Duration(days: 1));
      expect(IndonesianDateFormatter.formatRelative(yesterday), equals('Kemarin'));
      
      // Test future days
      final threeDaysLater = today.add(const Duration(days: 3));
      expect(IndonesianDateFormatter.formatRelative(threeDaysLater), equals('3 hari lagi'));
      
      final sevenDaysLater = today.add(const Duration(days: 7));
      expect(IndonesianDateFormatter.formatRelative(sevenDaysLater), equals('7 hari lagi'));
      
      // Test past days
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      expect(IndonesianDateFormatter.formatRelative(threeDaysAgo), equals('3 hari yang lalu'));
      
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      expect(IndonesianDateFormatter.formatRelative(sevenDaysAgo), equals('7 hari yang lalu'));
    });

    /// Test deadline text formatting in Indonesian
    test('Property 27: Deadline text formatting uses Indonesian terms', () {
      // Test overdue scenarios
      expect(IndonesianDateFormatter.formatDeadlineText(-1, true), equals('Terlambat 1 hari'));
      expect(IndonesianDateFormatter.formatDeadlineText(-3, true), equals('Terlambat 3 hari'));
      expect(IndonesianDateFormatter.formatDeadlineText(-7, true), equals('Terlambat 7 hari'));
      
      // Test current day
      expect(IndonesianDateFormatter.formatDeadlineText(0, false), equals('Hari ini'));
      
      // Test tomorrow
      expect(IndonesianDateFormatter.formatDeadlineText(1, false), equals('Besok'));
      
      // Test future days
      expect(IndonesianDateFormatter.formatDeadlineText(2, false), equals('2 hari lagi'));
      expect(IndonesianDateFormatter.formatDeadlineText(5, false), equals('5 hari lagi'));
      expect(IndonesianDateFormatter.formatDeadlineText(10, false), equals('10 hari lagi'));
      
      // Verify no English terms are used
      final testCases = [
        IndonesianDateFormatter.formatDeadlineText(-1, true),
        IndonesianDateFormatter.formatDeadlineText(0, false),
        IndonesianDateFormatter.formatDeadlineText(1, false),
        IndonesianDateFormatter.formatDeadlineText(5, false),
      ];
      
      for (final text in testCases) {
        expect(text, isNot(contains('day')));
        expect(text, isNot(contains('days')));
        expect(text, isNot(contains('today')));
        expect(text, isNot(contains('tomorrow')));
        expect(text, isNot(contains('overdue')));
        expect(text, isNot(contains('late')));
      }
    });

    /// Test duration formatting in Indonesian
    test('Property 27: Duration formatting uses Indonesian terms', () {
      // Test various durations
      expect(IndonesianDateFormatter.formatDuration(const Duration(minutes: 30)), equals('30 menit'));
      expect(IndonesianDateFormatter.formatDuration(const Duration(hours: 2)), equals('2 jam'));
      expect(IndonesianDateFormatter.formatDuration(const Duration(hours: 2, minutes: 30)), equals('2 jam 30 menit'));
      expect(IndonesianDateFormatter.formatDuration(const Duration(days: 1)), equals('1 hari'));
      expect(IndonesianDateFormatter.formatDuration(const Duration(days: 3, hours: 5)), equals('3 hari 5 jam'));
      expect(IndonesianDateFormatter.formatDuration(const Duration(days: 7)), equals('7 hari'));
      
      // Verify no English terms are used
      final testDurations = [
        const Duration(minutes: 45),
        const Duration(hours: 3),
        const Duration(days: 2, hours: 4),
        const Duration(days: 5),
      ];
      
      for (final duration in testDurations) {
        final formatted = IndonesianDateFormatter.formatDuration(duration);
        expect(formatted, isNot(contains('minute')));
        expect(formatted, isNot(contains('minutes')));
        expect(formatted, isNot(contains('hour')));
        expect(formatted, isNot(contains('hours')));
        expect(formatted, isNot(contains('day')));
        expect(formatted, isNot(contains('days')));
      }
    });

    /// Test error handling for invalid inputs
    test('Property 27: Error handling for invalid date inputs', () {
      // Test invalid month
      expect(() => IndonesianDateFormatter.getMonthName(0), throwsArgumentError);
      expect(() => IndonesianDateFormatter.getMonthName(13), throwsArgumentError);
      expect(() => IndonesianDateFormatter.getMonthName(-1), throwsArgumentError);
      
      // Test invalid weekday
      expect(() => IndonesianDateFormatter.getDayName(0), throwsArgumentError);
      expect(() => IndonesianDateFormatter.getDayName(8), throwsArgumentError);
      expect(() => IndonesianDateFormatter.getDayName(-1), throwsArgumentError);
      
      expect(() => IndonesianDateFormatter.getShortDayName(0), throwsArgumentError);
      expect(() => IndonesianDateFormatter.getShortDayName(8), throwsArgumentError);
      expect(() => IndonesianDateFormatter.getShortDayName(-1), throwsArgumentError);
    });

    /// Test consistency across different formatting methods
    test('Property 27: Consistency across formatting methods', () {
      final testDate = DateTime(2024, 6, 15, 14, 30);
      
      // All formats should use the same month name
      final monthName = IndonesianDateFormatter.getMonthName(testDate.month);
      expect(IndonesianDateFormatter.formatLong(testDate), contains(monthName));
      expect(IndonesianDateFormatter.formatDateOnly(testDate), contains(monthName));
      expect(IndonesianDateFormatter.formatWithDayName(testDate), contains(monthName));
      
      // All formats should use the same day name when applicable
      final dayName = IndonesianDateFormatter.getDayName(testDate.weekday);
      expect(IndonesianDateFormatter.formatWithDayName(testDate), contains(dayName));
      
      // Time formatting should be consistent
      final timeOnly = IndonesianDateFormatter.formatTimeOnly(testDate);
      expect(IndonesianDateFormatter.formatLong(testDate), contains(timeOnly));
    });
  });
}