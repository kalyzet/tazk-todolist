import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:math';

import '../../lib/services/deadline_service.dart';
import '../../lib/models/task.dart';
import '../../lib/repositories/task_repository.dart';
import '../../lib/database/database_helper.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DeadlineService Property Tests', () {
    late DeadlineService deadlineService;
    late TaskRepository taskRepository;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      // Use unique database name for each test to avoid locking
      final testDbName = 'test_deadline_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.db';
      DatabaseHelper.setTestDatabaseName(testDbName);
      
      // Initialize repository and service
      taskRepository = TaskRepository();
      deadlineService = DeadlineService(taskRepository: taskRepository);
      databaseHelper = DatabaseHelper();
      
      // Clear any existing data
      await taskRepository.clear();
    });

    tearDown(() async {
      await databaseHelper.close();
      await databaseHelper.deleteDatabase();
      DatabaseHelper.setTestDatabaseName(null);
    });

    group('Property 10: Deadline calculation consistency', () {
      test('**Feature: academic-task-manager, Property 10: Deadline calculation consistency** - For any task with a deadline, the calculated remaining days should equal the difference between the deadline date and current date', () async {
        final random = Random();
        
        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate random deadline (can be past, present, or future)
          final daysOffset = random.nextInt(61) - 30; // -30 to +30 days
          final deadline = DateTime.now().add(Duration(days: daysOffset));
          
          // Calculate remaining days using service
          final calculatedDays = deadlineService.calculateRemainingDays(deadline);
          
          // Calculate expected remaining days manually
          final now = DateTime.now();
          final currentDate = DateTime(now.year, now.month, now.day);
          final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
          final expectedDays = deadlineDate.difference(currentDate).inDays;
          
          // Property: Calculated days should match manual calculation
          expect(calculatedDays, equals(expectedDays),
                 reason: 'Calculated remaining days ($calculatedDays) should equal expected days ($expectedDays) for deadline $deadline');
        }
      });
    });

    group('Property 11: Overdue detection', () {
      test('**Feature: academic-task-manager, Property 11: Overdue detection** - For any task where the deadline date is before the current date, the system should display an overdue indicator', () async {
        final random = Random();
        
        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate random deadline (can be past, present, or future)
          final daysOffset = random.nextInt(61) - 30; // -30 to +30 days
          final deadline = DateTime.now().add(Duration(days: daysOffset));
          
          // Check if deadline is overdue using service
          final isOverdueResult = deadlineService.isOverdue(deadline);
          
          // Calculate expected overdue status manually
          final now = DateTime.now();
          final currentDate = DateTime(now.year, now.month, now.day);
          final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
          final expectedOverdue = deadlineDate.isBefore(currentDate);
          
          // Property: Overdue detection should match manual calculation
          expect(isOverdueResult, equals(expectedOverdue),
                 reason: 'Overdue detection ($isOverdueResult) should equal expected overdue status ($expectedOverdue) for deadline $deadline');
          
          // Additional verification: if overdue, remaining days should be negative
          if (isOverdueResult) {
            final remainingDays = deadlineService.calculateRemainingDays(deadline);
            expect(remainingDays, lessThan(0),
                   reason: 'Overdue tasks should have negative remaining days but got $remainingDays');
          }
        }
      });
    });
  });
}