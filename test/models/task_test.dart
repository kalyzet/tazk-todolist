import 'package:test/test.dart';
import 'package:tazk/models/task.dart';
import 'dart:math';

void main() {
  group('Task Model Tests', () {
    group('Property Tests', () {
      test('**Feature: academic-task-manager, Property 2: Empty input validation** - For any task creation or context selection attempt with empty required fields, the system should reject the input and maintain current state', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a task with at least one empty required field
          final emptyFieldIndex = random.nextInt(5); // 0-4 for the 5 required string fields
          
          String name = 'Valid Task Name';
          String courseName = 'Valid Course';
          String instructorName = 'Valid Instructor';
          String semester = 'Semester 4';
          String period = 'UTS';
          
          // Make one field empty based on the random index
          switch (emptyFieldIndex) {
            case 0:
              name = _generateEmptyString(random);
              break;
            case 1:
              courseName = _generateEmptyString(random);
              break;
            case 2:
              instructorName = _generateEmptyString(random);
              break;
            case 3:
              semester = _generateEmptyString(random);
              break;
            case 4:
              period = _generateEmptyString(random);
              break;
          }
          
          final task = Task(
            name: name,
            courseName: courseName,
            instructorName: instructorName,
            deadline: DateTime.now().add(Duration(days: random.nextInt(30) + 1)),
            semester: semester,
            period: period,
            progress: random.nextInt(101),
          );
          
          // The task should be invalid due to empty required field
          expect(task.validateRequiredFields(), isFalse, 
                 reason: 'Task with empty required field should be invalid (iteration $i)');
          expect(task.isValid(), isFalse,
                 reason: 'Task with empty required field should fail overall validation (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 2: Empty input validation** - Valid tasks with all required fields should pass validation', () {
        final random = Random();
        
        // Run property test with 100 iterations for valid tasks
        for (int i = 0; i < 100; i++) {
          final task = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(30) + 1)),
            semester: _generateNonEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
            progress: random.nextInt(101), // 0-100
          );
          
          // The task should pass required fields validation
          expect(task.validateRequiredFields(), isTrue,
                 reason: 'Task with all required fields should be valid (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 7: Progress range validation** - Progress values outside 0-100 range should be rejected', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate invalid progress values (outside 0-100 range)
          int invalidProgress;
          if (random.nextBool()) {
            // Generate negative progress
            invalidProgress = -random.nextInt(1000) - 1;
          } else {
            // Generate progress > 100
            invalidProgress = random.nextInt(1000) + 101;
          }
          
          final task = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(30) + 1)),
            semester: _generateNonEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
            progress: invalidProgress,
          );
          
          // The task should fail progress validation
          expect(task.validateProgressRange(), isFalse,
                 reason: 'Task with progress $invalidProgress should fail validation (iteration $i)');
          expect(task.isValid(), isFalse,
                 reason: 'Task with invalid progress should fail overall validation (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 7: Progress range validation** - Progress values within 0-100 range should be accepted', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          final validProgress = random.nextInt(101); // 0-100
          
          final task = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(30) + 1)),
            semester: _generateNonEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
            progress: validProgress,
          );
          
          // The task should pass progress validation
          expect(task.validateProgressRange(), isTrue,
                 reason: 'Task with progress $validProgress should pass validation (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 6: Past deadline rejection** - Tasks with past deadlines should be rejected', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a past deadline (1 to 365 days ago)
          final pastDeadline = DateTime.now().subtract(Duration(days: random.nextInt(365) + 1));
          
          final task = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: pastDeadline,
            semester: _generateNonEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
            progress: random.nextInt(101),
          );
          
          // The task should fail deadline validation
          expect(task.validateDeadlineNotPast(), isFalse,
                 reason: 'Task with past deadline should fail validation (iteration $i)');
          expect(task.isValid(), isFalse,
                 reason: 'Task with past deadline should fail overall validation (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 6: Past deadline rejection** - Tasks with future or today deadlines should be accepted', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a future deadline or today (0 to 365 days from now)
          final futureDeadline = DateTime.now().add(Duration(days: random.nextInt(366)));
          
          final task = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: futureDeadline,
            semester: _generateNonEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
            progress: random.nextInt(101),
          );
          
          // The task should pass deadline validation
          expect(task.validateDeadlineNotPast(), isTrue,
                 reason: 'Task with future/today deadline should pass validation (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 4: Task persistence round-trip** - For any valid task data, saving the task to the database and then retrieving it should return a task with identical field values', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a valid task with random data
          final originalTask = Task(
            id: random.nextInt(1000),
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(days: random.nextInt(365) + 1)),
            semester: _generateNonEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
            progress: random.nextInt(101),
            createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
            updatedAt: DateTime.now(),
          );
          
          // Test JSON serialization round-trip
          final jsonMap = originalTask.toJson();
          final taskFromJson = Task.fromJson(jsonMap);
          
          expect(taskFromJson.id, equals(originalTask.id),
                 reason: 'JSON round-trip should preserve id (iteration $i)');
          expect(taskFromJson.name, equals(originalTask.name),
                 reason: 'JSON round-trip should preserve name (iteration $i)');
          expect(taskFromJson.courseName, equals(originalTask.courseName),
                 reason: 'JSON round-trip should preserve courseName (iteration $i)');
          expect(taskFromJson.instructorName, equals(originalTask.instructorName),
                 reason: 'JSON round-trip should preserve instructorName (iteration $i)');
          expect(taskFromJson.deadline, equals(originalTask.deadline),
                 reason: 'JSON round-trip should preserve deadline (iteration $i)');
          expect(taskFromJson.semester, equals(originalTask.semester),
                 reason: 'JSON round-trip should preserve semester (iteration $i)');
          expect(taskFromJson.period, equals(originalTask.period),
                 reason: 'JSON round-trip should preserve period (iteration $i)');
          expect(taskFromJson.progress, equals(originalTask.progress),
                 reason: 'JSON round-trip should preserve progress (iteration $i)');
          expect(taskFromJson.createdAt, equals(originalTask.createdAt),
                 reason: 'JSON round-trip should preserve createdAt (iteration $i)');
          expect(taskFromJson.updatedAt, equals(originalTask.updatedAt),
                 reason: 'JSON round-trip should preserve updatedAt (iteration $i)');
          
          // Test database Map serialization round-trip
          final mapData = originalTask.toMap();
          final taskFromMap = Task.fromMap(mapData);
          
          expect(taskFromMap.id, equals(originalTask.id),
                 reason: 'Map round-trip should preserve id (iteration $i)');
          expect(taskFromMap.name, equals(originalTask.name),
                 reason: 'Map round-trip should preserve name (iteration $i)');
          expect(taskFromMap.courseName, equals(originalTask.courseName),
                 reason: 'Map round-trip should preserve courseName (iteration $i)');
          expect(taskFromMap.instructorName, equals(originalTask.instructorName),
                 reason: 'Map round-trip should preserve instructorName (iteration $i)');
          expect(taskFromMap.deadline, equals(originalTask.deadline),
                 reason: 'Map round-trip should preserve deadline (iteration $i)');
          expect(taskFromMap.semester, equals(originalTask.semester),
                 reason: 'Map round-trip should preserve semester (iteration $i)');
          expect(taskFromMap.period, equals(originalTask.period),
                 reason: 'Map round-trip should preserve period (iteration $i)');
          expect(taskFromMap.progress, equals(originalTask.progress),
                 reason: 'Map round-trip should preserve progress (iteration $i)');
          expect(taskFromMap.createdAt, equals(originalTask.createdAt),
                 reason: 'Map round-trip should preserve createdAt (iteration $i)');
          expect(taskFromMap.updatedAt, equals(originalTask.updatedAt),
                 reason: 'Map round-trip should preserve updatedAt (iteration $i)');
          
          // Test that the round-trip tasks are equal to the original
          expect(taskFromJson, equals(originalTask),
                 reason: 'JSON round-trip should produce equal task (iteration $i)');
          expect(taskFromMap, equals(originalTask),
                 reason: 'Map round-trip should produce equal task (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 4: Task persistence round-trip** - ISO-8601 date format should be preserved in serialization', () {
        final random = Random();
        
        // Run property test with 100 iterations focusing on date serialization
        for (int i = 0; i < 100; i++) {
          final originalTask = Task(
            name: _generateNonEmptyString(random),
            courseName: _generateNonEmptyString(random),
            instructorName: _generateNonEmptyString(random),
            deadline: DateTime.now().add(Duration(
              days: random.nextInt(365),
              hours: random.nextInt(24),
              minutes: random.nextInt(60),
              seconds: random.nextInt(60),
              milliseconds: random.nextInt(1000),
            )),
            semester: _generateNonEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
            progress: random.nextInt(101),
          );
          
          // Test JSON serialization preserves ISO-8601 format
          final jsonMap = originalTask.toJson();
          final deadlineString = jsonMap['deadline'] as String;
          final createdAtString = jsonMap['created_at'] as String;
          final updatedAtString = jsonMap['updated_at'] as String;
          
          // Verify ISO-8601 format can be parsed back to DateTime
          final parsedDeadline = DateTime.parse(deadlineString);
          final parsedCreatedAt = DateTime.parse(createdAtString);
          final parsedUpdatedAt = DateTime.parse(updatedAtString);
          
          expect(parsedDeadline, equals(originalTask.deadline),
                 reason: 'ISO-8601 deadline should parse correctly (iteration $i)');
          expect(parsedCreatedAt, equals(originalTask.createdAt),
                 reason: 'ISO-8601 createdAt should parse correctly (iteration $i)');
          expect(parsedUpdatedAt, equals(originalTask.updatedAt),
                 reason: 'ISO-8601 updatedAt should parse correctly (iteration $i)');
          
          // Test Map serialization preserves ISO-8601 format
          final mapData = originalTask.toMap();
          final mapDeadlineString = mapData['deadline'] as String;
          final mapCreatedAtString = mapData['created_at'] as String;
          final mapUpdatedAtString = mapData['updated_at'] as String;
          
          final mapParsedDeadline = DateTime.parse(mapDeadlineString);
          final mapParsedCreatedAt = DateTime.parse(mapCreatedAtString);
          final mapParsedUpdatedAt = DateTime.parse(mapUpdatedAtString);
          
          expect(mapParsedDeadline, equals(originalTask.deadline),
                 reason: 'Map ISO-8601 deadline should parse correctly (iteration $i)');
          expect(mapParsedCreatedAt, equals(originalTask.createdAt),
                 reason: 'Map ISO-8601 createdAt should parse correctly (iteration $i)');
          expect(mapParsedUpdatedAt, equals(originalTask.updatedAt),
                 reason: 'Map ISO-8601 updatedAt should parse correctly (iteration $i)');
        }
      });
    });

    group('Unit Tests', () {
      test('Task creation with default values', () {
        final now = DateTime.now();
        final deadline = now.add(Duration(days: 7));
        
        final task = Task(
          name: 'Test Task',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: deadline,
          semester: 'Semester 4',
          period: 'UTS',
        );
        
        expect(task.name, equals('Test Task'));
        expect(task.courseName, equals('Test Course'));
        expect(task.instructorName, equals('Test Instructor'));
        expect(task.deadline, equals(deadline));
        expect(task.semester, equals('Semester 4'));
        expect(task.period, equals('UTS'));
        expect(task.progress, equals(0)); // Default value
        expect(task.createdAt, isNotNull);
        expect(task.updatedAt, isNotNull);
      });

      test('Task validation methods', () {
        final validTask = Task(
          name: 'Valid Task',
          courseName: 'Valid Course',
          instructorName: 'Valid Instructor',
          deadline: DateTime.now().add(Duration(days: 1)),
          semester: 'Semester 4',
          period: 'UTS',
          progress: 50,
        );
        
        expect(validTask.validateRequiredFields(), isTrue);
        expect(validTask.validateProgressRange(), isTrue);
        expect(validTask.validatePeriod(), isTrue);
        expect(validTask.validateDeadlineNotPast(), isTrue);
        expect(validTask.isValid(), isTrue);
      });

      test('Task with invalid period should fail validation', () {
        final task = Task(
          name: 'Test Task',
          courseName: 'Test Course',
          instructorName: 'Test Instructor',
          deadline: DateTime.now().add(Duration(days: 1)),
          semester: 'Semester 4',
          period: 'INVALID',
          progress: 50,
        );
        
        expect(task.validatePeriod(), isFalse);
        expect(task.isValid(), isFalse);
      });
    });
  });
}

// Helper functions for property testing
String _generateEmptyString(Random random) {
  final emptyOptions = ['', '   ', '\t', '\n', '  \t  \n  '];
  return emptyOptions[random.nextInt(emptyOptions.length)];
}

String _generateNonEmptyString(Random random) {
  final words = ['Task', 'Course', 'Instructor', 'Semester', 'Project', 'Assignment', 'Lab', 'Quiz'];
  final word1 = words[random.nextInt(words.length)];
  final word2 = words[random.nextInt(words.length)];
  final number = random.nextInt(10);
  return '$word1 $word2 $number';
}