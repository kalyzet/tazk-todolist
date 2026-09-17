import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/date_formatter.dart';

/// Task editing screen with comprehensive update functionality
/// 
/// Features:
/// - Task update form with pre-filled values
/// - Progress slider with 0-100% range validation
/// - Notification rescheduling on deadline/progress changes
/// - Delete functionality with confirmation dialog
/// 
/// Requirements: 4.1, 4.2, 4.5, 9.4
class TaskEditingScreen extends StatefulWidget {
  final Task task;

  const TaskEditingScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskEditingScreen> createState() => _TaskEditingScreenState();
}

class _TaskEditingScreenState extends State<TaskEditingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _instructorController = TextEditingController();
  
  DateTime? _selectedDeadline;
  String? _selectedSemester;
  String? _selectedPeriod;
  double _progress = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _nameController.text = widget.task.name;
    _courseController.text = widget.task.courseName;
    _instructorController.text = widget.task.instructorName;
    _selectedDeadline = widget.task.deadline;
    _selectedSemester = widget.task.semester;
    _selectedPeriod = widget.task.period;
    _progress = widget.task.progress.toDouble();
  }

  Future<void> _selectDeadline() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? tomorrow,
      firstDate: tomorrow,
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
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
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

  Future<void> _selectSemester() async {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.selectSemesterTitle),
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
            child: Text(l10n.cancel),
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

  Future<void> _selectPeriod() async {
    final l10n = AppLocalizations.of(context)!;
    final periods = [
      {'value': 'UTS', 'label': l10n.utsLong},
      {'value': 'UAS', 'label': l10n.uasLong},
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectPeriodTitle),
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
            child: Text(l10n.cancel),
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

  Future<void> _showDeleteConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text(l10n.deleteTaskConfirm(widget.task.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTask();
    }
  }

  Future<void> _deleteTask() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final success = await taskProvider.deleteTask(widget.task.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskDeletedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted && taskProvider.errorMessage != null) {
          _showErrorSnackBar(taskProvider.errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${l10n.taskDeletedError}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    if (_progress < 0 || _progress > 100) {
      _showErrorSnackBar(l10n.progressRangeError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = widget.task.copyWith(
        name: _nameController.text.trim(),
        courseName: _courseController.text.trim(),
        instructorName: _instructorController.text.trim(),
        deadline: _selectedDeadline!,
        semester: _selectedSemester!,
        period: _selectedPeriod!,
        progress: _progress.round(),
      );

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final result = await taskProvider.updateTask(updatedTask);

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskUpdatedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted && taskProvider.errorMessage != null) {
          _showErrorSnackBar(taskProvider.errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('${l10n.taskUpdatedError}: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    return IndonesianDateFormatter.formatLong(deadline);
  }

  String _getProgressStatusText() {
    final l10n = AppLocalizations.of(context)!;
    if (_progress == 100) {
      return l10n.completed;
    } else if (_progress >= 75) {
      return l10n.almostDone;
    } else if (_progress >= 50) {
      return l10n.halfWay;
    } else if (_progress >= 25) {
      return l10n.inProgress;
    } else if (_progress > 0) {
      return l10n.justStarted;
    } else {
      return l10n.notStarted;
    }
  }

  Color _getProgressColor() {
    if (_progress == 100) {
      return Colors.green;
    } else if (_progress >= 75) {
      return Colors.lightGreen;
    } else if (_progress >= 50) {
      return Colors.orange;
    } else if (_progress >= 25) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editTask),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _showDeleteConfirmation,
            icon: const Icon(Icons.delete),
            tooltip: l10n.deleteTask,
          ),
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
            // Progress section
            Container(
              padding: const EdgeInsets.all(16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.taskProgress,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getProgressColor(),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getProgressStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Text(
                        '0%',
                        style: theme.textTheme.bodySmall,
                      ),
                      Expanded(
                        child: Slider(
                          value: _progress,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${_progress.round()}%',
                          onChanged: _isLoading ? null : (value) {
                            setState(() {
                              _progress = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        '100%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  Center(
                    child: Text(
                      '${_progress.round()}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
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
                  labelText: '${l10n.deadline} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.schedule),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedDeadline == null
                      ? l10n.selectDeadlineHint
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
                  labelText: '${l10n.semester} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.school),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedSemester ?? l10n.selectSemesterHint,
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
                  labelText: '${l10n.periodLabel} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedPeriod == null
                      ? l10n.selectPeriodHint
                      : _selectedPeriod == 'UTS'
                          ? l10n.utsLong
                          : l10n.uasLong,
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
                      l10n.progressUpdateInfo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Update button
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
                    : Text(l10n.updateTask),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
