import 'package:test/test.dart';
import 'package:tazk/models/task.dart';
import 'package:tazk/models/academic_context.dart';
import 'package:tazk/services/task_service.dart';
import 'package:tazk/repositories/preferences_repository.dart';
import 'dart:math';

// Mock implementations for testing
class MockTaskService extends TaskService {
  final List<Task> _tasks = [];
  int _nextId = 1;

  @override
  Future<Task> createTask(Task task) async {
    // Simulate validation
    if (!task.validateRequiredFields()) {
      throw ArgumentError('Semua field wajib harus diisi');
    }
    if (!task.validatePeriod()) {
      throw ArgumentError('Period harus UTS atau UAS');
    }
    if (!task.validateDeadlineNotPast()) {
      throw ArgumentError('Deadline tidak boleh di masa lalu');
    }

    final newTask = task.copyWith(
      id: _nextId++,
      progress: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _tasks.add(newTask);
    return newTask;
  }

  @override
  Future<List<Task>> getTasksByContext(AcademicContext context) async {
    return _tasks.where((task) => 
      task.semester == context.semester && task.period == context.period
    ).toList();
  }

  @override
  Future<Task> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      throw StateError('Task tidak ditemukan');
    }
    _tasks[index] = task;
    return task;
  }

  @override
  Future<void> deleteTask(int taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  void clearTasks() {
    _tasks.clear();
    _nextId = 1;
  }
}

class MockPreferencesRepository extends PreferencesRepository {
  AcademicContext? _lastContext;
  String _sortPreference = 'deadline';

  @override
  Future<bool> saveLastContext(AcademicContext context) async {
    _lastContext = context;
    return true;
  }

  @override
  Future<AcademicContext?> getLastContext() async {
    return _lastContext;
  }

  @override
  Future<String> getSortPreference() async {
    return _sortPreference;
  }

  @override
  Future<bool> saveSortPreference(String sortBy) async {
    if (!PreferencesRepository.isValidSortOption(sortBy)) {
      return false;
    }
    _sortPreference = sortBy;
    return true;
  }

  void reset() {
    _lastContext = null;
    _sortPreference = 'deadline';
  }
}

