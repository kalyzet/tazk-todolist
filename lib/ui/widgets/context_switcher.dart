import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/academic_context.dart';
import '../../providers/task_provider.dart';

/// Context switcher dialog for changing academic context
/// 
/// Features:
/// - Semester selection dropdown
/// - Period selection (UTS/UAS) with Indonesian terminology
/// - Validation for context selection completeness
/// - Integration with TaskProvider for context switching
/// 
/// Requirements: 6.2, 6.5
class ContextSwitcher extends StatefulWidget {
  const ContextSwitcher({super.key});

  @override
  State<ContextSwitcher> createState() => _ContextSwitcherState();
}

class _ContextSwitcherState extends State<ContextSwitcher> {
  String? _selectedSemester;
  String? _selectedPeriod;
  String? _semesterError;
  String? _periodError;
  bool _isLoading = false;

  // Common semester options for Indonesian universities
  final List<String> _semesterOptions = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with current context if available
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (taskProvider.hasContext) {
      _selectedSemester = taskProvider.currentContext!.semester;
      _selectedPeriod = taskProvider.currentContext!.period;
    }
  }

  /// Validates the form and shows appropriate error messages
  bool _validateForm() {
    setState(() {
      _semesterError = null;
      _periodError = null;
    });

    bool isValid = true;
    final l10n = AppLocalizations.of(context)!;

    // Validate semester selection
    if (_selectedSemester == null || _selectedSemester!.trim().isEmpty) {
      setState(() {
        _semesterError = l10n.pleaseSelectSemester;
      });
      isValid = false;
    }

    // Validate period selection
    if (_selectedPeriod == null || _selectedPeriod!.trim().isEmpty) {
      setState(() {
        _periodError = l10n.pleaseSelectPeriod;
      });
      isValid = false;
    }

    return isValid;
  }

  /// Handles the context switch
  void _onSwitchContext() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create new academic context
      final newContext = AcademicContext(
        semester: _selectedSemester!,
        period: _selectedPeriod!,
      );

      // Switch context using TaskProvider
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.switchContext(newContext);

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengganti context: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Pilih Context Akademik',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Semester selection
            Text(
              l10n.selectSemester,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSemester,
              decoration: InputDecoration(
                hintText: l10n.selectSemester,
                errorText: _semesterError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _semesterOptions.map((semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(semester),
                );
              }).toList(),
              onChanged: _isLoading ? null : (value) {
                setState(() {
                  _selectedSemester = value;
                  _semesterError = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Period selection
            Text(
              l10n.selectPeriod,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Period selection cards
            Row(
              children: [
                Expanded(
                  child: _PeriodSelectionCard(
                    title: l10n.uts,
                    subtitle: l10n.utsLong,
                    value: 'UTS',
                    selectedValue: _selectedPeriod,
                    onSelected: _isLoading ? null : (value) {
                      setState(() {
                        _selectedPeriod = value;
                        _periodError = null;
                      });
                    },
                    hasError: _periodError != null,
                    isEnabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PeriodSelectionCard(
                    title: l10n.uas,
                    subtitle: l10n.uasLong,
                    value: 'UAS',
                    selectedValue: _selectedPeriod,
                    onSelected: _isLoading ? null : (value) {
                      setState(() {
                        _selectedPeriod = value;
                        _periodError = null;
                      });
                    },
                    hasError: _periodError != null,
                    isEnabled: !_isLoading,
                  ),
                ),
              ],
            ),
            
            // Period error message
            if (_periodError != null) ...[
              const SizedBox(height: 8),
              Text(
                _periodError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _onSwitchContext,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.continueButton),
        ),
      ],
    );
  }
}

/// Custom widget for period selection cards
class _PeriodSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String? selectedValue;
  final ValueChanged<String>? onSelected;
  final bool hasError;
  final bool isEnabled;

  const _PeriodSelectionCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
    this.hasError = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedValue == value;
    
    return GestureDetector(
      onTap: isEnabled ? () => onSelected?.call(value) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError
                ? theme.colorScheme.error
                : isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isEnabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isEnabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}