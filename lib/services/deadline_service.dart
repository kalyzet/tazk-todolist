import '../models/task.dart';
import '../repositories/task_repository.dart';

/// Service class for deadline calculations and time-related operations
class DeadlineService {
  final TaskRepository _taskRepository;

  DeadlineService({TaskRepository? taskRepository})
      : _taskRepository = taskRepository ?? TaskRepository();

  /// Calculates remaining days until deadline with proper date arithmetic
  /// 
  /// Requirements: 5.1, 5.3
  /// - Uses current date as reference for calculation
  /// - Returns positive number for future deadlines
  /// - Returns negative number for past deadlines
  /// - Uses date-only comparison (ignores time component)
  int calculateRemainingDays(DateTime deadline) {
    final now = DateTime.now();
    
    // Use date-only comparison to avoid time component issues
    final currentDate = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    
    // Calculate difference in days
    final difference = deadlineDate.difference(currentDate).inDays;
    
    return difference;
  }

  /// Checks if a task deadline has passed
  /// 
  /// Requirements: 5.2
  /// - Returns true if deadline date is before current date
  /// - Uses date-only comparison (ignores time component)
  bool isOverdue(DateTime deadline) {
    final now = DateTime.now();
    
    // Use date-only comparison
    final currentDate = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    
    return deadlineDate.isBefore(currentDate);
  }

  /// Gets tasks with upcoming deadlines for notification scheduling
  /// 
  /// Requirements: 5.4
  /// - Returns tasks with deadlines within specified days
  /// - Only includes tasks with progress < 100%
  /// - Orders by deadline (earliest first)
  Future<List<Task>> getUpcomingDeadlines({int daysAhead = 3}) async {
    if (daysAhead < 0) {
      throw ArgumentError('Days ahead harus >= 0');
    }
    
    return await _taskRepository.findUpcomingDeadlines(daysAhead);
  }

  /// Gets tasks that are overdue
  /// 
  /// Returns tasks where deadline has passed and progress < 100%
  Future<List<Task>> getOverdueTasks() async {
    return await _taskRepository.findOverdueTasks();
  }

  /// Gets tasks with deadlines exactly N days from now
  /// 
  /// Useful for notification scheduling (e.g., tasks due in exactly 3 days)
  Future<List<Task>> getTasksDueInDays(int days) async {
    if (days < 0) {
      throw ArgumentError('Days harus >= 0');
    }
    
    final targetDate = DateTime.now().add(Duration(days: days));
    final allTasks = await _taskRepository.findAll();
    
    return allTasks.where((task) {
      if (task.progress >= 100) return false; // Skip completed tasks
      
      final remainingDays = calculateRemainingDays(task.deadline);
      return remainingDays == days;
    }).toList();
  }

  /// Gets deadline status information for a task
  /// 
  /// Returns a map with deadline status details
  Map<String, dynamic> getDeadlineStatus(Task task) {
    final remainingDays = calculateRemainingDays(task.deadline);
    final isTaskOverdue = isOverdue(task.deadline);
    
    String status;
    String statusIndonesian;
    
    if (isTaskOverdue) {
      status = 'overdue';
      statusIndonesian = 'Terlambat';
    } else if (remainingDays == 0) {
      status = 'due_today';
      statusIndonesian = 'Hari ini';
    } else if (remainingDays == 1) {
      status = 'due_tomorrow';
      statusIndonesian = 'Besok';
    } else if (remainingDays <= 3) {
      status = 'due_soon';
      statusIndonesian = 'Segera';
    } else {
      status = 'normal';
      statusIndonesian = 'Normal';
    }
    
    return {
      'remaining_days': remainingDays,
      'is_overdue': isTaskOverdue,
      'status': status,
      'status_indonesian': statusIndonesian,
      'deadline_text': _formatDeadlineText(remainingDays, isTaskOverdue),
    };
  }

  /// Formats deadline text in Indonesian
  String _formatDeadlineText(int remainingDays, bool isTaskOverdue) {
    if (isTaskOverdue) {
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

  /// Gets summary of deadline statistics for a list of tasks
  Map<String, int> getDeadlineStatistics(List<Task> tasks) {
    int overdue = 0;
    int dueToday = 0;
    int dueTomorrow = 0;
    int dueSoon = 0; // 2-3 days
    int normal = 0; // > 3 days
    
    for (final task in tasks) {
      if (task.progress >= 100) continue; // Skip completed tasks
      
      final remainingDays = calculateRemainingDays(task.deadline);
      
      if (remainingDays < 0) {
        overdue++;
      } else if (remainingDays == 0) {
        dueToday++;
      } else if (remainingDays == 1) {
        dueTomorrow++;
      } else if (remainingDays <= 3) {
        dueSoon++;
      } else {
        normal++;
      }
    }
    
    return {
      'overdue': overdue,
      'due_today': dueToday,
      'due_tomorrow': dueTomorrow,
      'due_soon': dueSoon,
      'normal': normal,
      'total_incomplete': overdue + dueToday + dueTomorrow + dueSoon + normal,
    };
  }

  /// Checks if a task needs notification (used by notification service)
  bool needsNotification(Task task) {
    if (task.progress >= 100) return false; // Completed tasks don't need notifications
    
    final remainingDays = calculateRemainingDays(task.deadline);
    
    // Send notifications for tasks due in 1, 2, or 3 days
    return remainingDays >= 1 && remainingDays <= 3;
  }

  /// Gets the next notification date for a task
  /// Returns null if no notification is needed
  DateTime? getNextNotificationDate(Task task) {
    if (!needsNotification(task)) return null;
    
    final remainingDays = calculateRemainingDays(task.deadline);
    
    // Calculate when to send the next notification
    // For example, if task is due in 3 days, send notification today
    final now = DateTime.now();
    
    if (remainingDays == 3 || remainingDays == 2 || remainingDays == 1) {
      // Send notification today at a specific time (e.g., 9 AM)
      return DateTime(now.year, now.month, now.day, 9, 0);
    }
    
    return null;
  }
}