import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:Tazk/models/academic_context.dart';
import 'package:Tazk/models/task.dart';
import 'package:Tazk/repositories/preferences_repository.dart';
import 'package:Tazk/repositories/task_repository.dart';
import 'package:Tazk/services/backup_service.dart';
import 'package:Tazk/services/notification_service.dart';
import 'package:Tazk/services/task_service.dart';
import 'package:Tazk/database/database_helper.dart';

void main() {
  group('End-to-End Workflow Tests', () {
    late TaskRepository taskRepository;
    late PreferencesRepository preferencesRepository;
    late NotificationService notificationService;
    late BackupService backupService;
    late TaskService taskService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Clear shared preferences
      SharedPreferences.setMockInitialValues({});
      
      // Set up test database
      DatabaseHelper.setTestDatabaseName('test_e2e_${DateTime.now().millisecondsSinceEpoch}.db');
      
      taskRepository = TaskRepository();
      preferencesRepository = PreferencesRepository();
      notificationService = NotificationService();
      backupService = BackupService();
      taskService = TaskService();
    });

    tearDown(() async {
      // Clean up test database
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabase();
      DatabaseHelper.setTestDatabaseName(null);
    });

    test('Complete user journey from setup to task completion', () async {
      // Step 1: Initial setup - save academic context
      final context = AcademicContext(semester: 'Semester 1', period: 'UTS');
      final contextSaved = await preferencesRepository.saveLastContext(context);
      expect(contextSaved, isTrue);

      // Verify context can be retrieved
      final retrievedContext = await preferencesRepository.getLastContext();
      expect(retrievedContext, isNotNull);
      expect(retrievedContext!.semester, equals('Semester 1'));
      expect(retrievedContext.period, equals('UTS'));

      // Step 2: Create a new task
      final task = Task(
        name: 'Tugas Database',
        courseName: 'Basis Data',
        instructorName: 'Dr. Ahmad',
        deadline: DateTime.now().add(const Duration(days: 3)),
        semester: context.semester,
        period: context.period,
        progress: 0,
      );

      final createdTask = await taskService.createTask(task);
      expect(createdTask.id, isNotNull);
      expect(createdTask.name, equals('Tugas Database'));
      expect(createdTask.progress, equals(0));

      // Step 3: Retrieve tasks by context
      final contextTasks = await taskRepository.findByContext(context.semester, context.period);
      expect(contextTasks.length, equals(1));
      expect(contextTasks.first.name, equals('Tugas Database'));

      // Step 4: Update task progress
      final updatedTask = createdTask.copyWith(progress: 50);
      final savedUpdatedTask = await taskService.updateTask(updatedTask);
      expect(savedUpdatedTask.progress, equals(50));

      // Step 5: Complete the task
      final completedTask = savedUpdatedTask.copyWith(progress: 100);
      final finalTask = await taskService.updateTask(completedTask);
      expect(finalTask.progress, equals(100));

      // Verify task completion
      final finalTasks = await taskRepository.findByContext(context.semester, context.period);
      expect(finalTasks.first.progress, equals(100));
    });

    test('Notification scheduling and cancellation workflow', () async {
      final context = AcademicContext(semester: 'Semester 1', period: 'UTS');
      
      // Create task with deadline in 2 days
      final task = Task(
        name: 'Test Task',
        courseName: 'Test Course',
        instructorName: 'Test Instructor',
        deadline: DateTime.now().add(const Duration(days: 2)),
        semester: context.semester,
        period: context.period,
        progress: 0,
      );

      // Insert task
      final taskId = await taskRepository.insert(task);
      final savedTask = await taskRepository.findById(taskId);

      // Schedule notifications
      await notificationService.scheduleTaskNotifications(savedTask!);

      // Verify notifications are scheduled (this would require mocking the notification plugin)
      // For now, we verify the method completes without error

      // Update task progress to 100%
      final completedTask = savedTask.copyWith(progress: 100);
      await taskRepository.update(completedTask);

      // Cancel notifications for completed task
      await notificationService.cancelTaskNotifications(taskId);

      // Verify cancellation completes without error
      expect(true, isTrue); // Placeholder assertion
    });

    test('Context switching with proper data filtering', () async {
      // Create tasks for different contexts
      final utsTask = Task(
        name: 'UTS Task',
        courseName: 'Course A',
        instructorName: 'Instructor A',
        deadline: DateTime.now().add(const Duration(days: 5)),
        semester: 'Semester 1',
        period: 'UTS',
        progress: 50,
      );

      final uasTask = Task(
        name: 'UAS Task',
        courseName: 'Course B',
        instructorName: 'Instructor B',
        deadline: DateTime.now().add(const Duration(days: 10)),
        semester: 'Semester 1',
        period: 'UAS',
        progress: 25,
      );

      // Insert both tasks
      await taskRepository.insert(utsTask);
      await taskRepository.insert(uasTask);

      // Test UTS context filtering
      final utsTasks = await taskRepository.findByContext('Semester 1', 'UTS');
      expect(utsTasks.length, equals(1));
      expect(utsTasks.first.name, equals('UTS Task'));

      // Test UAS context filtering
      final uasTasks = await taskRepository.findByContext('Semester 1', 'UAS');
      expect(uasTasks.length, equals(1));
      expect(uasTasks.first.name, equals('UAS Task'));

      // Test different semester filtering
      final semester2Tasks = await taskRepository.findByContext('Semester 2', 'UTS');
      expect(semester2Tasks.length, equals(0));
    });

    test('Backup and restore functionality with real data', () async {
      // Create sample tasks
      final tasks = [
        Task(
          name: 'Task 1',
          courseName: 'Course 1',
          instructorName: 'Instructor 1',
          deadline: DateTime.now().add(const Duration(days: 3)),
          semester: 'Semester 1',
          period: 'UTS',
          progress: 30,
        ),
        Task(
          name: 'Task 2',
          courseName: 'Course 2',
          instructorName: 'Instructor 2',
          deadline: DateTime.now().add(const Duration(days: 7)),
          semester: 'Semester 1',
          period: 'UAS',
          progress: 75,
        ),
      ];

      // Insert tasks
      for (final task in tasks) {
        await taskRepository.insert(task);
      }

      // Export data
      final exportedJson = await backupService.exportToJson();
      expect(exportedJson, isNotEmpty);

      // Verify JSON contains task data
      expect(exportedJson, contains('Task 1'));
      expect(exportedJson, contains('Task 2'));
      expect(exportedJson, contains('Course 1'));
      expect(exportedJson, contains('Course 2'));

      // Clear database
      await taskRepository.clear();

      // Verify database is empty
      final emptyTasks = await taskRepository.findAll();
      expect(emptyTasks.length, equals(0));

      // Import data back
      await backupService.importFromJson(exportedJson);

      // Verify data is restored
      final restoredTasks = await taskRepository.findAll();
      expect(restoredTasks.length, equals(2));
      
      final restoredTask1 = restoredTasks.firstWhere((t) => t.name == 'Task 1');
      expect(restoredTask1.courseName, equals('Course 1'));
      expect(restoredTask1.progress, equals(30));
      
      final restoredTask2 = restoredTasks.firstWhere((t) => t.name == 'Task 2');
      expect(restoredTask2.courseName, equals('Course 2'));
      expect(restoredTask2.progress, equals(75));
    });
  });
}