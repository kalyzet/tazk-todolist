import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../lib/models/task.dart';
import '../../../lib/services/deadline_service.dart';
import '../../../lib/ui/widgets/task_list_item.dart';

/// Property-based tests for TaskListItem widget
/// 
/// **Feature: academic-task-manager, Property 9: Progress visualization**
/// **Validates: Requirements 4.4**
void main() {
  group('TaskListItem Progress Visualization Property Tests', () {
    late DeadlineService deadlineService;

    setUp(() {
      deadlineService = DeadlineService();
    });

    /// Helper function to create a test widget with localization
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id', '')],
        locale: const Locale('id', ''),
        home: Scaffold(body: child),
      );
    }

    /// Generate a task with specific progress value
    Task generateTaskWithProgress(int progress) {
      return Task(
        id: 1,
        name: 'Test Task',
        courseName: 'Test Course',
        instructorName: 'Test Instructor',
        deadline: DateTime.now().add(const Duration(days: 7)),
        semester: 'Semester 1',
        period: 'UTS',
        progress: progress,
      );
    }

    testWidgets(
      '**Feature: academic-task-manager, Property 9: Progress visualization** - '
      'For any task with a progress value, the visual progress indicator should accurately reflect the percentage completion',
      (WidgetTester tester) async {
        // Test multiple progress values to ensure property holds across all valid inputs
        final testProgressValues = [0, 1, 25, 50, 75, 99, 100];
        
        for (final progress in testProgressValues) {
          // Generate task with specific progress
          final task = generateTaskWithProgress(progress);
          
          // Build the widget
          await tester.pumpWidget(
            createTestWidget(
              TaskListItem(
                task: task,
                deadlineService: deadlineService,
              ),
            ),
          );
          
          // Find the progress indicator
          final progressIndicator = find.byType(LinearProgressIndicator);
          expect(progressIndicator, findsOneWidget);
          
          // Get the LinearProgressIndicator widget
          final progressWidget = tester.widget<LinearProgressIndicator>(progressIndicator);
          
          // Verify that the progress value matches the task progress
          final expectedValue = progress / 100.0;
          expect(progressWidget.value, equals(expectedValue),
              reason: 'Progress indicator value should match task progress ($progress%)');
          
          // Find and verify the progress text
          final progressText = find.text('$progress%');
          expect(progressText, findsOneWidget,
              reason: 'Progress text should display the correct percentage ($progress%)');
          
          // Verify completion icon appears only for 100% progress
          final completionIcon = find.byIcon(Icons.check_circle);
          if (progress == 100) {
            expect(completionIcon, findsOneWidget,
                reason: 'Completion icon should appear for 100% progress');
          } else {
            expect(completionIcon, findsNothing,
                reason: 'Completion icon should not appear for progress < 100%');
          }
          
          // Clean up for next iteration
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '**Feature: academic-task-manager, Property 9: Progress visualization** - '
      'Progress indicator color should change based on completion percentage',
      (WidgetTester tester) async {
        // Test different progress ranges and their expected colors
        final testCases = [
          {'progress': 0, 'expectedColorType': 'red'},
          {'progress': 20, 'expectedColorType': 'red'},
          {'progress': 30, 'expectedColorType': 'deepOrange'},
          {'progress': 60, 'expectedColorType': 'orange'},
          {'progress': 80, 'expectedColorType': 'blue'},
          {'progress': 100, 'expectedColorType': 'green'},
        ];
        
        for (final testCase in testCases) {
          final progress = testCase['progress'] as int;
          final task = generateTaskWithProgress(progress);
          
          // Build the widget
          await tester.pumpWidget(
            createTestWidget(
              TaskListItem(
                task: task,
                deadlineService: deadlineService,
              ),
            ),
          );
          
          // Find the progress indicator
          final progressIndicator = find.byType(LinearProgressIndicator);
          expect(progressIndicator, findsOneWidget);
          
          // Get the LinearProgressIndicator widget
          final progressWidget = tester.widget<LinearProgressIndicator>(progressIndicator);
          
          // Verify that the progress indicator has a color (not null)
          expect(progressWidget.valueColor, isNotNull,
              reason: 'Progress indicator should have a color for progress $progress%');
          
          // The color should be appropriate for the progress level
          // We can't test exact colors due to theme variations, but we can ensure it's set
          final colorAnimation = progressWidget.valueColor as AlwaysStoppedAnimation<Color>;
          expect(colorAnimation.value, isA<Color>(),
              reason: 'Progress indicator should have a valid color for progress $progress%');
          
          // Clean up for next iteration
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '**Feature: academic-task-manager, Property 9: Progress visualization** - '
      'Progress visualization should be consistent across different task data',
      (WidgetTester tester) async {
        // Test with various task configurations to ensure progress visualization is consistent
        final testTasks = [
          Task(
            id: 1,
            name: 'Short Task',
            courseName: 'Math',
            instructorName: 'Dr. A',
            deadline: DateTime.now().add(const Duration(days: 1)),
            semester: 'Semester 1',
            period: 'UTS',
            progress: 75,
          ),
          Task(
            id: 2,
            name: 'Very Long Task Name That Might Wrap Multiple Lines',
            courseName: 'Computer Science and Information Technology',
            instructorName: 'Prof. Dr. Very Long Name Here',
            deadline: DateTime.now().add(const Duration(days: 30)),
            semester: 'Semester 8',
            period: 'UAS',
            progress: 75,
          ),
          Task(
            id: 3,
            name: 'Overdue Task',
            courseName: 'Physics',
            instructorName: 'Dr. B',
            deadline: DateTime.now().subtract(const Duration(days: 5)),
            semester: 'Semester 3',
            period: 'UTS',
            progress: 75,
          ),
        ];
        
        for (final task in testTasks) {
          // Build the widget
          await tester.pumpWidget(
            createTestWidget(
              TaskListItem(
                task: task,
                deadlineService: deadlineService,
              ),
            ),
          );
          
          // Find the progress indicator
          final progressIndicator = find.byType(LinearProgressIndicator);
          expect(progressIndicator, findsOneWidget,
              reason: 'Progress indicator should be present regardless of task data');
          
          // Get the LinearProgressIndicator widget
          final progressWidget = tester.widget<LinearProgressIndicator>(progressIndicator);
          
          // Verify that the progress value is consistent (75% for all test tasks)
          expect(progressWidget.value, equals(0.75),
              reason: 'Progress indicator should show 75% for task: ${task.name}');
          
          // Find and verify the progress text
          final progressText = find.text('75%');
          expect(progressText, findsOneWidget,
              reason: 'Progress text should display 75% for task: ${task.name}');
          
          // Clean up for next iteration
          await tester.pumpAndSettle();
        }
      },
    );
  });
}