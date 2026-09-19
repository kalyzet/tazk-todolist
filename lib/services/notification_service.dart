import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task.dart';

/// Service for managing task deadline notifications
/// 
/// Implements the cancel-then-schedule pattern to ensure notification consistency
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    tz.initializeTimeZones();
    _isInitialized = true;
  }

  /// Schedule notifications for a task (3, 2, 1 days before deadline)
  /// 
  /// Requirements: 9.1, 9.2, 9.3
  /// - Schedules notifications for tasks with progress < 100%
  /// - Includes task name and remaining days in notification
  /// - Schedules at consistent daily time (9 AM)
  Future<void> scheduleTaskNotifications(Task task) async {
    if (!_isInitialized || !_notificationsEnabled) return;
    if (task.id == null || task.progress >= 100) return;

    await initialize();

    final now = DateTime.now();
    final deadline = task.deadline;
    
    for (int daysBeforeDeadline in [3, 2, 1]) {
      final notificationDate = DateTime(
        deadline.year,
        deadline.month,
        deadline.day - daysBeforeDeadline,
        9, // 9 AM
        0,
      );

      if (notificationDate.isAfter(now)) {
        final notificationId = _generateNotificationId(task.id!, daysBeforeDeadline);
        
        await _notifications.zonedSchedule(
          notificationId,
          'Tugas Mendekati Deadline',
          '${task.name} - $daysBeforeDeadline hari lagi',
          _convertToTZDateTime(notificationDate),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_deadlines',
              'Task Deadlines',
              channelDescription: 'Notifications for approaching task deadlines',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Cancel all notifications for a specific task
  /// 
  /// Requirements: 9.4
  /// - Removes all pending notifications when task is completed or deleted
  Future<void> cancelTaskNotifications(int taskId) async {
    if (!_isInitialized) return;

    // Cancel notifications for 3, 2, and 1 days before deadline
    for (int daysBeforeDeadline in [3, 2, 1]) {
      final notificationId = _generateNotificationId(taskId, daysBeforeDeadline);
      await _notifications.cancel(notificationId);
    }
  }

  /// Reschedule notifications for a task (cancel existing, then schedule new)
  /// 
  /// Requirements: 9.1, 9.4
  /// - Implements cancel-then-schedule pattern for consistency
  /// - Used when task deadline or progress changes
  Future<void> rescheduleTaskNotifications(Task task) async {
    if (task.id == null) return;

    // Always cancel existing notifications first
    await cancelTaskNotifications(task.id!);
    
    // Schedule new notifications if task is not completed
    if (task.progress < 100) {
      await scheduleTaskNotifications(task);
    }
  }

  /// Enable or disable notifications
  /// 
  /// Requirements: 9.5
  /// - Allows users to control notification preferences
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  /// Check if notifications are enabled
  bool get notificationsEnabled => _notificationsEnabled;

  /// Request notification permissions (mainly for iOS)
  Future<bool> requestPermissions() async {
    await initialize();
    
    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    return result ?? true; // Android doesn't need explicit permission request
  }

  /// Generate unique notification ID for task and days before deadline
  int _generateNotificationId(int taskId, int daysBeforeDeadline) {
    // Combine task ID and days to create unique notification ID
    // Format: taskId * 10 + daysBeforeDeadline
    // This ensures each task can have up to 10 different notification types
    return taskId * 10 + daysBeforeDeadline;
  }

  /// Convert DateTime to TZDateTime using local timezone
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final localLocation = tz.local;
    return tz.TZDateTime(
      localLocation,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }
}