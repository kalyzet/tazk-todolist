import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

import '../../lib/services/task_service.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/repositories/task_repository.dart';
import '../../lib/repositories/preferences_repository.dart';
import '../../lib/models/task.dart';
import '../../lib/models/academic_context.dart';
import '../../lib/database/database_helper.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Offline Functionality Tests', () {
    late TaskService taskService;
    late BackupService backupService;
    late TaskRepository taskRepository;
    late PreferencesRepository preferencesRepository;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Use unique database name for each test to avoid locking
      final testDbName = 'test_offline_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.db';
      DatabaseHelper.setTestDatabaseName(testDbName);
      
      taskRepository = TaskRepository();
      preferencesRepository = PreferencesRepository();
      taskService = TaskService(taskRepository: taskRepository);
      backupService = BackupService();
      databaseHelper = DatabaseHelper();
      
      // Clear any existing data
      await taskRepository.clear();
    });

    tearDown(() async {
      await databaseHelper.close();
      await databaseHelper.deleteDatabase();
      DatabaseHelper.setTestDatabaseName(null);
    });

    group('Database Initialization Tests', () {
      test('Database should initialize properly on first app launch without internet', () async {
        // Simulate first app launch by using a fresh database
        final freshDbName = 'test_fresh_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.db';
        DatabaseHelper.setTestDatabaseName(freshDbName);
        
        // Create new instances with fresh database
        final freshRepository = TaskRepository();
        final freshService = TaskService(taskRepository: freshRepository);
        
        // Test that database initializes and basic operations work
        final testTask = _generateValidTask(Random());
        final createdTask = await freshService.createTask(testTask);
        
        expect(createdTask.id, isNotNull, reason: 'Task should be created with ID');
        expect(createdTask.name, equals(testTask.name));
        expect(createdTask.progress, equals(0), reason: 'New task should have 0% progress');
        
        // Verify task can be retrieved
        final retrievedTask = await freshService.getTaskById(createdTask.id!);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.name, equals(testTask.name));
        
        // Clean up
        final freshDbHelper = DatabaseHelper();
        await freshDbHelper.close();
        await freshDbHelper.deleteDatabase();
      });

      test('Database schema should be created correctly on initialization', () async {
        // Get database instance to trigger initialization
        final db = await databaseHelper.database;
        
        // Verify tasks table exists with correct schema
        final tableInfo = await db.rawQuery("PRAGMA table_info(tasks)");
        
        // Expected columns
        final expectedColumns = {
          'id': 'INTEGER',
          'name': 'TEXT',
          'course_name': 'TEXT',
          'instructor_name': 'TEXT',
          'deadline': 'TEXT',
          'semester': 'TEXT',
          'period': 'TEXT',
          'progress': 'INTEGER',
          'created_at': 'TEXT',
          'updated_at': 'TEXT',
        };
        
        expect(tableInfo.length, equals(expectedColumns.length));
        
        for (final column in tableInfo) {
          final columnName = column['name'] as String;
          final columnType = column['type'] as String;
          
          expect(expectedColumns.containsKey(columnName), isTrue,
                 reason: 'Column $columnName should exist in schema');
          expect(columnType, contains(expectedColumns[columnName]!),
                 reason: 'Column $columnName should have correct type');
        }
        
        // Verify indexes exist
        final indexes = await db.rawQuery("PRAGMA index_list(tasks)");
        final indexNames = indexes.map((index) => index['name'] as String).toSet();
        
        expect(indexNames.contains('idx_tasks_context'), isTrue,
               reason: 'Context index should exist');
        expect(indexNames.contains('idx_tasks_deadline'), isTrue,
               reason: 'Deadline index should exist');
      });
    });

    group('CRUD Operations Offline Tests', () {
      test('All CRUD operations should work without internet connectivity', () async {
        final random = Random();
        
        // Test CREATE operation
        final createTask = _generateValidTask(random);
        final createdTask = await taskService.createTask(createTask);
        
        expect(createdTask.id, isNotNull);
        expect(createdTask.name, equals(createTask.name));
        expect(createdTask.progress, equals(0));
        
        // Test READ operation
        final readTask = await taskService.getTaskById(createdTask.id!);
        expect(readTask, isNotNull);
        expect(readTask!.name, equals(createTask.name));
        expect(readTask.courseName, equals(createTask.courseName));
        expect(readTask.instructorName, equals(createTask.instructorName));
        expect(readTask.deadline, equals(createTask.deadline));
        expect(readTask.semester, equals(createTask.semester));
        expect(readTask.period, equals(createTask.period));
        
        // Test UPDATE operation
        final updatedProgress = random.nextInt(101);
        final updateTask = readTask.copyWith(
          progress: updatedProgress,
          name: 'Updated ${readTask.name}',
        );
        
        final updatedTask = await taskService.updateTask(updateTask);
        expect(updatedTask.progress, equals(updatedProgress));
        expect(updatedTask.name, equals('Updated ${readTask.name}'));
        
        // Verify update persisted
        final verifyUpdatedTask = await taskService.getTaskById(createdTask.id!);
        expect(verifyUpdatedTask!.progress, equals(updatedProgress));
        expect(verifyUpdatedTask.name, equals('Updated ${readTask.name}'));
        
        // Test DELETE operation
        await taskService.deleteTask(createdTask.id!);
        
        // Verify task was deleted
        final deletedTask = await taskService.getTaskById(createdTask.id!);
        expect(deletedTask, isNull);
        
        // Verify task is not in list
        final allTasks = await taskService.getAllTasks();
        expect(allTasks.any((task) => task.id == createdTask.id), isFalse);
      });

      test('Context-based filtering should work offline', () async {
        final random = Random();
        
        // Create tasks for different contexts
        final context1 = AcademicContext(semester: 'Semester 1', period: 'UTS');
        final context2 = AcademicContext(semester: 'Semester 1', period: 'UAS');
        final context3 = AcademicContext(semester: 'Semester 2', period: 'UTS');
        
        final tasksContext1 = <Task>[];
        final tasksContext2 = <Task>[];
        final tasksContext3 = <Task>[];
        
        // Create 3 tasks for each context
        for (int i = 0; i < 3; i++) {
          final task1 = _generateTaskForContext(random, context1);
          final task2 = _generateTaskForContext(random, context2);
          final task3 = _generateTaskForContext(random, context3);
          
          final created1 = await taskService.createTask(task1);
          final created2 = await taskService.createTask(task2);
          final created3 = await taskService.createTask(task3);
          
          tasksContext1.add(created1);
          tasksContext2.add(created2);
          tasksContext3.add(created3);
        }
        
        // Test filtering for each context
        final filtered1 = await taskService.getTasksByContext(context1);
        final filtered2 = await taskService.getTasksByContext(context2);
        final filtered3 = await taskService.getTasksByContext(context3);
        
        expect(filtered1.length, equals(3));
        expect(filtered2.length, equals(3));
        expect(filtered3.length, equals(3));
        
        // Verify all tasks in filtered1 belong to context1
        for (final task in filtered1) {
          expect(task.semester, equals(context1.semester));
          expect(task.period, equals(context1.period));
        }
        
        // Verify all tasks in filtered2 belong to context2
        for (final task in filtered2) {
          expect(task.semester, equals(context2.semester));
          expect(task.period, equals(context2.period));
        }
        
        // Verify all tasks in filtered3 belong to context3
        for (final task in filtered3) {
          expect(task.semester, equals(context3.semester));
          expect(task.period, equals(context3.period));
        }
      });

      test('Batch operations should maintain data integrity offline', () async {
        final random = Random();
        final tasks = <Task>[];
        
        // Create multiple tasks in batch
        for (int i = 0; i < 10; i++) {
          final task = _generateValidTask(random);
          final createdTask = await taskService.createTask(task);
          tasks.add(createdTask);
        }
        
        // Verify all tasks were created
        final allTasks = await taskService.getAllTasks();
        expect(allTasks.length, equals(10));
        
        // Update all tasks in batch
        for (int i = 0; i < tasks.length; i++) {
          final updatedTask = tasks[i].copyWith(
            progress: (i + 1) * 10, // 10%, 20%, 30%, etc.
            name: 'Batch Updated ${tasks[i].name}',
          );
          await taskService.updateTask(updatedTask);
          tasks[i] = updatedTask;
        }
        
        // Verify all updates persisted
        final updatedTasks = await taskService.getAllTasks();
        expect(updatedTasks.length, equals(10));
        
        for (int i = 0; i < updatedTasks.length; i++) {
          final task = updatedTasks.firstWhere((t) => t.id == tasks[i].id);
          expect(task.progress, equals((i + 1) * 10));
          expect(task.name, contains('Batch Updated'));
        }
        
        // Delete half of the tasks
        for (int i = 0; i < 5; i++) {
          await taskService.deleteTask(tasks[i].id!);
        }
        
        // Verify correct number of tasks remain
        final remainingTasks = await taskService.getAllTasks();
        expect(remainingTasks.length, equals(5));
        
        // Verify correct tasks were deleted
        for (int i = 0; i < 5; i++) {
          final deletedTask = await taskService.getTaskById(tasks[i].id!);
          expect(deletedTask, isNull);
        }
        
        for (int i = 5; i < 10; i++) {
          final remainingTask = await taskService.getTaskById(tasks[i].id!);
          expect(remainingTask, isNotNull);
        }
      });
    });

    group('Backup/Restore Offline Tests', () {
      test('Export functionality should work offline', () async {
        final random = Random();
        
        // Create test data
        final tasks = <Task>[];
        for (int i = 0; i < 5; i++) {
          final task = _generateValidTask(random);
          final createdTask = await taskService.createTask(task);
          tasks.add(createdTask);
        }
        
        // Export data
        final exportJson = await backupService.exportToJson();
        
        // Verify export format
        expect(exportJson, isNotEmpty);
        
        final exportData = jsonDecode(exportJson) as Map<String, dynamic>;
        expect(exportData.containsKey('version'), isTrue);
        expect(exportData.containsKey('tasks'), isTrue);
        
        final exportedTasks = exportData['tasks'] as List<dynamic>;
        expect(exportedTasks.length, equals(5));
        
        // Verify each exported task has all required fields
        for (final exportedTaskJson in exportedTasks) {
          final exportedTask = exportedTaskJson as Map<String, dynamic>;
          
          final requiredFields = [
            'name', 'course_name', 'instructor_name', 'deadline',
            'semester', 'period', 'progress', 'created_at', 'updated_at'
          ];
          
          for (final field in requiredFields) {
            expect(exportedTask.containsKey(field), isTrue,
                   reason: 'Exported task should contain field: $field');
          }
        }
      });

      test('Import functionality should work offline', () async {
        final random = Random();
        
        // Create initial data
        final initialTask = _generateValidTask(random);
        await taskService.createTask(initialTask);
        
        // Create import data
        final importTasks = <Task>[];
        for (int i = 0; i < 3; i++) {
          importTasks.add(_generateValidTask(random));
        }
        
        final importData = {
          'version': '1.0',
          'exported_at': DateTime.now().toIso8601String(),
          'tasks': importTasks.map((task) => task.toJson()).toList(),
        };
        final importJson = jsonEncode(importData);
        
        // Import data
        final importedCount = await backupService.importFromJson(importJson);
        expect(importedCount, equals(3));
        
        // Verify total task count
        final allTasks = await taskService.getAllTasks();
        expect(allTasks.length, equals(4)); // 1 initial + 3 imported
        
        // Verify imported tasks exist
        for (final importTask in importTasks) {
          final foundTask = allTasks.firstWhere(
            (task) => task.name == importTask.name &&
                     task.courseName == importTask.courseName &&
                     task.instructorName == importTask.instructorName,
            orElse: () => throw StateError('Imported task not found: ${importTask.name}'),
          );
          
          expect(foundTask.deadline, equals(importTask.deadline));
          expect(foundTask.semester, equals(importTask.semester));
          expect(foundTask.period, equals(importTask.period));
          expect(foundTask.progress, equals(importTask.progress));
        }
      });

      test('Full backup-restore cycle should work offline', () async {
        final random = Random();
        
        // Create original data
        final originalTasks = <Task>[];
        for (int i = 0; i < 7; i++) {
          final task = _generateValidTask(random);
          final createdTask = await taskService.createTask(task);
          originalTasks.add(createdTask);
        }
        
        // Export data
        final exportJson = await backupService.exportToJson();
        
        // Clear database (simulate data loss)
        await taskRepository.clear();
        
        // Verify database is empty
        final emptyTasks = await taskService.getAllTasks();
        expect(emptyTasks.length, equals(0));
        
        // Restore data
        final importedCount = await backupService.importFromJson(exportJson);
        expect(importedCount, equals(7));
        
        // Verify all data was restored
        final restoredTasks = await taskService.getAllTasks();
        expect(restoredTasks.length, equals(7));
        
        // Verify each original task was restored correctly
        for (final originalTask in originalTasks) {
          final restoredTask = restoredTasks.firstWhere(
            (task) => task.name == originalTask.name &&
                     task.courseName == originalTask.courseName &&
                     task.instructorName == originalTask.instructorName,
            orElse: () => throw StateError('Original task not restored: ${originalTask.name}'),
          );
          
          expect(restoredTask.deadline, equals(originalTask.deadline));
          expect(restoredTask.semester, equals(originalTask.semester));
          expect(restoredTask.period, equals(originalTask.period));
          expect(restoredTask.progress, equals(originalTask.progress));
        }
      });
    });

    group('Error Handling Offline Tests', () {
      test('Database operations should handle errors gracefully', () async {
        // Test invalid task creation
        final invalidTask = Task(
          name: '', // Empty name should be handled
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: DateTime.now().add(Duration(days: 1)),
          semester: 'Semester 1',
          period: 'UTS',
          progress: 0,
        );
        
        // This should not crash but may throw validation error
        try {
          await taskService.createTask(invalidTask);
          // If no error thrown, verify task was not created with empty name
          final allTasks = await taskService.getAllTasks();
          if (allTasks.isNotEmpty) {
            expect(allTasks.first.name, isNotEmpty);
          }
        } catch (e) {
          // Error is acceptable for invalid input
          expect(e, isA<ArgumentError>());
        }
        
        // Test updating non-existent task
        final nonExistentTask = _generateValidTask(Random()).copyWith(id: 99999);
        
        try {
          await taskService.updateTask(nonExistentTask);
          // If no error, verify task was not actually updated
          final retrievedTask = await taskService.getTaskById(99999);
          expect(retrievedTask, isNull);
        } catch (e) {
          // Error is acceptable for non-existent task
          expect(e, isNotNull);
        }
        
        // Test deleting non-existent task
        try {
          await taskService.deleteTask(99999);
          // Should not crash even if task doesn't exist
        } catch (e) {
          // Error is acceptable but should not crash the app
          expect(e, isNotNull);
        }
      });

      test('Preferences should work offline with error handling', () async {
        // Clear preferences at start to ensure clean state
        await preferencesRepository.clearAll();
        
        // Test saving and retrieving context
        final context = AcademicContext(semester: 'Semester 1', period: 'UTS');
        final saveResult = await preferencesRepository.saveLastContext(context);
        expect(saveResult, isTrue, reason: 'Context should be saved successfully');
        
        final retrievedContext = await preferencesRepository.getLastContext();
        expect(retrievedContext, isNotNull, reason: 'Context should be retrieved after saving');
        expect(retrievedContext!.semester, equals(context.semester));
        expect(retrievedContext.period, equals(context.period));
        
        // Test saving and retrieving sort preference
        final sortSaveResult = await preferencesRepository.saveSortPreference('deadline');
        expect(sortSaveResult, isTrue, reason: 'Sort preference should be saved successfully');
        
        final sortPreference = await preferencesRepository.getSortPreference();
        expect(sortPreference, equals('deadline'));
        
        // Test retrieving non-existent preferences
        final newPrefsRepo = PreferencesRepository();
        
        // Clear all preferences to test default behavior
        await newPrefsRepo.clearAll();
        
        final defaultContext = await newPrefsRepo.getLastContext();
        // Should not crash, returns null when no context is saved
        expect(defaultContext, isNull);
        
        final defaultSort = await newPrefsRepo.getSortPreference();
        expect(defaultSort, isNotNull); // Should have a default value
        expect(defaultSort, equals('deadline')); // Default should be 'deadline'
      });
    });

    group('Property-Based Tests', () {
      /// **Feature: academic-task-manager, Property 24: Local data persistence**
      /// **Validates: Requirements 10.1, 10.2, 10.3**
      test('Property 24: Local data persistence', () async {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int iteration = 0; iteration < 100; iteration++) {
          // Clear database and preferences for each iteration
          await taskRepository.clear();
          SharedPreferences.setMockInitialValues({});
          
          // Generate random sequence of offline operations
          final operationCount = 5 + random.nextInt(15); // 5-20 operations
          final tasks = <Task>[];
          final contexts = <AcademicContext>[];
          
          for (int i = 0; i < operationCount; i++) {
            final operationType = random.nextInt(4); // 0=create, 1=read, 2=update, 3=delete
            
            switch (operationType) {
              case 0: // CREATE operation
                final task = _generateValidTask(random);
                
                // Property: Task creation should work offline and persist locally
                final createdTask = await taskService.createTask(task);
                expect(createdTask.id, isNotNull, 
                       reason: 'Task should be created with ID using local SQLite storage');
                expect(createdTask.progress, equals(0),
                       reason: 'New task should have 0% progress');
                
                tasks.add(createdTask);
                break;
                
              case 1: // READ operation
                if (tasks.isNotEmpty) {
                  final taskToRead = tasks[random.nextInt(tasks.length)];
                  
                  // Property: Task reading should work offline from local storage
                  final readTask = await taskService.getTaskById(taskToRead.id!);
                  expect(readTask, isNotNull,
                         reason: 'Task should be readable from local SQLite storage');
                  expect(readTask!.name, equals(taskToRead.name));
                  expect(readTask.courseName, equals(taskToRead.courseName));
                  expect(readTask.deadline, equals(taskToRead.deadline));
                }
                break;
                
              case 2: // UPDATE operation
                if (tasks.isNotEmpty) {
                  final taskIndex = random.nextInt(tasks.length);
                  final taskToUpdate = tasks[taskIndex];
                  final newProgress = random.nextInt(101);
                  final updatedTask = taskToUpdate.copyWith(
                    progress: newProgress,
                    name: 'Updated ${taskToUpdate.name}',
                  );
                  
                  // Property: Task updating should work offline and persist locally
                  final resultTask = await taskService.updateTask(updatedTask);
                  expect(resultTask.progress, equals(newProgress),
                         reason: 'Task update should persist to local SQLite storage');
                  expect(resultTask.name, equals('Updated ${taskToUpdate.name}'));
                  
                  tasks[taskIndex] = resultTask;
                }
                break;
                
              case 3: // DELETE operation
                if (tasks.isNotEmpty) {
                  final taskIndex = random.nextInt(tasks.length);
                  final taskToDelete = tasks[taskIndex];
                  
                  // Property: Task deletion should work offline and persist locally
                  await taskService.deleteTask(taskToDelete.id!);
                  
                  // Verify deletion persisted
                  final deletedTask = await taskService.getTaskById(taskToDelete.id!);
                  expect(deletedTask, isNull,
                         reason: 'Deleted task should not exist in local SQLite storage');
                  
                  tasks.removeAt(taskIndex);
                }
                break;
            }
          }
          
          // Test context operations offline
          final context = AcademicContext(
            semester: 'Semester ${1 + random.nextInt(8)}',
            period: random.nextBool() ? 'UTS' : 'UAS',
          );
          
          // Property: Context saving should work offline
          final contextSaved = await preferencesRepository.saveLastContext(context);
          expect(contextSaved, isTrue,
                 reason: 'Context should be saved to local SharedPreferences storage');
          
          final retrievedContext = await preferencesRepository.getLastContext();
          expect(retrievedContext, equals(context),
                 reason: 'Context should be retrievable from local SharedPreferences storage');
          
          // Test sort preference operations offline
          final validSortOptions = ['deadline', 'progress', 'course_name', 'task_name'];
          final sortPreference = validSortOptions[random.nextInt(validSortOptions.length)];
          
          // Property: Sort preference should work offline
          final sortSaved = await preferencesRepository.saveSortPreference(sortPreference);
          expect(sortSaved, isTrue,
                 reason: 'Sort preference should be saved to local SharedPreferences storage');
          
          final retrievedSort = await preferencesRepository.getSortPreference();
          expect(retrievedSort, equals(sortPreference),
                 reason: 'Sort preference should be retrievable from local SharedPreferences storage');
          
          // Verify all operations completed without requiring internet connectivity
          // by checking that all expected tasks still exist in local storage
          final finalTasks = await taskService.getAllTasks();
          expect(finalTasks.length, equals(tasks.length),
                 reason: 'All remaining tasks should persist in local SQLite storage');
          
          for (final expectedTask in tasks) {
            final foundTask = finalTasks.firstWhere(
              (task) => task.id == expectedTask.id,
              orElse: () => throw StateError('Expected task not found in local storage'),
            );
            
            expect(foundTask.name, equals(expectedTask.name));
            expect(foundTask.progress, equals(expectedTask.progress));
            expect(foundTask.courseName, equals(expectedTask.courseName));
            expect(foundTask.deadline, equals(expectedTask.deadline));
          }
          
          // Test backup/restore operations offline
          if (tasks.isNotEmpty) {
            // Property: Export should work offline
            final exportJson = await backupService.exportToJson();
            expect(exportJson, isNotEmpty,
                   reason: 'Export should work using local SQLite storage');
            
            // Clear database to simulate data loss
            await taskRepository.clear();
            
            // Property: Import should work offline
            final importedCount = await backupService.importFromJson(exportJson);
            expect(importedCount, equals(tasks.length),
                   reason: 'Import should work using local SQLite storage');
            
            // Verify all tasks were restored from local backup
            final restoredTasks = await taskService.getAllTasks();
            expect(restoredTasks.length, equals(tasks.length),
                   reason: 'All tasks should be restored to local SQLite storage');
          }
        }
      });
    });
  });
}

