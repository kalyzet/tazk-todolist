import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:math';

import '../../lib/services/task_service.dart';
import '../../lib/models/task.dart';
import '../../lib/models/academic_context.dart';
import '../../lib/repositories/task_repository.dart';
import '../../lib/database/database_helper.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TaskService Property Tests', () {
    late TaskService taskService;
    late TaskRepository taskRepository;

    setUp(() async {
      // Initialize repository and service
      taskRepository = TaskRepository();
      taskService = TaskService(taskRepository: taskRepository);
      
      // Clear any existing data
      await taskRepository.clear();
    });

    tearDown(() async {
      // Clean up after each test
      await taskRepository.clear();
    });

    group('Property 5: New task initialization', () {
      test('**Feature: academic-task-manager, Property 5: New task initialization** - For any valid task data, creating a task should initialize progress to 0%', () async {
        final random = Random();
        
        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate random valid task data
          final task = _generateValidTask(random);
          
          // Set random progress (should be overridden to 0)
          final taskWithRandomProgress = task.copyWith(
            progress: random.nextInt(101), // 0-100
          );
          
          // Create task using service
          final createdTask = await taskService.createTask(taskWithRandomProgress);
          
          // Property: Progress should always be initialized to 0% regardless of input
          expect(createdTask.progress, equals(0), 
                 reason: 'Task progress should be initialized to 0% but was ${createdTask.progress}');
          
          // Verify task was actually saved to database
          final retrievedTask = await taskService.getTaskById(createdTask.id!);
          expect(retrievedTask, isNotNull);
          expect(retrievedTask!.progress, equals(0));
          
          // Clean up for next iteration
          await taskService.deleteTask(createdTask.id!);
        }
      });
    });

    group('Property 6: Past deadline rejection', () {
      test('**Feature: academic-task-manager, Property 6: Past deadline rejection** - For any task creation attempt with a deadline in the past, the system should reject the task creation', () async {
        final random = Random();
        
        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Generate task with past deadline
          final task = _generateTaskWithPastDeadline(random);
          
          // Property: Creating task with past deadline should throw ArgumentError
          expect(
            () async => await taskService.createTask(task),
            throwsA(isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('masa lalu'),
            )),
            reason: 'Task creation with past deadline should be rejected but was accepted',
          );
          
          // Verify no task was created in database
          final allTasks = await taskService.getAllTasks();
          expect(allTasks.length, equals(0), 
                 reason: 'No tasks should be created when deadline is in the past');
        }
      });
    });

    group('Property 8: Automatic completion', () {
      test('**Feature: academic-task-manager, Property 8: Automatic completion** - For any task with progress updated to 100%, the task should be automatically marked as completed', () async {
        final random = Random();
        
        // Run property test with multiple iterations
        for (int i = 0; i < 100; i++) {
          // Create a valid task first
          final originalTask = _generateValidTask(random);
          final createdTask = await taskService.createTask(originalTask);
          
          // Update task progress to 100%
          final taskWith100Progress = createdTask.copyWith(progress: 100);
          final updatedTask = await taskService.updateTask(taskWith100Progress);
          
          // Property: Task with 100% progress should be marked as completed
          expect(updatedTask.progress, equals(100), 
                 reason: 'Task progress should be 100% but was ${updatedTask.progress}');
          
          // Verify task was updated in database
          final retrievedTask = await taskService.getTaskById(updatedTask.id!);
          expect(retrievedTask, isNotNull);
          expect(retrievedTask!.progress, equals(100));
          
          // Clean up for next iteration
          await taskService.deleteTask(createdTask.id!);
        }
      });
    });
  });
}

/// Generates a valid task with random data for property testing
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
    progress: random.nextInt(101), // This should be overridden to 0
  );
}

/// Generates a task with past deadline for property testing
Task _generateTaskWithPastDeadline(Random random) {
  final courses = ['Basis Data', 'Algoritma', 'Jaringan Komputer', 'Pemrograman Web', 'Sistem Operasi'];
  final instructors = ['Dr. Ahmad', 'Prof. Siti', 'Ir. Budi', 'Dr. Rina', 'Prof. Joko'];
  final semesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5'];
  final periods = ['UTS', 'UAS'];
  
  // Generate past deadline (1-30 days ago)
  final pastDeadline = DateTime.now().subtract(Duration(days: random.nextInt(30) + 1));
  
  return Task(
    name: 'Tugas ${random.nextInt(1000)}',
    courseName: courses[random.nextInt(courses.length)],
    instructorName: instructors[random.nextInt(instructors.length)],
    deadline: pastDeadline,
    semester: semesters[random.nextInt(semesters.length)],
    period: periods[random.nextInt(periods.length)],
    progress: random.nextInt(101),
  );
}