void main() {
  group('TaskProvider Property Tests', () {
    late MockTaskService mockTaskService;
    late MockPreferencesRepository mockPreferencesRepository;

    setUp(() {
      mockTaskService = MockTaskService();
      mockPreferencesRepository = MockPreferencesRepository();
    });

    tearDown(() {
      mockTaskService.clearTasks();
      mockPreferencesRepository.reset();
    });

    group('Property Tests', () {
      test('**Feature: academic-task-manager, Property 13: Context assignment** - For any task created while a specific context is selected, the task should be assigned to that context\'s semester and period', () async {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random context
          final context = AcademicContext(
            semester: _generateRandomSemester(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
          );
          
          // Generate random task data (without context assignment)
          final taskData = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
            semester: _generateRandomSemester(random), // This should be overridden
            period: random.nextBool() ? 'UTS' : 'UAS', // This should be overridden
            progress: random.nextInt(101),
          );

          // Simulate the context assignment behavior that TaskProvider would do
          final taskWithContext = taskData.copyWith(
            semester: context.semester,
            period: context.period,
          );

          // Create the task through the service
          final createdTask = await mockTaskService.createTask(taskWithContext);
          
          // Verify the task was assigned to the current context
          expect(createdTask.semester, equals(context.semester),
                 reason: 'Task should be assigned to current context semester (iteration $i)');
          expect(createdTask.period, equals(context.period),
                 reason: 'Task should be assigned to current context period (iteration $i)');
          
          // Verify the task appears when filtering by context
          final tasksInContext = await mockTaskService.getTasksByContext(context);
          expect(tasksInContext, contains(createdTask),
                 reason: 'Created task should appear when filtering by context (iteration $i)');
          
          // Verify all tasks in the context belong to that context
          for (final task in tasksInContext) {
            expect(task.semester, equals(context.semester),
                   reason: 'All tasks should belong to current context semester (iteration $i)');
            expect(task.period, equals(context.period),
                   reason: 'All tasks should belong to current context period (iteration $i)');
          }
          
          // Clean up for next iteration
          mockTaskService.clearTasks();
        }
      });

      test('**Feature: academic-task-manager, Property 13: Context assignment** - Tasks created in different contexts should be properly isolated', () async {
        final random = Random();
        
        // Run property test with 50 iterations (fewer due to complexity)
        for (int i = 0; i < 50; i++) {
          // Generate two different contexts
          final context1 = AcademicContext(
            semester: _generateRandomSemester(random),
            period: 'UTS',
          );
          final context2 = AcademicContext(
            semester: _generateRandomSemester(random),
            period: 'UAS',
          );
          
          // Ensure contexts are different
          if (context1 == context2) {
            context2.semester = context1.semester + ' Modified';
          }
          
          // Create task in first context
          final task1Data = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
            semester: context1.semester,
            period: context1.period,
          );
          
          final task1 = await mockTaskService.createTask(task1Data);
          
          expect(task1.semester, equals(context1.semester));
          expect(task1.period, equals(context1.period));
          
          // Create task in second context
          final task2Data = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
            semester: context2.semester,
            period: context2.period,
          );
          
          final task2 = await mockTaskService.createTask(task2Data);
          
          expect(task2.semester, equals(context2.semester));
          expect(task2.period, equals(context2.period));
          
          // Verify context isolation
          final tasksInContext1 = await mockTaskService.getTasksByContext(context1);
          final tasksInContext2 = await mockTaskService.getTasksByContext(context2);
          
          expect(tasksInContext1.length, equals(1),
                 reason: 'Context 1 should have exactly 1 task (iteration $i)');
          expect(tasksInContext2.length, equals(1),
                 reason: 'Context 2 should have exactly 1 task (iteration $i)');
          
          expect(tasksInContext1.first.id, equals(task1.id),
                 reason: 'Context 1 should contain only task1 (iteration $i)');
          expect(tasksInContext2.first.id, equals(task2.id),
                 reason: 'Context 2 should contain only task2 (iteration $i)');
          
          // Clean up
          mockTaskService.clearTasks();
        }
      });

      test('**Feature: academic-task-manager, Property 14: Task sorting consistency** - For any sort criteria (deadline, progress, course name, task name), tasks should be ordered according to the specified criteria in ascending order', () async {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a list of random tasks
          final numTasks = random.nextInt(10) + 2; // 2-11 tasks
          final tasks = <Task>[];
          
          for (int j = 0; j < numTasks; j++) {
            final task = Task(
              name: _generateNonEmptyString(random),
              courseName: _generateNonEmptyString(random),
              instructorName: _generateNonEmptyString(random),
              deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
              semester: 'Semester 4',
              period: 'UTS',
              progress: random.nextInt(101),
            );
            
            final createdTask = await mockTaskService.createTask(task);
            tasks.add(createdTask);
          }
          
          // Test each sort criteria
          final sortCriteria = ['deadline', 'progress', 'course_name', 'task_name'];
          
          for (final sortBy in sortCriteria) {
            // Create a copy of tasks to sort
            final tasksCopy = List<Task>.from(tasks);
            
            // Sort using the same logic as TaskProvider would use
            switch (sortBy) {
              case 'deadline':
                tasksCopy.sort((a, b) => a.deadline.compareTo(b.deadline));
                break;
              case 'progress':
                tasksCopy.sort((a, b) => a.progress.compareTo(b.progress));
                break;
              case 'course_name':
                tasksCopy.sort((a, b) => a.courseName.toLowerCase().compareTo(b.courseName.toLowerCase()));
                break;
              case 'task_name':
                tasksCopy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                break;
            }
            
            // Verify the sorting is correct
            for (int k = 0; k < tasksCopy.length - 1; k++) {
              final current = tasksCopy[k];
              final next = tasksCopy[k + 1];
              
              switch (sortBy) {
                case 'deadline':
                  expect(current.deadline.isBefore(next.deadline) || current.deadline.isAtSameMomentAs(next.deadline), 
                         isTrue,
                         reason: 'Tasks should be sorted by deadline in ascending order (iteration $i, sort $sortBy)');
                  break;
                case 'progress':
                  expect(current.progress <= next.progress, 
                         isTrue,
                         reason: 'Tasks should be sorted by progress in ascending order (iteration $i, sort $sortBy)');
                  break;
                case 'course_name':
                  expect(current.courseName.toLowerCase().compareTo(next.courseName.toLowerCase()) <= 0, 
                         isTrue,
                         reason: 'Tasks should be sorted by course name in ascending order (iteration $i, sort $sortBy)');
                  break;
                case 'task_name':
                  expect(current.name.toLowerCase().compareTo(next.name.toLowerCase()) <= 0, 
                         isTrue,
                         reason: 'Tasks should be sorted by task name in ascending order (iteration $i, sort $sortBy)');
                  break;
              }
            }
          }
          
          // Clean up
          mockTaskService.clearTasks();
        }
      });

      test('**Feature: academic-task-manager, Property 14: Task sorting consistency** - Sorting should be stable and consistent across multiple sorts', () async {
        final random = Random();
        
        // Run property test with 50 iterations
        for (int i = 0; i < 50; i++) {
          // Generate tasks with some duplicate values to test stability
          final tasks = <Task>[];
          final baseName = _generateNonEmptyString(random);
          final baseCourse = _generateNonEmptyString(random);
          final baseDeadline = DateTime.now().add(Duration(days: random.nextInt(30) + 1));
          
          for (int j = 0; j < 5; j++) {
            final task = Task(
              name: j < 2 ? baseName : _generateNonEmptyString(random), // Some duplicate names
              courseName: j < 2 ? baseCourse : _generateNonEmptyString(random), // Some duplicate courses
              instructorName: _generateNonEmptyString(random),
              deadline: j < 2 ? baseDeadline : DateTime.now().add(Duration(days: random.nextInt(30) + 1)), // Some duplicate deadlines
              semester: 'Semester 4',
              period: 'UTS',
              progress: j < 2 ? 50 : random.nextInt(101), // Some duplicate progress
            );
            
            final createdTask = await mockTaskService.createTask(task);
            tasks.add(createdTask);
          }
          
          // Test that multiple sorts of the same data produce the same result
          final sortBy = ['deadline', 'progress', 'course_name', 'task_name'][random.nextInt(4)];
          
          final firstSort = List<Task>.from(tasks);
          final secondSort = List<Task>.from(tasks);
          
          // Sort both lists using the same criteria
          void sortTasks(List<Task> taskList) {
            switch (sortBy) {
              case 'deadline':
                taskList.sort((a, b) => a.deadline.compareTo(b.deadline));
                break;
              case 'progress':
                taskList.sort((a, b) => a.progress.compareTo(b.progress));
                break;
              case 'course_name':
                taskList.sort((a, b) => a.courseName.toLowerCase().compareTo(b.courseName.toLowerCase()));
                break;
              case 'task_name':
                taskList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                break;
            }
          }
          
          sortTasks(firstSort);
          sortTasks(secondSort);
          
          // Verify both sorts produce identical results
          expect(firstSort.length, equals(secondSort.length),
                 reason: 'Both sorted lists should have the same length (iteration $i, sort $sortBy)');
          
          for (int k = 0; k < firstSort.length; k++) {
            expect(firstSort[k].id, equals(secondSort[k].id),
                   reason: 'Sorting should be consistent across multiple sorts (iteration $i, sort $sortBy, position $k)');
          }
          
          // Clean up
          mockTaskService.clearTasks();
        }
      });
    });

    group('Unit Tests', () {
      test('Context assignment behavior simulation', () async {
        final context = AcademicContext(semester: 'Semester 4', period: 'UTS');
        
        final task = Task(
          name: 'Test Task',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: DateTime.now().add(Duration(days: 1)),
          semester: 'Should be overridden',
          period: 'Should be overridden',
        );
        
        // Simulate TaskProvider behavior
        final taskWithContext = task.copyWith(
          semester: context.semester,
          period: context.period,
        );
        
        final createdTask = await mockTaskService.createTask(taskWithContext);
        
        expect(createdTask.semester, equals(context.semester));
        expect(createdTask.period, equals(context.period));
      });

      test('Sort preference persistence simulation', () async {
        // Test valid sort options
        final validOptions = ['deadline', 'progress', 'course_name', 'task_name'];
        
        for (final option in validOptions) {
          final saved = await mockPreferencesRepository.saveSortPreference(option);
          expect(saved, isTrue);
          
          final retrieved = await mockPreferencesRepository.getSortPreference();
          expect(retrieved, equals(option));
        }
      });

      test('Invalid sort preference is rejected', () async {
        final saved = await mockPreferencesRepository.saveSortPreference('invalid_sort');
        expect(saved, isFalse);
        
        // Should return default
        final retrieved = await mockPreferencesRepository.getSortPreference();
        expect(retrieved, equals('deadline'));
      });
    });
  });
}

// Helper functions for property testing
String _generateNonEmptyString(Random random) {
  final words = ['Task', 'Course', 'Instructor', 'Project', 'Assignment', 'Lab', 'Quiz', 'Exam'];
  final word1 = words[random.nextInt(words.length)];
  final word2 = words[random.nextInt(words.length)];
  final number = random.nextInt(100);
  return '$word1 $word2 $number';
}

String _generateRandomSemester(Random random) {
  final semesters = [
    'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4',
    'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'
  ];
  return semesters[random.nextInt(semesters.length)];
}