/// Generate a valid task with random data for testing
Task _generateValidTask(Random random) {
  final courses = ['Basis Data', 'Algoritma', 'Jaringan Komputer', 'Pemrograman Web', 'Sistem Operasi'];
  final instructors = ['Dr. Ahmad', 'Prof. Siti', 'Ir. Budi', 'Dr. Rina', 'Prof. Joko'];
  final semesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5'];
  final periods = ['UTS', 'UAS'];
  
  // Generate future deadline (1-30 days from now)
  final futureDeadline = DateTime.now().add(Duration(days: random.nextInt(30) + 1));
  
  return Task(
    name: 'Tugas ${random.nextInt(1000)}',
    courseName: courses[random.nextInt(courses.length)],
    instructorName: instructors[random.nextInt(instructors.length)],
    deadline: futureDeadline,
    semester: semesters[random.nextInt(semesters.length)],
    period: periods[random.nextInt(periods.length)],
    progress: random.nextInt(101),
  );
}

/// Generate a task for a specific context
Task _generateTaskForContext(Random random, AcademicContext context) {
  final courses = ['Basis Data', 'Algoritma', 'Jaringan Komputer', 'Pemrograman Web', 'Sistem Operasi'];
  final instructors = ['Dr. Ahmad', 'Prof. Siti', 'Ir. Budi', 'Dr. Rina', 'Prof. Joko'];
  
  final futureDeadline = DateTime.now().add(Duration(days: random.nextInt(30) + 1));
  
  return Task(
    name: 'Tugas ${context.semester} ${context.period} ${random.nextInt(100)}',
    courseName: courses[random.nextInt(courses.length)],
    instructorName: instructors[random.nextInt(instructors.length)],
    deadline: futureDeadline,
    semester: context.semester,
    period: context.period,
    progress: random.nextInt(101),
  );
}