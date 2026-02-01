import 'package:flutter_test/flutter_test.dart';
import '../../../lib/models/task.dart';
import '../../../lib/services/deadline_service.dart';

/// Property-based tests for deadline refresh functionality
/// 
/// **Feature: academic-task-manager, Property 12: Deadline calculation refresh**
/// **Validates: Requirements 5.4**
void main() {
  group('Deadline Refresh Property Tests', () {
    late DeadlineService deadlineService;

    setUp(() {
      deadlineService = DeadlineService();
    });

    /// Generate a task with specific deadline relative to current date
    Task generateTaskWithDeadlineOffset(int daysOffset, {int? taskId}) {
      return Task(
        id: taskId ?? 1,
        name: 'Test Task',
        courseName: 'Test Course',
        instructorName: 'Test Instructor',
        deadline: DateTime.now().add(Duration(days: daysOffset)),
        semester: 'Semester 1',
        period: 'UTS',
        progress: 50,
      );
    }

    test(
      '**Feature: academic-task-manager, Property 12: Deadline calculation refresh** - '
      'For any task list display, remaining days should be recalculated using the current date as reference',
      () {
        // Test with various deadline offsets to ensure property holds across all scenarios
        final testDeadlineOffsets = [-5, -1, 0, 1, 3, 7, 30]; // Past, today, future deadlines
        
        for (final daysOffset in testDeadlineOffsets) {
          // Generate task with specific deadline offset
          final task = generateTaskWithDeadlineOffset(daysOffset);
          
          // Calculate remaining days using current date as reference
          final remainingDays = deadlineService.calculateRemainingDays(task.deadline);
          final isOverdue = deadlineService.isOverdue(task.deadline);
          
          // The calculation should be based on the actual difference between deadline and current date
          final now = DateTime.now();
          final currentDate = DateTime(now.year, now.month, now.day);
          final deadlineDate = DateTime(task.deadline.year, task.deadline.month, task.deadline.day);
          final expectedDifference = deadlineDate.difference(currentDate).inDays;
          
          // Property: Remaining days should always equal the actual difference between deadline and current date
          expect(remainingDays, equals(expectedDifference),
              reason: 'Remaining days should equal the actual difference between deadline and current date for offset $daysOffset');
          
          // Property: Overdue status should be consistent with remaining days calculation
          if (expectedDifference < 0) {
            expect(isOverdue, isTrue,
                reason: 'Task should be marked as overdue when deadline is in the past (offset: $daysOffset)');
          } else {
            expect(isOverdue, isFalse,
                reason: 'Task should not be marked as overdue when deadline is today or in the future (offset: $daysOffset)');
          }
        }
      },
    );

    test(
      '**Feature: academic-task-manager, Property 12: Deadline calculation refresh** - '
      'Deadline calculations should be consistent across multiple calls',
      () {
        // Create multiple tasks with different deadlines
        final tasks = [
          generateTaskWithDeadlineOffset(-2, taskId: 1), // Overdue
          generateTaskWithDeadlineOffset(0, taskId: 2),  // Due today
          generateTaskWithDeadlineOffset(1, taskId: 3),  // Due tomorrow
          generateTaskWithDeadlineOffset(5, taskId: 4),  // Due in 5 days
        ];
        
        // For each task, store its initial calculation and verify consistency across multiple calls
        for (final task in tasks) {
          final initialRemainingDays = deadlineService.calculateRemainingDays(task.deadline);
          final initialOverdueStatus = deadlineService.isOverdue(task.deadline);
          
          // Simulate multiple calls (as would happen during UI refreshes)
          for (int i = 0; i < 10; i++) {
            final currentCalculation = deadlineService.calculateRemainingDays(task.deadline);
            final currentOverdueStatus = deadlineService.isOverdue(task.deadline);
            
            // Property: Deadline calculations should remain consistent across multiple calls for the same task
            expect(currentCalculation, equals(initialRemainingDays),
                reason: 'Deadline calculation should remain consistent across multiple calls for task ${task.id} with deadline offset ${task.deadline.difference(DateTime.now()).inDays} (iteration $i)');
            
            expect(currentOverdueStatus, equals(initialOverdueStatus),
                reason: 'Overdue status should remain consistent across multiple calls for task ${task.id} (iteration $i)');
          }
        }
      },
    );

    test(
      '**Feature: academic-task-manager, Property 12: Deadline calculation refresh** - '
      'Deadline status should update correctly when current date changes',
      () {
        // This test verifies that deadline calculations always use current date as reference
        // We test with a task that has a fixed deadline
        
        final fixedDeadline = DateTime(2024, 12, 25); // Fixed deadline: Christmas 2024
        final task = Task(
          id: 1,
          name: 'Test Task',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: fixedDeadline,
          semester: 'Semester 1',
          period: 'UTS',
          progress: 50,
        );
        
        // Calculate remaining days using current date as reference
        final remainingDays = deadlineService.calculateRemainingDays(task.deadline);
        final isOverdue = deadlineService.isOverdue(task.deadline);
        
        // Verify that the deadline calculation uses current date as reference
        final now = DateTime.now();
        final currentDate = DateTime(now.year, now.month, now.day);
        final deadlineDate = DateTime(task.deadline.year, task.deadline.month, task.deadline.day);
        final expectedDifference = deadlineDate.difference(currentDate).inDays;
        
        // Property: Calculation should always be based on current date
        expect(remainingDays, equals(expectedDifference),
            reason: 'Remaining days should equal the actual difference between deadline and current date');
        
        // Property: Overdue status should be consistent with current date comparison
        if (expectedDifference < 0) {
          expect(isOverdue, isTrue,
              reason: 'Task should be marked as overdue when deadline is before current date');
        } else {
          expect(isOverdue, isFalse,
              reason: 'Task should not be marked as overdue when deadline is today or after current date');
        }
      },
    );

    test(
      '**Feature: academic-task-manager, Property 12: Deadline calculation refresh** - '
      'Deadline calculations should be consistent across different task data',
      () {
        // Test with various task configurations to ensure deadline refresh is consistent
        // regardless of other task properties
        final baseDeadline = DateTime.now().add(const Duration(days: 3));
        
        final testTasks = [
          Task(
            id: 1,
            name: 'Short Task',
            courseName: 'Math',
            instructorName: 'Dr. A',
            deadline: baseDeadline,
            semester: 'Semester 1',
            period: 'UTS',
            progress: 25,
          ),
          Task(
            id: 2,
            name: 'Very Long Task Name That Might Wrap Multiple Lines',
            courseName: 'Computer Science and Information Technology',
            instructorName: 'Prof. Dr. Very Long Name Here',
            deadline: baseDeadline,
            semester: 'Semester 2',
            period: 'UAS',
            progress: 75,
          ),
          Task(
            id: 3,
            name: 'High Priority Task',
            courseName: 'Physics',
            instructorName: 'Dr. B',
            deadline: baseDeadline,
            semester: 'Semester 3',
            period: 'UTS',
            progress: 90,
          ),
        ];
        
        // All tasks have the same deadline, so they should all have the same remaining days
        final expectedRemainingDays = deadlineService.calculateRemainingDays(baseDeadline);
        final expectedOverdueStatus = deadlineService.isOverdue(baseDeadline);
        
        // Property: Tasks with identical deadlines should have identical deadline calculations
        // regardless of other properties (name, course, instructor, semester, period, progress)
        for (final task in testTasks) {
          final actualRemainingDays = deadlineService.calculateRemainingDays(task.deadline);
          final actualOverdueStatus = deadlineService.isOverdue(task.deadline);
          
          expect(actualRemainingDays, equals(expectedRemainingDays),
              reason: 'Task ${task.name} should show same remaining days as other tasks with identical deadline');
          
          expect(actualOverdueStatus, equals(expectedOverdueStatus),
              reason: 'Task ${task.name} should show same overdue status as other tasks with identical deadline');
        }
      },
    );
  });
}