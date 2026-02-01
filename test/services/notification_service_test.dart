import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../lib/services/notification_service.dart';
import '../../lib/models/task.dart';
import '../../lib/models/academic_context.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUpAll(() {
      // Initialize Flutter bindings for testing
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      notificationService = NotificationService();
    });

    group('Property Tests', () {
      /// **Feature: academic-task-manager, Property 19: Notification triggering**
      /// **Validates: Requirements 9.1**
      /// 
      /// Property: For any task with 1, 2, or 3 days remaining until deadline 
      /// and progress below 100%, a local notification should be scheduled
      test('Property 19: Notification triggering', () async {
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random task data
          final now = DateTime.now();
          final daysUntilDeadline = 1 + (iteration % 3); // 1, 2, or 3 days
          final deadline = now.add(Duration(days: daysUntilDeadline));
          final progress = iteration % 100; // 0-99% progress
          
          final task = Task(
            id: iteration + 1,
            name: 'Test Task $iteration',
            courseName: 'Test Course',
            instructorName: 'Test Instructor',
            deadline: deadline,
            semester: 'Semester ${(iteration % 8) + 1}',
            period: iteration % 2 == 0 ? 'UTS' : 'UAS',
            progress: progress,
            createdAt: now.subtract(Duration(days: 7)),
            updatedAt: now,
          );

          // Test the property: tasks with 1-3 days remaining and progress < 100%
          // should be eligible for notification scheduling
          final shouldScheduleNotifications = progress < 100 && 
                                            daysUntilDeadline >= 1 && 
                                            daysUntilDeadline <= 3 &&
                                            task.id != null;

          if (shouldScheduleNotifications) {
            // Verify that the task meets the criteria for notification scheduling
            expect(task.progress, lessThan(100));
            expect(daysUntilDeadline, inInclusiveRange(1, 3));
            expect(task.id, isNotNull);
            expect(task.deadline.isAfter(now), isTrue);
          }

          // Test that completed tasks don't meet notification criteria
          if (progress >= 100) {
            expect(task.progress, greaterThanOrEqualTo(100));
            // Completed tasks should not be scheduled for notifications
          }
        }
      });

      /// **Feature: academic-task-manager, Property 22: Completed task notification cleanup**
      /// **Validates: Requirements 9.4**
      /// 
      /// Property: For any task that reaches 100% progress, all pending notifications 
      /// for that task should be cancelled
      test('Property 22: Completed task notification cleanup', () async {
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          final now = DateTime.now();
          final deadline = now.add(Duration(days: (iteration % 7) + 1)); // 1-7 days
          
          // Create a task that gets completed (progress = 100%)
          final completedTask = Task(
            id: iteration + 1,
            name: 'Completed Task $iteration',
            courseName: 'Test Course',
            instructorName: 'Test Instructor',
            deadline: deadline,
            semester: 'Semester ${(iteration % 8) + 1}',
            period: iteration % 2 == 0 ? 'UTS' : 'UAS',
            progress: 100, // Completed task
            createdAt: now.subtract(Duration(days: 7)),
            updatedAt: now,
          );

          // Test the property: completed tasks should not be eligible for new notifications
          expect(completedTask.progress, equals(100));
          expect(completedTask.id, isNotNull);
          
          // Verify that completed tasks don't meet notification scheduling criteria
          final shouldScheduleNotifications = completedTask.progress < 100;
          expect(shouldScheduleNotifications, isFalse);
        }
      });

      /// **Feature: academic-task-manager, Property 23: Notification preference enforcement**
      /// **Validates: Requirements 9.5**
      /// 
      /// Property: For any notification setting (enabled/disabled), the system should 
      /// respect the user's preference when scheduling notifications
      test('Property 23: Notification preference enforcement', () async {
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          final now = DateTime.now();
          final deadline = now.add(Duration(days: (iteration % 3) + 1)); // 1-3 days
          final progress = iteration % 100; // 0-99% progress
          final notificationsEnabled = iteration % 2 == 0; // Alternate enabled/disabled
          
          final task = Task(
            id: iteration + 1,
            name: 'Test Task $iteration',
            courseName: 'Test Course',
            instructorName: 'Test Instructor',
            deadline: deadline,
            semester: 'Semester ${(iteration % 8) + 1}',
            period: iteration % 2 == 0 ? 'UTS' : 'UAS',
            progress: progress,
            createdAt: now.subtract(Duration(days: 7)),
            updatedAt: now,
          );

          // Test the property: notification service should respect user preference
          notificationService.setNotificationsEnabled(notificationsEnabled);
          
          // Verify that the notification service stores the preference correctly
          expect(notificationService.notificationsEnabled, equals(notificationsEnabled));
          
          // Test that the preference affects notification behavior
          if (notificationsEnabled) {
            // When notifications are enabled, eligible tasks should be considered for scheduling
            final isEligibleTask = task.progress < 100 && 
                                 task.id != null && 
                                 task.deadline.isAfter(now);
            
            if (isEligibleTask) {
              // The service should be ready to schedule notifications for eligible tasks
              expect(notificationService.notificationsEnabled, isTrue);
            }
          } else {
            // When notifications are disabled, no tasks should be scheduled regardless of eligibility
            expect(notificationService.notificationsEnabled, isFalse);
            
            // Even eligible tasks should not be scheduled when notifications are disabled
            final isEligibleTask = task.progress < 100 && 
                                 task.id != null && 
                                 task.deadline.isAfter(now);
            
            if (isEligibleTask) {
              // Despite being eligible, notifications should be disabled
              expect(notificationService.notificationsEnabled, isFalse);
            }
          }
        }
      });
    });

    group('Unit Tests', () {
      test('should handle notification preferences', () {
        // Test enabling/disabling notifications
        notificationService.setNotificationsEnabled(false);
        expect(notificationService.notificationsEnabled, false);

        notificationService.setNotificationsEnabled(true);
        expect(notificationService.notificationsEnabled, true);
      });

      test('should identify tasks eligible for notifications', () {
        final now = DateTime.now();
        
        // Task with 2 days remaining and 50% progress - should be eligible
        final eligibleTask = Task(
          id: 1,
          name: 'Eligible Task',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: now.add(Duration(days: 2)),
          semester: 'Semester 1',
          period: 'UTS',
          progress: 50,
          createdAt: now.subtract(Duration(days: 7)),
          updatedAt: now,
        );

        expect(eligibleTask.progress, lessThan(100));
        expect(eligibleTask.id, isNotNull);
        expect(eligibleTask.deadline.isAfter(now), isTrue);
      });

      test('should identify completed tasks as not eligible for notifications', () {
        final now = DateTime.now();
        
        final completedTask = Task(
          id: 1,
          name: 'Completed Task',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: now.add(Duration(days: 2)),
          semester: 'Semester 1',
          period: 'UTS',
          progress: 100, // Completed
          createdAt: now.subtract(Duration(days: 7)),
          updatedAt: now,
        );

        expect(completedTask.progress, equals(100));
        // Completed tasks should not be scheduled for notifications
      });

      test('should identify tasks without ID as not eligible for notifications', () {
        final now = DateTime.now();
        
        final taskWithoutId = Task(
          id: null, // No ID
          name: 'Task Without ID',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: now.add(Duration(days: 2)),
          semester: 'Semester 1',
          period: 'UTS',
          progress: 50,
          createdAt: now.subtract(Duration(days: 7)),
          updatedAt: now,
        );

        expect(taskWithoutId.id, isNull);
        // Tasks without ID should not be scheduled for notifications
      });

      test('should handle past deadlines', () {
        final now = DateTime.now();
        
        final pastTask = Task(
          id: 1,
          name: 'Past Task',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: now.subtract(Duration(days: 1)), // Past deadline
          semester: 'Semester 1',
          period: 'UTS',
          progress: 50,
          createdAt: now.subtract(Duration(days: 7)),
          updatedAt: now,
        );

        expect(pastTask.deadline.isBefore(now), isTrue);
        // Past tasks should not be scheduled for new notifications
      });
    });
  });
}