import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/repositories/task_repository.dart';
import '../../lib/models/task.dart';
import '../../lib/models/academic_context.dart';
import '../../lib/database/database_helper.dart';
import 'dart:math';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TaskRepository Property Tests', () {
    late TaskRepository repository;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      // Use unique database name for each test to avoid locking
      final testDbName = 'test_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.db';
      DatabaseHelper.setTestDatabaseName(testDbName);
      
      repository = TaskRepository();
      databaseHelper = DatabaseHelper();
      
      // Clear database before each test
      await repository.clear();
    });

    tearDown(() async {
      await databaseHelper.close();
      await databaseHelper.deleteDatabase();
      DatabaseHelper.setTestDatabaseName(null);
    });

    /// **Feature: academic-task-manager, Property 3: Context-based task filtering**
    /// **Validates: Requirements 2.2, 6.1, 6.2, 6.3**
    test('Property 3: Context-based task filtering', () async {
      final random = Random();
      
      // Run property test with 100 iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Clear database for each iteration
        await repository.clear();
        
        // Generate random academic contexts
        final contexts = _generateRandomContexts(random, 3 + random.nextInt(3)); // 3-5 contexts
        final targetContext = contexts[random.nextInt(contexts.length)];
        
        // Generate random tasks for different contexts
        final allTasks = <Task>[];
        final expectedTasksForTarget = <Task>[];
        
        for (final context in contexts) {
          final tasksForContext = _generateRandomTasksForContext(
            random, 
            context, 
            2 + random.nextInt(4) // 2-5 tasks per context
          );
          
          allTasks.addAll(tasksForContext);
          
          if (context.semester == targetContext.semester && 
              context.period == targetContext.period) {
            expectedTasksForTarget.addAll(tasksForContext);
          }
        }
        
        // Insert all tasks into database
        for (final task in allTasks) {
          await repository.insert(task);
        }
        
        // Test the property: filtering by context should return only matching tasks
        final filteredTasks = await repository.findByContext(
          targetContext.semester, 
          targetContext.period
        );
        
        // Verify all returned tasks match the target context
        for (final task in filteredTasks) {
          expect(task.semester, equals(targetContext.semester),
              reason: 'Task semester should match target context semester');
          expect(task.period, equals(targetContext.period),
              reason: 'Task period should match target context period');
        }
        
        // Verify we got all tasks for the target context
        expect(filteredTasks.length, equals(expectedTasksForTarget.length),
            reason: 'Should return all tasks matching the context');
        
        // Verify tasks are ordered by deadline (ISO-8601 format ensures proper sorting)
        for (int i = 1; i < filteredTasks.length; i++) {
          expect(
            filteredTasks[i-1].deadline.isBefore(filteredTasks[i].deadline) ||
            filteredTasks[i-1].deadline.isAtSameMomentAs(filteredTasks[i].deadline),
            isTrue,
            reason: 'Tasks should be ordered by deadline ascending'
          );
        }
      }
    });

    /// **Feature: academic-task-manager, Property 25: Data integrity maintenance**
    /// **Validates: Requirements 10.5**
    test('Property 25: Data integrity maintenance', () async {
      final random = Random();
      
      // Run property test with 100 iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Clear database for each iteration
        await repository.clear();
        
        // Generate random sequence of CRUD operations
        final operations = _generateRandomCrudOperations(random, 10 + random.nextInt(20)); // 10-30 operations
        final expectedTasks = <int, Task>{}; // Track expected state by ID
        var nextId = 1;
        
        for (final operation in operations) {
          switch (operation.type) {
            case CrudOperationType.create:
              final task = _generateRandomTask(random);
              final insertedId = await repository.insert(task);
              expectedTasks[insertedId] = task.copyWith(id: insertedId);
              nextId = insertedId + 1;
              break;
              
            case CrudOperationType.update:
              if (expectedTasks.isNotEmpty) {
                final taskId = expectedTasks.keys.elementAt(random.nextInt(expectedTasks.length));
                final existingTask = expectedTasks[taskId]!;
                final updatedTask = _generateRandomTaskUpdate(random, existingTask);
                
                await repository.update(updatedTask);
                expectedTasks[taskId] = updatedTask;
              }
              break;
              
            case CrudOperationType.delete:
              if (expectedTasks.isNotEmpty) {
                final taskId = expectedTasks.keys.elementAt(random.nextInt(expectedTasks.length));
                await repository.delete(taskId);
                expectedTasks.remove(taskId);
              }
              break;
          }
        }
        
        // Verify data integrity: all expected tasks should exist and match
        final allTasks = await repository.findAll();
        
        // Check count matches
        expect(allTasks.length, equals(expectedTasks.length),
            reason: 'Database should contain exactly the expected number of tasks');
        
        // Check each task exists and has correct data
        for (final expectedTask in expectedTasks.values) {
          final foundTask = allTasks.firstWhere(
            (task) => task.id == expectedTask.id,
            orElse: () => throw StateError('Expected task with ID ${expectedTask.id} not found'),
          );
          
          // Verify all fields match (excluding updatedAt which may differ slightly)
          expect(foundTask.name, equals(expectedTask.name));
          expect(foundTask.courseName, equals(expectedTask.courseName));
          expect(foundTask.instructorName, equals(expectedTask.instructorName));
          expect(foundTask.deadline, equals(expectedTask.deadline));
          expect(foundTask.semester, equals(expectedTask.semester));
          expect(foundTask.period, equals(expectedTask.period));
          expect(foundTask.progress, equals(expectedTask.progress));
          expect(foundTask.createdAt, equals(expectedTask.createdAt));
        }
        
        // Verify no extra tasks exist
        for (final actualTask in allTasks) {
          expect(expectedTasks.containsKey(actualTask.id), isTrue,
              reason: 'Database should not contain unexpected tasks');
        }
        
        // Verify database constraints are maintained
        for (final task in allTasks) {
          expect(task.progress >= 0 && task.progress <= 100, isTrue,
              reason: 'Progress should be within 0-100 range');
          expect(task.period == 'UTS' || task.period == 'UAS', isTrue,
              reason: 'Period should be either UTS or UAS');
          expect(task.name.isNotEmpty, isTrue,
              reason: 'Task name should not be empty');
          expect(task.courseName.isNotEmpty, isTrue,
              reason: 'Course name should not be empty');
          expect(task.instructorName.isNotEmpty, isTrue,
              reason: 'Instructor name should not be empty');
          expect(task.semester.isNotEmpty, isTrue,
              reason: 'Semester should not be empty');
        }
      }
    });
  });
}

