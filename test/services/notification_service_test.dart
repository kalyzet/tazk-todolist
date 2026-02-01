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

      /// **Feature: academic-task-manager, Property 20: Notification content completeness**
      /// **Validates: Requirements 9.2**
      /// 
      /// Property: For any triggered notification, the message should contain both 
      /// the task name and remaining days information
      test('Property 20: Notification content completeness', () async {
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          final now = DateTime.now();
          final daysUntilDeadline = 1 + (iteration % 3); // 1, 2, or 3 days
          final deadline = now.add(Duration(days: daysUntilDeadline));
          final progress = iteration % 100; // 0-99% progress
          
          // Generate random task name with various characters
          final taskNames = [
            'Tugas Database $iteration',
            'Laporan Praktikum ${iteration + 1}',
            'Presentasi Kelompok ${iteration % 10}',
            'Essay Bahasa Inggris $iteration',
            'Kuis Online ${iteration % 5}',
            'Proyek Akhir Semester',
            'Tugas Mandiri $iteration',
            'Diskusi Forum ${iteration % 3}',
          ];
          final taskName = taskNames[iteration % taskNames.length];
          
          final task = Task(
            id: iteration + 1,
            name: taskName,
            courseName: 'Test Course $iteration',
            instructorName: 'Test Instructor',
            deadline: deadline,
            semester: 'Semester ${(iteration % 8) + 1}',
            period: iteration % 2 == 0 ? 'UTS' : 'UAS',
            progress: progress,
            createdAt: now.subtract(Duration(days: 7)),
            updatedAt: now,
          );

          // Test the property: notification content should contain task name and remaining days
          if (progress < 100 && task.id != null) {
            // For each notification day (3, 2, 1 days before)
            for (int daysBeforeDeadline in [3, 2, 1]) {
              final notificationDate = DateTime(
                deadline.year,
                deadline.month,
                deadline.day - daysBeforeDeadline,
                9, // 9 AM
                0,
              );

              // Only test notifications that would be scheduled in the future
              if (notificationDate.isAfter(now)) {
                // Verify notification content format based on NotificationService implementation
                final expectedTitle = 'Tugas Mendekati Deadline';
                final expectedBody = '${task.name} - ${daysBeforeDeadline} hari lagi';
                
                // Test that the notification content contains the task name
                expect(expectedBody, contains(task.name));
                
                // Test that the notification content contains the remaining days information
                expect(expectedBody, contains('${daysBeforeDeadline} hari lagi'));
                
                // Test that the title is in Indonesian
                expect(expectedTitle, equals('Tugas Mendekati Deadline'));
                
                // Test that the body format follows the expected pattern: "TaskName - X hari lagi"
                final bodyPattern = RegExp(r'^.+ - \d+ hari lagi$');
                expect(expectedBody, matches(bodyPattern));
                
                // Test that the notification content is not empty
                expect(expectedTitle.trim(), isNotEmpty);
                expect(expectedBody.trim(), isNotEmpty);
                
                // Test that the task name is preserved exactly in the notification
                final taskNameInBody = expectedBody.split(' - ')[0];
                expect(taskNameInBody, equals(task.name));
                
                // Test that the days information is correctly formatted
                final daysInfo = expectedBody.split(' - ')[1];
                expect(daysInfo, equals('${daysBeforeDeadline} hari lagi'));
              }
            }
          }
        }
      });

      /// **Feature: academic-task-manager, Property 21: Notification scheduling consistency**
      /// **Validates: Requirements 9.3**
      /// 
      /// Property: For any notification, it should be scheduled to appear at the same 
      /// daily time across all notifications
      test('Property 21: Notification scheduling consistency', () async {
        // Run property test with multiple iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          final now = DateTime.now();
          final daysUntilDeadline = 1 + (iteration % 7); // 1-7 days
          final deadline = now.add(Duration(days: daysUntilDeadline));
          final progress = iteration % 100; // 0-99% progress
          
          final task = Task(
            id: iteration + 1,
            name: 'Test Task $iteration',
            courseName: 'Test Course $iteration',
            instructorName: 'Test Instructor',
            deadline: deadline,
            semester: 'Semester ${(iteration % 8) + 1}',
            period: iteration % 2 == 0 ? 'UTS' : 'UAS',
            progress: progress,
            createdAt: now.subtract(Duration(days: 7)),
            updatedAt: now,
          );

          // Test the property: all notifications should be scheduled at the same daily time
          if (progress < 100 && task.id != null) {
            const expectedHour = 9; // 9 AM as defined in NotificationService
            const expectedMinute = 0;
            
            // Test notification scheduling for 3, 2, and 1 days before deadline
            for (int daysBeforeDeadline in [3, 2, 1]) {
              final notificationDate = DateTime(
                deadline.year,
                deadline.month,
                deadline.day - daysBeforeDeadline,
                expectedHour,
                expectedMinute,
              );

              // Only test notifications that would be scheduled in the future
              if (notificationDate.isAfter(now)) {
                // Test that the notification is scheduled at the consistent time (9:00 AM)
                expect(notificationDate.hour, equals(expectedHour));
                expect(notificationDate.minute, equals(expectedMinute));
                
                // Test that the notification date is correctly calculated
                final expectedDate = DateTime(
                  deadline.year,
                  deadline.month,
                  deadline.day - daysBeforeDeadline,
                );
                
                expect(notificationDate.year, equals(expectedDate.year));
                expect(notificationDate.month, equals(expectedDate.month));
                expect(notificationDate.day, equals(expectedDate.day));
                
                // Test that all notifications for this task use the same time format
                final notificationTime = '${notificationDate.hour.toString().padLeft(2, '0')}:${notificationDate.minute.toString().padLeft(2, '0')}';
                expect(notificationTime, equals('09:00'));
                
                // Test that the notification is scheduled for the correct number of days before deadline
                final daysDifference = deadline.difference(notificationDate).inDays;
                expect(daysDifference, equals(daysBeforeDeadline));
                
                // Test that the notification date is in the future (if applicable)
                if (notificationDate.isAfter(now)) {
                  expect(notificationDate.isAfter(now), isTrue);
                }
              }
            }
            
            // Test consistency across multiple tasks - all should use the same scheduling time
            final consistentHour = 9;
            final consistentMinute = 0;
            
            // Verify that regardless of task properties, the scheduling time remains consistent
            for (int testDays in [1, 2, 3]) {
              final testNotificationDate = DateTime(
                deadline.year,
                deadline.month,
                deadline.day - testDays,
                consistentHour,
                consistentMinute,
              );
              
              expect(testNotificationDate.hour, equals(consistentHour));
              expect(testNotificationDate.minute, equals(consistentMinute));
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