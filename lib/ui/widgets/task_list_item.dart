import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../services/deadline_service.dart';

/// Individual task item widget for the task list
/// 
/// Features:
/// - Progress indicator visualization
/// - Remaining days and overdue indicators
/// - Course and instructor information
/// - Tap handling for navigation
/// 
/// Requirements: 4.4, 5.4, 5.5
class TaskListItem extends StatelessWidget {
  final Task task;
  final DeadlineService deadlineService;
  final VoidCallback? onTap;

  const TaskListItem({
    super.key,
    required this.task,
    required this.deadlineService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final deadlineStatus = deadlineService.getDeadlineStatus(task);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task name and deadline status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DeadlineChip(
                    deadlineStatus: deadlineStatus,
                    theme: theme,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Course and instructor
              Row(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.courseName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.instructorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.progres,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${task.progress}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getProgressColor(task.progress, theme),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: task.progress / 100,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(task.progress, theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Completion status icon
                  if (task.progress == 100) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get progress color based on completion percentage
  Color _getProgressColor(int progress, ThemeData theme) {
    if (progress == 100) {
      return Colors.green;
    } else if (progress >= 75) {
      return Colors.blue;
    } else if (progress >= 50) {
      return Colors.orange;
    } else if (progress >= 25) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }
}

/// Deadline status chip widget
class _DeadlineChip extends StatelessWidget {
  final Map<String, dynamic> deadlineStatus;
  final ThemeData theme;

  const _DeadlineChip({
    required this.deadlineStatus,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final status = deadlineStatus['status'] as String;
    final isOverdue = deadlineStatus['is_overdue'] as bool;
    final remainingDays = deadlineStatus['remaining_days'] as int;
    final deadlineText = deadlineStatus['deadline_text'] as String;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (status == 'completed') {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isOverdue) {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      icon = Icons.warning;
    } else if (remainingDays <= 1) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      icon = Icons.schedule;
    } else if (remainingDays <= 3) {
      backgroundColor = Colors.yellow.withOpacity(0.1);
      textColor = Colors.orange.shade700;
      icon = Icons.schedule;
    } else {
      backgroundColor = theme.colorScheme.primaryContainer.withOpacity(0.3);
      textColor = theme.colorScheme.primary;
      icon = Icons.schedule;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            deadlineText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}