/// Generate random academic contexts
List<AcademicContext> _generateRandomContexts(Random random, int count) {
  final semesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6'];
  final periods = ['UTS', 'UAS'];
  final contexts = <AcademicContext>[];
  
  for (int i = 0; i < count; i++) {
    contexts.add(AcademicContext(
      semester: semesters[random.nextInt(semesters.length)],
      period: periods[random.nextInt(periods.length)],
    ));
  }
  
  return contexts;
}

/// Generate random tasks for a specific context
List<Task> _generateRandomTasksForContext(Random random, AcademicContext context, int count) {
  final taskNames = ['Tugas 1', 'Laporan Praktikum', 'Essay', 'Presentasi', 'Proyek Akhir'];
  final courseNames = ['Matematika', 'Fisika', 'Kimia', 'Biologi', 'Bahasa Indonesia'];
  final instructorNames = ['Dr. Ahmad', 'Prof. Siti', 'Ir. Budi', 'Dra. Ani', 'M.Sc. Dedi'];
  
  final tasks = <Task>[];
  final now = DateTime.now();
  
  for (int i = 0; i < count; i++) {
    final deadline = now.add(Duration(days: 1 + random.nextInt(30))); // 1-30 days from now
    
    tasks.add(Task(
      name: '${taskNames[random.nextInt(taskNames.length)]} ${i + 1}',
      courseName: courseNames[random.nextInt(courseNames.length)],
      instructorName: instructorNames[random.nextInt(instructorNames.length)],
      deadline: deadline,
      semester: context.semester,
      period: context.period,
      progress: random.nextInt(101), // 0-100
    ));
  }
  
  return tasks;
}

/// Generate a single random task
Task _generateRandomTask(Random random) {
  final taskNames = ['Tugas 1', 'Laporan Praktikum', 'Essay', 'Presentasi', 'Proyek Akhir'];
  final courseNames = ['Matematika', 'Fisika', 'Kimia', 'Biologi', 'Bahasa Indonesia'];
  final instructorNames = ['Dr. Ahmad', 'Prof. Siti', 'Ir. Budi', 'Dra. Ani', 'M.Sc. Dedi'];
  final semesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6'];
  final periods = ['UTS', 'UAS'];
  
  final now = DateTime.now();
  final deadline = now.add(Duration(days: 1 + random.nextInt(30))); // 1-30 days from now
  
  return Task(
    name: '${taskNames[random.nextInt(taskNames.length)]} ${random.nextInt(100)}',
    courseName: courseNames[random.nextInt(courseNames.length)],
    instructorName: instructorNames[random.nextInt(instructorNames.length)],
    deadline: deadline,
    semester: semesters[random.nextInt(semesters.length)],
    period: periods[random.nextInt(periods.length)],
    progress: random.nextInt(101), // 0-100
  );
}

/// Generate a random update for an existing task
Task _generateRandomTaskUpdate(Random random, Task existingTask) {
  final taskNames = ['Tugas 1', 'Laporan Praktikum', 'Essay', 'Presentasi', 'Proyek Akhir'];
  final courseNames = ['Matematika', 'Fisika', 'Kimia', 'Biologi', 'Bahasa Indonesia'];
  final instructorNames = ['Dr. Ahmad', 'Prof. Siti', 'Ir. Budi', 'Dra. Ani', 'M.Sc. Dedi'];
  
  // Randomly choose which fields to update
  final updateName = random.nextBool();
  final updateCourse = random.nextBool();
  final updateInstructor = random.nextBool();
  final updateProgress = random.nextBool();
  final updateDeadline = random.nextBool();
  
  final now = DateTime.now();
  
  return existingTask.copyWith(
    name: updateName ? '${taskNames[random.nextInt(taskNames.length)]} Updated' : null,
    courseName: updateCourse ? courseNames[random.nextInt(courseNames.length)] : null,
    instructorName: updateInstructor ? instructorNames[random.nextInt(instructorNames.length)] : null,
    progress: updateProgress ? random.nextInt(101) : null,
    deadline: updateDeadline ? now.add(Duration(days: 1 + random.nextInt(30))) : null,
  );
}

/// CRUD operation types for data integrity testing
enum CrudOperationType { create, update, delete }

/// CRUD operation for data integrity testing
class CrudOperation {
  final CrudOperationType type;
  
  CrudOperation(this.type);
}

/// Generate random sequence of CRUD operations
List<CrudOperation> _generateRandomCrudOperations(Random random, int count) {
  final operations = <CrudOperation>[];
  
  for (int i = 0; i < count; i++) {
    // Bias towards create operations early to have data to work with
    final operationTypes = [
      CrudOperationType.create,
      CrudOperationType.create, // Double weight for create
      CrudOperationType.update,
      CrudOperationType.delete,
    ];
    
    final operationType = operationTypes[random.nextInt(operationTypes.length)];
    operations.add(CrudOperation(operationType));
  }
  
  return operations;
}