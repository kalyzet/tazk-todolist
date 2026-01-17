import 'package:test/test.dart';
import 'package:tazk/models/academic_context.dart';
import 'dart:math';

void main() {
  group('AcademicContext Model Tests', () {
    group('Property Tests', () {
      test('**Feature: academic-task-manager, Property 1: Context persistence round-trip** - For any valid academic context (semester and period combination), saving the context to SharedPreferences and then retrieving it should return the identical context', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a valid academic context with random data
          final originalContext = AcademicContext(
            semester: _generateRandomSemester(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
          );
          
          // Test JSON serialization round-trip (for backup functionality)
          final jsonMap = originalContext.toJson();
          final contextFromJson = AcademicContext.fromJson(jsonMap);
          
          expect(contextFromJson.semester, equals(originalContext.semester),
                 reason: 'JSON round-trip should preserve semester (iteration $i)');
          expect(contextFromJson.period, equals(originalContext.period),
                 reason: 'JSON round-trip should preserve period (iteration $i)');
          expect(contextFromJson, equals(originalContext),
                 reason: 'JSON round-trip should produce equal context (iteration $i)');
          
          // Test Map serialization round-trip (for SharedPreferences)
          final mapData = originalContext.toMap();
          final contextFromMap = AcademicContext.fromMap(mapData);
          
          expect(contextFromMap.semester, equals(originalContext.semester),
                 reason: 'Map round-trip should preserve semester (iteration $i)');
          expect(contextFromMap.period, equals(originalContext.period),
                 reason: 'Map round-trip should preserve period (iteration $i)');
          expect(contextFromMap, equals(originalContext),
                 reason: 'Map round-trip should produce equal context (iteration $i)');
          
          // Test that display names are consistent
          expect(contextFromJson.displayName, equals(originalContext.displayName),
                 reason: 'JSON round-trip should preserve display name (iteration $i)');
          expect(contextFromMap.displayName, equals(originalContext.displayName),
                 reason: 'Map round-trip should preserve display name (iteration $i)');
          
          // Test Indonesian display names
          expect(contextFromJson.indonesianDisplayName, equals(originalContext.indonesianDisplayName),
                 reason: 'JSON round-trip should preserve Indonesian display name (iteration $i)');
          expect(contextFromMap.indonesianDisplayName, equals(originalContext.indonesianDisplayName),
                 reason: 'Map round-trip should preserve Indonesian display name (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 1: Context persistence round-trip** - Context validation should be preserved through serialization', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate contexts with various validity states
          final semester = random.nextBool() ? _generateRandomSemester(random) : _generateEmptyString(random);
          final period = random.nextBool() ? (random.nextBool() ? 'UTS' : 'UAS') : _generateInvalidPeriod(random);
          
          final originalContext = AcademicContext(
            semester: semester,
            period: period,
          );
          
          final originalValidity = originalContext.isValid();
          
          // Test JSON round-trip preserves validity
          final jsonMap = originalContext.toJson();
          final contextFromJson = AcademicContext.fromJson(jsonMap);
          
          expect(contextFromJson.isValid(), equals(originalValidity),
                 reason: 'JSON round-trip should preserve validity state (iteration $i)');
          
          // Test Map round-trip preserves validity
          final mapData = originalContext.toMap();
          final contextFromMap = AcademicContext.fromMap(mapData);
          
          expect(contextFromMap.isValid(), equals(originalValidity),
                 reason: 'Map round-trip should preserve validity state (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 2: Empty input validation** - Context with empty semester should be invalid', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          final emptyContext = AcademicContext(
            semester: _generateEmptyString(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
          );
          
          expect(emptyContext.validateSemester(), isFalse,
                 reason: 'Context with empty semester should fail validation (iteration $i)');
          expect(emptyContext.isValid(), isFalse,
                 reason: 'Context with empty semester should be invalid (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 2: Empty input validation** - Context with invalid period should be invalid', () {
        final random = Random();
        
        // Run property test with 100 iterations
        for (int i = 0; i < 100; i++) {
          final invalidContext = AcademicContext(
            semester: _generateRandomSemester(random),
            period: _generateInvalidPeriod(random),
          );
          
          expect(invalidContext.validatePeriod(), isFalse,
                 reason: 'Context with invalid period should fail validation (iteration $i)');
          expect(invalidContext.isValid(), isFalse,
                 reason: 'Context with invalid period should be invalid (iteration $i)');
        }
      });

      test('**Feature: academic-task-manager, Property 1: Context persistence round-trip** - Valid contexts should maintain validity through serialization', () {
        final random = Random();
        
        // Run property test with 100 iterations for valid contexts only
        for (int i = 0; i < 100; i++) {
          final validContext = AcademicContext(
            semester: _generateRandomSemester(random),
            period: random.nextBool() ? 'UTS' : 'UAS',
          );
          
          // Ensure the original context is valid
          expect(validContext.isValid(), isTrue,
                 reason: 'Generated context should be valid (iteration $i)');
          
          // Test JSON round-trip maintains validity
          final jsonMap = validContext.toJson();
          final contextFromJson = AcademicContext.fromJson(jsonMap);
          
          expect(contextFromJson.isValid(), isTrue,
                 reason: 'JSON round-trip should maintain validity (iteration $i)');
          
          // Test Map round-trip maintains validity
          final mapData = validContext.toMap();
          final contextFromMap = AcademicContext.fromMap(mapData);
          
          expect(contextFromMap.isValid(), isTrue,
                 reason: 'Map round-trip should maintain validity (iteration $i)');
        }
      });
    });

    group('Unit Tests', () {
      test('AcademicContext creation and basic properties', () {
        final context = AcademicContext(
          semester: 'Semester 4',
          period: 'UTS',
        );
        
        expect(context.semester, equals('Semester 4'));
        expect(context.period, equals('UTS'));
        expect(context.displayName, equals('Semester 4 - UTS'));
        expect(context.indonesianDisplayName, equals('Semester 4 - Ujian Tengah Semester'));
        expect(context.periodIndonesianName, equals('Ujian Tengah Semester'));
      });

      test('AcademicContext validation methods', () {
        final validContext = AcademicContext(
          semester: 'Semester 4',
          period: 'UAS',
        );
        
        expect(validContext.validateSemester(), isTrue);
        expect(validContext.validatePeriod(), isTrue);
        expect(validContext.isValid(), isTrue);
        expect(validContext.periodIndonesianName, equals('Ujian Akhir Semester'));
      });

      test('AcademicContext with invalid data', () {
        final invalidContext = AcademicContext(
          semester: '',
          period: 'INVALID',
        );
        
        expect(invalidContext.validateSemester(), isFalse);
        expect(invalidContext.validatePeriod(), isFalse);
        expect(invalidContext.isValid(), isFalse);
      });

      test('AcademicContext static methods', () {
        expect(AcademicContext.validPeriods, equals(['UTS', 'UAS']));
        expect(AcademicContext.periodIndonesianNames['UTS'], equals('Ujian Tengah Semester'));
        expect(AcademicContext.periodIndonesianNames['UAS'], equals('Ujian Akhir Semester'));
      });

      test('AcademicContext copyWith method', () {
        final original = AcademicContext(
          semester: 'Semester 4',
          period: 'UTS',
        );
        
        final copied = original.copyWith(period: 'UAS');
        
        expect(copied.semester, equals('Semester 4'));
        expect(copied.period, equals('UAS'));
        expect(original.period, equals('UTS')); // Original unchanged
      });

      test('AcademicContext equality and hashCode', () {
        final context1 = AcademicContext(semester: 'Semester 4', period: 'UTS');
        final context2 = AcademicContext(semester: 'Semester 4', period: 'UTS');
        final context3 = AcademicContext(semester: 'Semester 4', period: 'UAS');
        
        expect(context1, equals(context2));
        expect(context1.hashCode, equals(context2.hashCode));
        expect(context1, isNot(equals(context3)));
      });
    });
  });
}

// Helper functions for property testing
String _generateRandomSemester(Random random) {
  final semesters = [
    'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4',
    'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8',
    'Semester Ganjil 2024', 'Semester Genap 2024',
    'Semester Ganjil 2025', 'Semester Genap 2025'
  ];
  return semesters[random.nextInt(semesters.length)];
}

String _generateEmptyString(Random random) {
  final emptyOptions = ['', '   ', '\t', '\n', '  \t  \n  '];
  return emptyOptions[random.nextInt(emptyOptions.length)];
}

String _generateInvalidPeriod(Random random) {
  final invalidPeriods = ['INVALID', 'MID', 'FINAL', 'TEST', 'EXAM', 'uts', 'uas', 'Uts', 'Uas'];
  return invalidPeriods[random.nextInt(invalidPeriods.length)];
}