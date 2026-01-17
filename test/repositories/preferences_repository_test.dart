import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/repositories/preferences_repository.dart';
import '../../lib/models/academic_context.dart';
import 'dart:math';

void main() {
  group('PreferencesRepository Property Tests', () {
    late PreferencesRepository repository;

    setUp(() async {
      repository = PreferencesRepository();
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    /// **Feature: academic-task-manager, Property 15: Sort preference persistence**
    /// **Validates: Requirements 7.5**
    test('Property 15: Sort preference persistence', () async {
      final random = Random();
      
      // Run property test with 100 iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Clear preferences for each iteration
        SharedPreferences.setMockInitialValues({});
        
        // Generate random valid sort preference
        final validSortOptions = PreferencesRepository.getValidSortOptions();
        final randomSortPreference = validSortOptions[random.nextInt(validSortOptions.length)];
        
        // Test the property: saving and retrieving sort preference should return identical value
        final saveResult = await repository.saveSortPreference(randomSortPreference);
        expect(saveResult, isTrue, reason: 'Save operation should succeed for valid sort preference');
        
        final retrievedPreference = await repository.getSortPreference();
        expect(retrievedPreference, equals(randomSortPreference),
            reason: 'Retrieved sort preference should match the saved preference');
        
        // Additional verification: preference should persist across multiple retrievals
        final secondRetrieval = await repository.getSortPreference();
        expect(secondRetrieval, equals(randomSortPreference),
            reason: 'Sort preference should persist across multiple retrievals');
        
        // Verify preference exists
        final hasPreference = await repository.hasSortPreference();
        expect(hasPreference, isTrue, reason: 'Should indicate that preference exists after saving');
      }
    });

    /// Additional property test for context persistence (Property 1)
    /// **Feature: academic-task-manager, Property 1: Context persistence round-trip**
    /// **Validates: Requirements 1.3, 2.4**
    test('Property 1: Context persistence round-trip', () async {
      final random = Random();
      
      // Run property test with 100 iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Clear preferences for each iteration
        SharedPreferences.setMockInitialValues({});
        
        // Generate random valid academic context
        final randomContext = _generateRandomAcademicContext(random);
        
        // Test the property: saving and retrieving context should return identical context
        final saveResult = await repository.saveLastContext(randomContext);
        expect(saveResult, isTrue, reason: 'Save operation should succeed for valid context');
        
        final retrievedContext = await repository.getLastContext();
        expect(retrievedContext, isNotNull, reason: 'Retrieved context should not be null');
        expect(retrievedContext!.semester, equals(randomContext.semester),
            reason: 'Retrieved context semester should match saved context');
        expect(retrievedContext.period, equals(randomContext.period),
            reason: 'Retrieved context period should match saved context');
        
        // Verify contexts are equal using the equality operator
        expect(retrievedContext, equals(randomContext),
            reason: 'Retrieved context should be equal to saved context');
        
        // Additional verification: context should persist across multiple retrievals
        final secondRetrieval = await repository.getLastContext();
        expect(secondRetrieval, equals(randomContext),
            reason: 'Context should persist across multiple retrievals');
        
        // Verify context exists
        final hasContext = await repository.hasLastContext();
        expect(hasContext, isTrue, reason: 'Should indicate that context exists after saving');
      }
    });

    /// Property test for empty input validation (Property 2)
    /// **Feature: academic-task-manager, Property 2: Empty input validation**
    /// **Validates: Requirements 1.5, 3.1, 3.3**
    test('Property 2: Empty input validation', () async {
      final random = Random();
      
      // Run property test with 100 iterations
      for (int iteration = 0; iteration < 100; iteration++) {
        // Clear preferences for each iteration
        SharedPreferences.setMockInitialValues({});
        
        // Test invalid sort preferences
        final invalidSortOptions = _generateInvalidSortOptions(random);
        
        for (final invalidSort in invalidSortOptions) {
          // Test the property: invalid sort preferences should be rejected
          final saveResult = await repository.saveSortPreference(invalidSort);
          expect(saveResult, isFalse, 
              reason: 'Save operation should fail for invalid sort preference: $invalidSort');
          
          // Verify that no preference was saved
          final retrievedPreference = await repository.getSortPreference();
          expect(retrievedPreference, equals('deadline'),
              reason: 'Should return default preference when invalid preference is attempted');
          
          final hasPreference = await repository.hasSortPreference();
          expect(hasPreference, isFalse, 
              reason: 'Should not indicate preference exists after failed save');
        }
        
        // Test invalid academic contexts
        final invalidContexts = _generateInvalidAcademicContexts(random);
        
        for (final invalidContext in invalidContexts) {
          // Save the invalid context (this should succeed at repository level)
          final saveResult = await repository.saveLastContext(invalidContext);
          expect(saveResult, isTrue, reason: 'Repository should save any context');
          
          // Test the property: invalid contexts should be rejected during retrieval
          final retrievedContext = await repository.getLastContext();
          expect(retrievedContext, isNull,
              reason: 'Should return null for invalid context and clear corrupted data');
          
          // Verify corrupted data was cleared
          final hasContext = await repository.hasLastContext();
          expect(hasContext, isFalse,
              reason: 'Should not indicate context exists after invalid context was cleared');
        }
      }
    });

    // Unit tests for edge cases and specific scenarios
    group('Unit Tests', () {
      test('should return default sort preference when none is saved', () async {
        SharedPreferences.setMockInitialValues({});
        
        final preference = await repository.getSortPreference();
        expect(preference, equals('deadline'));
      });

      test('should return null context when none is saved', () async {
        SharedPreferences.setMockInitialValues({});
        
        final context = await repository.getLastContext();
        expect(context, isNull);
      });

      test('should clear all preferences successfully', () async {
        // Save some preferences first
        await repository.saveSortPreference('progress');
        await repository.saveLastContext(AcademicContext(semester: 'Semester 1', period: 'UTS'));
        
        // Clear all
        final result = await repository.clearAll();
        expect(result, isTrue);
        
        // Verify all cleared
        final hasSort = await repository.hasSortPreference();
        final hasContext = await repository.hasLastContext();
        expect(hasSort, isFalse);
        expect(hasContext, isFalse);
      });

      test('should validate sort options correctly', () {
        expect(PreferencesRepository.isValidSortOption('deadline'), isTrue);
        expect(PreferencesRepository.isValidSortOption('progress'), isTrue);
        expect(PreferencesRepository.isValidSortOption('course_name'), isTrue);
        expect(PreferencesRepository.isValidSortOption('task_name'), isTrue);
        expect(PreferencesRepository.isValidSortOption('invalid'), isFalse);
        expect(PreferencesRepository.isValidSortOption(''), isFalse);
      });
    });
  });
}

