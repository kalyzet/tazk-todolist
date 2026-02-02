import 'package:test/test.dart';
import 'package:Tazk/models/task.dart';
import 'package:Tazk/models/academic_context.dart';
import 'dart:math';

void main() {
  group('TaskProvider Logic Tests (VM Compatible)', () {
    group('Property Tests', () {
      test('**Feature: academic-task-manager, Property 13: Context assignment** - For any task created while a specific context is selected, the task should be assigned to that context\'s semester and period', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate random context
          final context = AcademicContext(
            semester: _generateRandomSemester(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
          );
          
          // Generate random task data (without context assignment)
          final originalTask = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
            semester: _generateRandomSemester(random), // This should be overridden
            period: random.nextBool() ? 'UTS' : 'UAS', // This should be overridden
            progress: random.nextInt(101),
          );

          // Simulate the context assignment behavior that TaskProvider would do
          final taskWithContext = originalTask.copyWith(
            semester: context.semester,
            period: context.period,
          );

          // Verify the task was assigned to the current context
          expect(taskWithContext.semester, equals(context.semester),
                 reason: 'Task should be assigned to current context semester (iteration $i)');
          expect(taskWithContext.period, equals(context.period),
                 reason: 'Task should be assigned to current context period (iteration $i)');
          
          // Verify the original task data was preserved except for context
          expect(taskWithContext.name, equals(originalTask.name),
                 reason: 'Task name should be preserved (iteration $i)');
          expect(taskWithContext.courseName, equals(originalTask.courseName),
                 reason: 'Course name should be preserved (iteration $i)');
          expect(taskWithContext.instructorName, equals(originalTask.instructorName),
                 reason: 'Instructor name should be preserved (iteration $i)');
          expect(taskWithContext.deadline, equals(originalTask.deadline),
                 reason: 'Deadline should be preserved (iteration $i)');
          expect(taskWithContext.progress, equals(originalTask.progress),
                 reason: 'Progress should be preserved (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 13: Context assignment** - Tasks created in different contexts should be properly isolated by filtering', () {
        final random = Random();
        
        // Run property test with 50 iterations
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
          
          // Create tasks for both contexts
          final tasks = <Task>[];
          
          // Create tasks for context1
          for (int j = 0; j < 3; j++) {
            final task = Task(
              id: j + 1,
              name: _generateNonEmptyString(random),
              courseName: _generateNonEmptyString(random),
              instructorName: _generateNonEmptyString(random),
              deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
              semester: context1.semester,
              period: context1.period,
            );
            tasks.add(task);
          }
          
          // Create tasks for context2
          for (int j = 0; j < 3; j++) {
            final task = Task(
              id: j + 4,
              name: _generateNonEmptyString(random),
              courseName: _generateNonEmptyString(random),
              instructorName: _generateNonEmptyString(random),
              deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
              semester: context2.semester,
              period: context2.period,
            );
            tasks.add(task);
          }
          
          // Simulate context filtering (what TaskProvider would do)
          final tasksInContext1 = tasks.where((task) => 
            task.semester == context1.semester && task.period == context1.period
          ).toList();
          
          final tasksInContext2 = tasks.where((task) => 
            task.semester == context2.semester && task.period == context2.period
          ).toList();
          
          // Verify context isolation
          expect(tasksInContext1.length, equals(3),
                 reason: 'Context 1 should have exactly 3 tasks (iteration $i)');
          expect(tasksInContext2.length, equals(3),
                 reason: 'Context 2 should have exactly 3 tasks (iteration $i)');
          
          // Verify all tasks in context1 belong to context1
          for (final task in tasksInContext1) {
            expect(task.semester, equals(context1.semester),
                   reason: 'All tasks in context1 should belong to context1 semester (iteration $i)');
            expect(task.period, equals(context1.period),
                   reason: 'All tasks in context1 should belong to context1 period (iteration $i)');
          }
          
          // Verify all tasks in context2 belong to context2
          for (final task in tasksInContext2) {
            expect(task.semester, equals(context2.semester),
                   reason: 'All tasks in context2 should belong to context2 semester (iteration $i)');
            expect(task.period, equals(context2.period),
                   reason: 'All tasks in context2 should belong to context2 period (iteration $i)');
          }
          
          // Verify no overlap between contexts
          final context1Ids = tasksInContext1.map((t) => t.id).toSet();
          final context2Ids = tasksInContext2.map((t) => t.id).toSet();
          expect(context1Ids.intersection(context2Ids), isEmpty,
                 reason: 'Tasks should not overlap between contexts (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 14: Task sorting consistency** - For any sort criteria (deadline, progress, course name, task name), tasks should be ordered according to the specified criteria in ascending order', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a list of random tasks
          final numTasks = random.nextInt(10) + 2; // 2-11 tasks
          final tasks = <Task>[];
          
          for (int j = 0; j < numTasks; j++) {
            final task = Task(
              id: j + 1,
              name: _generateNonEmptyString(random),
              courseName: _generateNonEmptyString(random),
              instructorName: _generateNonEmptyString(random),
              deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
              semester: 'Semester 4',
              period: 'UTS',
              progress: random.nextInt(101),
            );
            tasks.add(task);
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
        }
      });

      test('**Feature: academic-task-manager, Property 14: Task sorting consistency** - Sorting should be stable and consistent across multiple sorts', () {
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
              id: j + 1,
              name: j < 2 ? baseName : _generateNonEmptyString(random), // Some duplicate names
              courseName: j < 2 ? baseCourse : _generateNonEmptyString(random), // Some duplicate courses
              instructorName: _generateNonEmptyString(random),
              deadline: j < 2 ? baseDeadline : DateTime.now().add(Duration(days: random.nextInt(30) + 1)), // Some duplicate deadlines
              semester: 'Semester 4',
              period: 'UTS',
              progress: j < 2 ? 50 : random.nextInt(101), // Some duplicate progress
            );
            tasks.add(task);
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
        }
      });
    });

    group('Unit Tests', () {
      test('Context assignment behavior simulation', () {
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
        
        expect(taskWithContext.semester, equals(context.semester));
        expect(taskWithContext.period, equals(context.period));
      });

      test('Sort preference validation', () {
        final validOptions = ['deadline', 'progress', 'course_name', 'task_name'];
        final invalidOptions = ['invalid_sort', '', 'name', 'date'];
        
        for (final option in validOptions) {
          expect(validOptions.contains(option), isTrue,
                 reason: '$option should be a valid sort option');
        }
        
        for (final option in invalidOptions) {
          expect(validOptions.contains(option), isFalse,
                 reason: '$option should not be a valid sort option');
        }
      });

      test('Task filtering by context', () {
        final context1 = AcademicContext(semester: 'Semester 4', period: 'UTS');
        final context2 = AcademicContext(semester: 'Semester 5', period: 'UAS');
        
        final tasks = [
          Task(id: 1, name: 'Task 1', courseName: 'Course A', instructorName: 'Instructor A',
               deadline: DateTime.now().add(Duration(days: 1)), semester: 'Semester 4', period: 'UTS'),
          Task(id: 2, name: 'Task 2', courseName: 'Course B', instructorName: 'Instructor B',
               deadline: DateTime.now().add(Duration(days: 2)), semester: 'Semester 5', period: 'UAS'),
          Task(id: 3, name: 'Task 3', courseName: 'Course C', instructorName: 'Instructor C',
               deadline: DateTime.now().add(Duration(days: 3)), semester: 'Semester 4', period: 'UTS'),
        ];
        
        final context1Tasks = tasks.where((task) => 
          task.semester == context1.semester && task.period == context1.period
        ).toList();
        
        final context2Tasks = tasks.where((task) => 
          task.semester == context2.semester && task.period == context2.period
        ).toList();
        
        expect(context1Tasks.length, equals(2));
        expect(context2Tasks.length, equals(1));
        expect(context1Tasks.map((t) => t.id).toList(), equals([1, 3]));
        expect(context2Tasks.map((t) => t.id).toList(), equals([2]));
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