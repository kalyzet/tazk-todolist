import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/academic_context.dart';

/// Initial setup screen for new users to select semester and period
/// 
/// Features:
/// - Semester selection interface
/// - Period selection (UTS/UAS) with Indonesian terminology
/// - Validation for context selection completeness
/// - Navigation to task list after setup
/// - Indonesian localization for all UI elements
/// 
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 11.1, 11.2
class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  String? _selectedSemester;
  String? _selectedPeriod;
  String? _semesterError;
  String? _periodError;

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

  /// Handles the continue button press
  void _onContinue() {
    if (!_validateForm()) {
      return;
    }

    // Create academic context
    final academicContext = AcademicContext(
      semester: _selectedSemester!,
      period: _selectedPeriod!,
    );

    // Navigate to task list with the selected context
    Navigator.of(context).pushReplacementNamed(
      '/task-list',
      arguments: academicContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              
              // Title and subtitle
              Text(
                l10n.setupTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Semester selection
              Text(
                l10n.selectSemester,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                decoration: InputDecoration(
                  hintText: l10n.selectSemester,
                  errorText: _semesterError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _semesterOptions.map((semester) {
                  return DropdownMenuItem<String>(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value;
                    _semesterError = null;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Period selection
              Text(
                l10n.selectPeriod,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Period selection cards
              Row(
                children: [
                  Expanded(
                    child: _PeriodSelectionCard(
                      title: l10n.uts,
                      subtitle: l10n.utsLong,
                      value: 'UTS',
                      selectedValue: _selectedPeriod,
                      onSelected: (value) {
                        setState(() {
                          _selectedPeriod = value;
                          _periodError = null;
                        });
                      },
                      hasError: _periodError != null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PeriodSelectionCard(
                      title: l10n.uas,
                      subtitle: l10n.uasLong,
                      value: 'UAS',
                      selectedValue: _selectedPeriod,
                      onSelected: (value) {
                        setState(() {
                          _selectedPeriod = value;
                          _periodError = null;
                        });
                      },
                      hasError: _periodError != null,
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
              
              const Spacer(),
              
              // Continue button
              FilledButton(
                onPressed: _onContinue,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.continueButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom widget for period selection cards
class _PeriodSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String? selectedValue;
  final ValueChanged<String> onSelected;
  final bool hasError;

  const _PeriodSelectionCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedValue == value;
    
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError
                ? theme.colorScheme.error
                : isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}