/// Generate random valid academic context
AcademicContext _generateRandomAcademicContext(Random random) {
  final semesters = [
    'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 
    'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'
  ];
  final periods = ['UTS', 'UAS'];
  
  return AcademicContext(
    semester: semesters[random.nextInt(semesters.length)],
    period: periods[random.nextInt(periods.length)],
  );
}

/// Generate invalid sort options for testing
List<String> _generateInvalidSortOptions(Random random) {
  final invalidOptions = [
    '', // Empty string
    ' ', // Whitespace only
    'invalid_sort',
    'DEADLINE', // Wrong case
    'Progress', // Wrong case
    'course-name', // Wrong format
    'task.name', // Wrong format
    'random_string_${random.nextInt(1000)}',
    'null',
    '123',
    'deadline ', // Trailing space
    ' deadline', // Leading space
  ];
  
  // Return a random subset of invalid options
  final count = 3 + random.nextInt(5); // 3-7 invalid options
  invalidOptions.shuffle(random);
  return invalidOptions.take(count).toList();
}

/// Generate invalid academic contexts for testing
List<AcademicContext> _generateInvalidAcademicContexts(Random random) {
  final invalidContexts = <AcademicContext>[];
  
  // Empty semester
  invalidContexts.add(AcademicContext(semester: '', period: 'UTS'));
  
  // Empty period
  invalidContexts.add(AcademicContext(semester: 'Semester 1', period: ''));
  
  // Both empty
  invalidContexts.add(AcademicContext(semester: '', period: ''));
  
  // Whitespace only semester
  invalidContexts.add(AcademicContext(semester: '   ', period: 'UTS'));
  
  // Whitespace only period
  invalidContexts.add(AcademicContext(semester: 'Semester 1', period: '   '));
  
  // Invalid period values
  final invalidPeriods = ['uts', 'UAS ', ' UTS', 'MIDTERM', 'FINAL', 'invalid'];
  for (final invalidPeriod in invalidPeriods) {
    invalidContexts.add(AcademicContext(
      semester: 'Semester ${1 + random.nextInt(8)}', 
      period: invalidPeriod
    ));
  }
  
  // Return a random subset
  final count = 3 + random.nextInt(invalidContexts.length - 2);
  invalidContexts.shuffle(random);
  return invalidContexts.take(count).toList();
}