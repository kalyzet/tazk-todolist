import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/task_provider.dart';

/// Bottom sheet for selecting task sorting options
/// 
/// Features:
/// - Visual feedback for current sort option
/// - Indonesian labels for sort criteria
/// - Integration with TaskProvider for sort preference persistence
/// 
/// Requirements: 7.1, 7.2
class SortOptionsSheet extends StatelessWidget {
  const SortOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              Text(
                l10n.sortBy,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Sort options
              ...TaskProvider.sortOptions.entries.map((entry) {
                final sortKey = entry.key;
                final sortLabel = entry.value;
                final isSelected = taskProvider.currentSortBy == sortKey;
                
                return _SortOptionTile(
                  title: sortLabel,
                  subtitle: _getSortDescription(sortKey, l10n),
                  isSelected: isSelected,
                  onTap: () async {
                    await taskProvider.changeSortBy(sortKey);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              }).toList(),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Get description for sort option in Indonesian
  String _getSortDescription(String sortKey, AppLocalizations l10n) {
    switch (sortKey) {
      case 'deadline':
        return 'Urutkan berdasarkan batas waktu (terdini ke terakhir)';
      case 'progress':
        return 'Urutkan berdasarkan progres (terendah ke tertinggi)';
      case 'course_name':
        return 'Urutkan berdasarkan nama mata kuliah (A-Z)';
      case 'task_name':
        return 'Urutkan berdasarkan nama tugas (A-Z)';
      default:
        return '';
    }
  }
}

/// Individual sort option tile
class _SortOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.8)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : null,
      ),
    );
  }
}