import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../models/academic_context.dart';
import '../../providers/task_provider.dart';
import '../../utils/date_formatter.dart';

/// Task creation screen with comprehensive form validation
/// 
/// Features:
/// - Form with all required fields (name, course, instructor, deadline)
/// - Date picker with past date validation
/// - Semester and period selection with current context default
/// - Form validation with Indonesian error messages
/// 
/// Requirements: 3.1, 3.3, 3.5, 11.3
class TaskCreationScreen extends StatefulWidget {
  const TaskCreationScreen({super.key});

  @override
  State<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _instructorController = TextEditingController();
  
  DateTime? _selectedDeadline;
  String? _selectedSemester;
  String? _selectedPeriod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  /// Initialize form with current context defaults
  void _initializeDefaults() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (taskProvider.hasContext) {
      _selectedSemester = taskProvider.currentContext!.semester;
      _selectedPeriod = taskProvider.currentContext!.period;
    }
  }

  /// Show date picker for deadline selection
  Future<void> _selectDeadline() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? tomorrow,
      firstDate: tomorrow, // Prevent past date selection
      lastDate: DateTime(now.year + 2),
      locale: const Locale('id', ''),
      helpText: l10n.pickDeadlineDate,
      cancelText: l10n.cancel,
      confirmText: l10n.choose,
      fieldLabelText: l10n.dateFieldLabel,
      fieldHintText: l10n.dateFieldHint,
      errorFormatText: l10n.invalidDateFormat,
      errorInvalidText: l10n.invalidDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Show time picker for more precise deadline
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
        helpText: l10n.pickDeadlineTime,
        cancelText: l10n.cancel,
        confirmText: l10n.choose,
        hourLabelText: l10n.hour,
        minuteLabelText: l10n.minute,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  /// Show semester selection dialog
  Future<void> _selectSemester() async {
    final semesters = [
      'Semester 1',
      'Semester 2',
      'Semester 3',
      'Semester 4',
      'Semester 5',
      'Semester 6',
      'Semester 7',
      'Semester 8',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Semester'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: semesters.length,
            itemBuilder: (context, index) {
              final semester = semesters[index];
              return ListTile(
                title: Text(semester),
                selected: semester == _selectedSemester,
                onTap: () => Navigator.of(context).pop(semester),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedSemester = selected;
      });
    }
  }

  /// Show period selection dialog
  Future<void> _selectPeriod() async {
    final periods = [
      {'value': 'UTS', 'label': 'UTS (Ujian Tengah Semester)'},
      {'value': 'UAS', 'label': 'UAS (Ujian Akhir Semester)'},
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Periode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: periods.map((period) {
            return ListTile(
              title: Text(period['label']!),
              selected: period['value'] == _selectedPeriod,
              onTap: () => Navigator.of(context).pop(period['value']),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedPeriod = selected;
      });
    }
  }

  /// Validate and submit the form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for required selections
    if (_selectedDeadline == null) {
      _showErrorSnackBar(l10n.deadlineRequired);
      return;
    }

    if (_selectedSemester == null || _selectedSemester!.isEmpty) {
      _showErrorSnackBar(l10n.semesterRequired);
      return;
    }

    if (_selectedPeriod == null || _selectedPeriod!.isEmpty) {
      _showErrorSnackBar(l10n.periodRequired);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create task object
      final task = Task(
        name: _nameController.text.trim(),
        courseName: _courseController.text.trim(),
        instructorName: _instructorController.text.trim(),
        deadline: _selectedDeadline!,
        semester: _selectedSemester!,
        period: _selectedPeriod!,
      );

      // Add task through provider
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final createdTask = await taskProvider.addTask(task);

      if (createdTask != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskAddedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to task list
          Navigator.of(context).pop();
        }
      } else {
        // Show error from provider
        if (mounted && taskProvider.errorMessage != null) {
          _showErrorSnackBar(taskProvider.errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${l10n.taskAddedError}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show error message in snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Format deadline for display
  String _formatDeadline(DateTime deadline) {
    return IndonesianDateFormatter.formatLong(deadline);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addNewTask),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Task name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${l10n.taskName} *',
                hintText: l10n.taskNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.assignment),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.taskNameRequired;
                }
                if (value.trim().length < 3) {
                  return l10n.taskNameMinLength;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Course name field
            TextFormField(
              controller: _courseController,
              decoration: InputDecoration(
                labelText: '${l10n.courseName} *',
                hintText: l10n.courseNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.book),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.courseNameRequired;
                }
                if (value.trim().length < 2) {
                  return l10n.courseNameMinLength;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Instructor name field
            TextFormField(
              controller: _instructorController,
              decoration: InputDecoration(
                labelText: '${l10n.instructorName} *',
                hintText: l10n.instructorNameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.instructorNameRequired;
                }
                if (value.trim().length < 2) {
                  return l10n.instructorNameMinLength;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Deadline selection
            InkWell(
              onTap: _isLoading ? null : _selectDeadline,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Batas Waktu *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.schedule),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: _selectedDeadline == null ? null : null,
                ),
                child: Text(
                  _selectedDeadline == null
                      ? 'Pilih batas waktu tugas'
                      : _formatDeadline(_selectedDeadline!),
                  style: TextStyle(
                    color: _selectedDeadline == null
                        ? theme.hintColor
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Semester selection
            InkWell(
              onTap: _isLoading ? null : _selectSemester,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Semester *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.school),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: _selectedSemester == null ? null : null,
                ),
                child: Text(
                  _selectedSemester ?? 'Pilih semester',
                  style: TextStyle(
                    color: _selectedSemester == null
                        ? theme.hintColor
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Period selection
            InkWell(
              onTap: _isLoading ? null : _selectPeriod,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Periode *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: _selectedPeriod == null ? null : null,
                ),
                child: Text(
                  _selectedPeriod == null
                      ? 'Pilih periode'
                      : _selectedPeriod == 'UTS'
                          ? 'UTS (Ujian Tengah Semester)'
                          : 'UAS (Ujian Akhir Semester)',
                  style: TextStyle(
                    color: _selectedPeriod == null
                        ? theme.hintColor
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primaryContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tugas baru akan dimulai dengan progres 0% dan dapat diperbarui nanti.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Tambah Tugas'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}