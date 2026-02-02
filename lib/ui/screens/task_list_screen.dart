import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/academic_context.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../services/deadline_service.dart';
import '../widgets/task_list_item.dart';
import '../widgets/context_switcher.dart';
import '../widgets/sort_options_sheet.dart';

/// Task list screen with context awareness and sorting functionality
/// 
/// Features:
/// - Task list display with progress indicators
/// - Context switching functionality in app bar
/// - Sorting options with visual feedback
/// - Floating action button for task creation
/// - Remaining days and overdue indicators
/// 
/// Requirements: 2.2, 4.4, 5.4, 5.5, 6.2, 7.1
class TaskListScreen extends StatefulWidget {
  final AcademicContext? initialContext;

  const TaskListScreen({
    super.key,
    this.initialContext,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DeadlineService _deadlineService = DeadlineService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  /// Initialize the task provider with initial context if provided
  void _initializeProvider() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Initialize the provider
    await taskProvider.initialize();
    
    // If we have an initial context and no current context, switch to it
    if (widget.initialContext != null && !taskProvider.hasContext) {
      await taskProvider.switchContext(widget.initialContext!);
    }
  }

  /// Show context switcher dialog
  void _showContextSwitcher() {
    showDialog(
      context: context,
      builder: (context) => const ContextSwitcher(),
    );
  }

  /// Show sort options bottom sheet
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SortOptionsSheet(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  /// Navigate to task creation screen
  void _navigateToTaskCreation() {
    Navigator.of(context).pushNamed('/task-create');
  }

  /// Navigate to task detail/edit screen
  void _navigateToTaskDetail(Task task) {
    Navigator.of(context).pushNamed(
      '/task-edit',
      arguments: task,
    );
  }

  /// Refresh task list
  Future<void> _refreshTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (taskProvider.hasContext) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.taskList,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    taskProvider.currentContext!.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }
            return Text(l10n.taskList);
          },
        ),
        actions: [
          // Context switcher button
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.hasContext) {
                return IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _showContextSwitcher,
                  tooltip: 'Ganti Konteks',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Sort options button
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.hasTasks) {
                return IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortOptions,
                  tooltip: l10n.sortBy,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Show loading indicator
          if (taskProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error message
          if (taskProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    taskProvider.errorMessage!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _refreshTasks,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Show setup screen if no context
          if (!taskProvider.hasContext) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Konteks Akademik',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih semester dan periode untuk memulai',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _showContextSwitcher,
                    child: const Text('Pilih Konteks'),
                  ),
                ],
              ),
            );
          }

          // Show empty state if no tasks
          if (!taskProvider.hasTasks) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTasks,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noTasksSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Show task list
          return RefreshIndicator(
            onRefresh: _refreshTasks,
            child: Column(
              children: [
                // Task statistics header
                _TaskStatisticsHeader(
                  tasks: taskProvider.tasks,
                  deadlineService: _deadlineService,
                ),
                
                // Sort indicator
                if (taskProvider.hasTasks)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.sortBy}: ${taskProvider.currentSortLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Task list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: taskProvider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskListItem(
                          task: task,
                          deadlineService: _deadlineService,
                          onTap: () => _navigateToTaskDetail(task),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      
      // Floating action button for adding tasks
      floatingActionButton: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.hasContext) {
            return FloatingActionButton(
              onPressed: _navigateToTaskCreation,
              tooltip: l10n.addTask,
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Widget to display task statistics at the top of the list
class _TaskStatisticsHeader extends StatelessWidget {
  final List<Task> tasks;
  final DeadlineService deadlineService;

  const _TaskStatisticsHeader({
    required this.tasks,
    required this.deadlineService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = deadlineService.getDeadlineStatistics(tasks);
    
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primaryContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Tugas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total',
                  value: tasks.length.toString(),
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Selesai',
                  value: (tasks.length - stats['total_incomplete']!).toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Terlambat',
                  value: stats['overdue'].toString(),
                  color: Colors.red,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Segera',
                  value: (stats['due_today']! + stats['due_tomorrow']! + stats['due_soon']!).toString(),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual statistic item widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}