import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/services/backup_service.dart';
import '../../lib/repositories/task_repository.dart';
import '../../lib/models/task.dart';
import '../../lib/database/database_helper.dart';

void main() {
  late BackupService backupService;
  late TaskRepository taskRepository;
  late DatabaseHelper databaseHelper;
  
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  
  setUp(() async {
    // Use unique database name for each test to avoid locking
    final testDbName = 'test_backup_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.db';
    DatabaseHelper.setTestDatabaseName(testDbName);
    
    backupService = BackupService();
    taskRepository = TaskRepository();
    databaseHelper = DatabaseHelper();
    
    // Clear database before each test
    await taskRepository.clear();
  });
  
  tearDown(() async {
    await databaseHelper.close();
    await databaseHelper.deleteDatabase();
    DatabaseHelper.setTestDatabaseName(null);
  });
  
  group('BackupService Property Tests', () {
    
    test('**Feature: academic-task-manager, Property 16: Export completeness** - For any task collection, exported JSON should contain all tasks with all required fields', () async {
      final random = Random();
      
      // Run property test with multiple iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Clear database for each iteration
        await taskRepository.clear();
        
        // Generate random number of tasks (0-10)
        final taskCount = random.nextInt(11);
        final originalTasks = <Task>[];
        
        for (int i = 0; i < taskCount; i++) {
          final task = _generateRandomTask(random);
          await taskRepository.insert(task);
          originalTasks.add(task);
        }
        
        // Export tasks to JSON
        final jsonData = await backupService.exportToJson();
        final exportData = jsonDecode(jsonData) as Map<String, dynamic>;
        
        // Verify export structure
        expect(exportData.containsKey('version'), isTrue, 
               reason: 'Export should contain version field');
        expect(exportData.containsKey('exported_at'), isTrue,
               reason: 'Export should contain exported_at field');
        expect(exportData.containsKey('tasks'), isTrue,
               reason: 'Export should contain tasks field');
        
        final exportedTasks = exportData['tasks'] as List<dynamic>;
        
        // Verify task count matches
        expect(exportedTasks.length, equals(taskCount),
               reason: 'Exported task count should match original task count');
        
        // Verify each exported task has all required fields
        for (final exportedTaskJson in exportedTasks) {
          final exportedTask = exportedTaskJson as Map<String, dynamic>;
          
          // Check all required fields are present
          final requiredFields = [
            'name', 'course_name', 'instructor_name', 'deadline',
            'semester', 'period', 'progress', 'created_at', 'updated_at'
          ];
          
          for (final field in requiredFields) {
            expect(exportedTask.containsKey(field), isTrue,
                   reason: 'Exported task should contain field: $field');
          }
          
          // Verify field types
          expect(exportedTask['name'], isA<String>());
          expect(exportedTask['course_name'], isA<String>());
          expect(exportedTask['instructor_name'], isA<String>());
          expect(exportedTask['deadline'], isA<String>());
          expect(exportedTask['semester'], isA<String>());
          expect(exportedTask['period'], isA<String>());
          expect(exportedTask['progress'], isA<int>());
          expect(exportedTask['created_at'], isA<String>());
          expect(exportedTask['updated_at'], isA<String>());
          
          // Verify date strings are valid ISO-8601
          expect(() => DateTime.parse(exportedTask['deadline'] as String), 
                 returnsNormally, reason: 'Deadline should be valid ISO-8601');
          expect(() => DateTime.parse(exportedTask['created_at'] as String), 
                 returnsNormally, reason: 'Created_at should be valid ISO-8601');
          expect(() => DateTime.parse(exportedTask['updated_at'] as String), 
                 returnsNormally, reason: 'Updated_at should be valid ISO-8601');
          
          // Verify progress range
          final progress = exportedTask['progress'] as int;
          expect(progress, greaterThanOrEqualTo(0), 
                 reason: 'Progress should be >= 0');
          expect(progress, lessThanOrEqualTo(100), 
                 reason: 'Progress should be <= 100');
          
          // Verify period value
          final period = exportedTask['period'] as String;
          expect(['UTS', 'UAS'].contains(period), isTrue,
                 reason: 'Period should be UTS or UAS');
        }
      }
    });
    
    test('**Feature: academic-task-manager, Property 17: Import validation** - For any JSON import attempt, invalid JSON format should be rejected before processing, while valid JSON should be accepted', () async {
      final random = Random();
      
      // Run property test with multiple iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Test invalid JSON formats
        final invalidJsonCases = [
          // Invalid JSON syntax
          '{"invalid": json}',
          '{missing_quotes: "value"}',
          '{"unclosed": "string}',
          
          // Missing required top-level fields
          '{"version": "1.0"}', // missing tasks
          '{"tasks": []}', // missing version
          '{}', // missing both
          
          // Wrong field types
          '{"version": 123, "tasks": []}', // version should be string
          '{"version": "1.0", "tasks": "not_array"}', // tasks should be array
          
          // Invalid task structure
          '{"version": "1.0", "tasks": [{"name": "test"}]}', // missing required fields
          '{"version": "1.0", "tasks": [{"name": 123, "course_name": "test", "instructor_name": "test", "deadline": "2024-12-31T23:59:59.000", "semester": "S1", "period": "UTS", "progress": 50, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}]}', // name should be string
          
          // Invalid date formats
          '{"version": "1.0", "tasks": [{"name": "test", "course_name": "test", "instructor_name": "test", "deadline": "invalid-date", "semester": "S1", "period": "UTS", "progress": 50, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}]}',
          
          // Invalid progress values
          '{"version": "1.0", "tasks": [{"name": "test", "course_name": "test", "instructor_name": "test", "deadline": "2024-12-31T23:59:59.000", "semester": "S1", "period": "UTS", "progress": -1, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}]}',
          '{"version": "1.0", "tasks": [{"name": "test", "course_name": "test", "instructor_name": "test", "deadline": "2024-12-31T23:59:59.000", "semester": "S1", "period": "UTS", "progress": 101, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}]}',
          
          // Invalid period values
          '{"version": "1.0", "tasks": [{"name": "test", "course_name": "test", "instructor_name": "test", "deadline": "2024-12-31T23:59:59.000", "semester": "S1", "period": "INVALID", "progress": 50, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}]}',
        ];
        
        // Test each invalid case
        for (final invalidJson in invalidJsonCases) {
          expect(backupService.validateJsonFormat(invalidJson), isFalse,
                 reason: 'Should reject invalid JSON: $invalidJson');
        }
        
        // Test valid JSON formats
        final validJsonCases = [
          // Empty tasks list
          '{"version": "1.0", "tasks": []}',
          
          // Single valid task
          '{"version": "1.0", "tasks": [{"name": "Test Task", "course_name": "Test Course", "instructor_name": "Test Instructor", "deadline": "2024-12-31T23:59:59.000", "semester": "Semester 1", "period": "UTS", "progress": 50, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}]}',
          
          // Multiple valid tasks
          '{"version": "1.0", "tasks": [{"name": "Task 1", "course_name": "Course 1", "instructor_name": "Instructor 1", "deadline": "2024-12-31T23:59:59.000", "semester": "Semester 1", "period": "UTS", "progress": 0, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}, {"name": "Task 2", "course_name": "Course 2", "instructor_name": "Instructor 2", "deadline": "2024-12-31T23:59:59.000", "semester": "Semester 2", "period": "UAS", "progress": 100, "created_at": "2024-01-01T00:00:00.000", "updated_at": "2024-01-01T00:00:00.000"}]}',
          
          // With optional exported_at field
          '{"version": "1.0", "exported_at": "2024-01-01T00:00:00.000", "tasks": []}',
        ];
        
        // Test each valid case
        for (final validJson in validJsonCases) {
          expect(backupService.validateJsonFormat(validJson), isTrue,
                 reason: 'Should accept valid JSON: $validJson');
        }
        
        // Generate random valid JSON and test
        final randomTask = _generateRandomTask(random);
        final validRandomJson = jsonEncode({
          'version': '1.0',
          'exported_at': DateTime.now().toIso8601String(),
          'tasks': [randomTask.toJson()],
        });
        
        expect(backupService.validateJsonFormat(validRandomJson), isTrue,
               reason: 'Should accept randomly generated valid JSON');
      }
    });
    
    test('**Feature: academic-task-manager, Property 18: Import deduplication** - For any valid data import, existing tasks should not be duplicated when merging with imported data', () async {
      final random = Random();
      
      // Run property test with multiple iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Clear database for each iteration
        await taskRepository.clear();
        
        // Generate random number of initial tasks (1-5)
        final initialTaskCount = random.nextInt(5) + 1;
        final initialTasks = <Task>[];
        
        for (int i = 0; i < initialTaskCount; i++) {
          final task = _generateRandomTask(random);
          await taskRepository.insert(task);
          initialTasks.add(task);
        }
        
        // Get initial task count
        final initialCount = await taskRepository.count();
        expect(initialCount, equals(initialTaskCount));
        
        // Create import data with some duplicate tasks and some new tasks
        final duplicateTasks = <Task>[];
        final newTasks = <Task>[];
        
        // Add some existing tasks as duplicates (same key fields)
        final duplicateCount = random.nextInt(initialTaskCount) + 1;
        for (int i = 0; i < duplicateCount; i++) {
          final originalTask = initialTasks[i];
          // Create duplicate with same key fields but different progress/timestamps
          final duplicateTask = Task(
            name: originalTask.name,
            courseName: originalTask.courseName,
            instructorName: originalTask.instructorName,
            deadline: originalTask.deadline,
            semester: originalTask.semester,
            period: originalTask.period,
            progress: random.nextInt(101), // Different progress
            createdAt: originalTask.createdAt,
            updatedAt: DateTime.now(), // Different update time
          );
          duplicateTasks.add(duplicateTask);
        }
        
        // Add some completely new tasks
        final newTaskCount = random.nextInt(3) + 1;
        for (int i = 0; i < newTaskCount; i++) {
          final newTask = _generateRandomTask(random);
          newTasks.add(newTask);
        }
        
        // Combine duplicates and new tasks for import
        final tasksToImport = [...duplicateTasks, ...newTasks];
        
        // Create import JSON
        final importData = {
          'version': '1.0',
          'exported_at': DateTime.now().toIso8601String(),
          'tasks': tasksToImport.map((task) => task.toJson()).toList(),
        };
        final importJson = jsonEncode(importData);
        
        // Import tasks
        final importedCount = await backupService.importFromJson(importJson);
        
        // Verify only new tasks were imported (duplicates should be skipped)
        expect(importedCount, equals(newTaskCount),
               reason: 'Should only import new tasks, not duplicates');
        
        // Verify total task count
        final finalCount = await taskRepository.count();
        expect(finalCount, equals(initialTaskCount + newTaskCount),
               reason: 'Final count should be initial + new tasks only');
        
        // Verify no actual duplicates exist in database
        final allTasks = await taskRepository.findAll();
        final taskKeys = <String>{};
        
        for (final task in allTasks) {
          final key = '${task.name}|${task.courseName}|${task.instructorName}|'
                     '${task.deadline.toIso8601String()}|${task.semester}|${task.period}';
          
          expect(taskKeys.contains(key), isFalse,
                 reason: 'Should not have duplicate task keys in database');
          taskKeys.add(key);
        }
        
        // Test importing the same data again (should import 0 tasks)
        final secondImportCount = await backupService.importFromJson(importJson);
        expect(secondImportCount, equals(0),
               reason: 'Second import of same data should import 0 tasks');
        
        final finalCountAfterSecondImport = await taskRepository.count();
        expect(finalCountAfterSecondImport, equals(finalCount),
               reason: 'Task count should not change after second import');
      }
    });
  });
}

/// Generate a random task for property testing
Task _generateRandomTask(Random random) {
  final names = ['Tugas 1', 'Laporan', 'Presentasi', 'Quiz', 'Ujian'];
  final courses = ['Matematika', 'Fisika', 'Kimia', 'Biologi', 'Sejarah'];
  final instructors = ['Dr. Ahmad', 'Prof. Siti', 'Ir. Budi', 'Dra. Ani', 'M.Sc. Eko'];
  final semesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4'];
  final periods = ['UTS', 'UAS'];
  
  final now = DateTime.now();
  final futureDate = now.add(Duration(days: random.nextInt(365) + 1));
  
  return Task(
    name: names[random.nextInt(names.length)],
    courseName: courses[random.nextInt(courses.length)],
    instructorName: instructors[random.nextInt(instructors.length)],
    deadline: futureDate,
    semester: semesters[random.nextInt(semesters.length)],
    period: periods[random.nextInt(periods.length)],
    progress: random.nextInt(101), // 0-100
    createdAt: now.subtract(Duration(days: random.nextInt(30))),
    updatedAt: now.subtract(Duration(days: random.nextInt(7))),
  );
}