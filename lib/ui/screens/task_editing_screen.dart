import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../models/academic_context.dart';
import '../../providers/task_provider.dart';

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

  /// Initialize form with existing task values
  void _initializeForm() {
    _nameController.text = widget.task.name;
    _courseController.text = widget.task.courseName;
    _instructorController.text = widget.task.instructorName;
    _selectedDeadline = widget.task.deadline;
    _selectedSemester = widget.task.semester;
    _selectedPeriod = widget.task.period;
    _progress = widget.task.progress.toDouble();
  }

  /// Show date picker for deadline selection
  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? tomorrow,
      firstDate: tomorrow, // Prevent past date selection for new deadlines
      lastDate: DateTime(now.year + 2),
      locale: const Locale('id', ''),
      helpText: 'Pilih Batas Waktu',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      fieldLabelText: 'Tanggal Deadline',
      fieldHintText: 'dd/mm/yyyy',
      errorFormatText: 'Format tanggal tidak valid',
      errorInvalidText: 'Tanggal tidak valid',
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
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
        helpText: 'Pilih Waktu Deadline',
        cancelText: 'Batal',
        confirmText: 'Pilih',
        hourLabelText: 'Jam',
        minuteLabelText: 'Menit',
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

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: Text(
          'Apakah Anda yakin ingin menghapus tugas "${widget.task.name}"?\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTask();
    }
  }

  /// Delete the task
  Future<void> _deleteTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final success = await taskProvider.deleteTask(widget.task.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to task list
          Navigator.of(context).pop();
        }
      } else {
        if (mounted && taskProvider.errorMessage != null) {
          _showErrorSnackBar(taskProvider.errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal menghapus tugas: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Validate and submit the form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for required selections
    if (_selectedDeadline == null) {
      _showErrorSnackBar('Silakan pilih batas waktu tugas');
      return;
    }

    if (_selectedSemester == null || _selectedSemester!.isEmpty) {
      _showErrorSnackBar('Silakan pilih semester');
      return;
    }

    if (_selectedPeriod == null || _selectedPeriod!.isEmpty) {
      _showErrorSnackBar('Silakan pilih periode');
      return;
    }

    // Validate progress range (0-100)
    if (_progress < 0 || _progress > 100) {
      _showErrorSnackBar('Progres harus antara 0-100%');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated task object
      final updatedTask = widget.task.copyWith(
        name: _nameController.text.trim(),
        courseName: _courseController.text.trim(),
        instructorName: _instructorController.text.trim(),
        deadline: _selectedDeadline!,
        semester: _selectedSemester!,
        period: _selectedPeriod!,
        progress: _progress.round(),
      );

      // Update task through provider
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final result = await taskProvider.updateTask(updatedTask);

      if (result != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil diperbarui'),
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
        _showErrorSnackBar('Gagal memperbarui tugas: ${e.toString()}');
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
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final day = deadline.day.toString().padLeft(2, '0');
    final month = months[deadline.month - 1];
    final year = deadline.year;
    final hour = deadline.hour.toString().padLeft(2, '0');
    final minute = deadline.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  /// Get progress status text
  String _getProgressStatusText() {
    if (_progress == 100) {
      return 'Selesai';
    } else if (_progress >= 75) {
      return 'Hampir Selesai';
    } else if (_progress >= 50) {
      return 'Setengah Jalan';
    } else if (_progress >= 25) {
      return 'Dalam Progres';
    } else if (_progress > 0) {
      return 'Baru Dimulai';
    } else {
      return 'Belum Dimulai';
    }
  }

  /// Get progress color based on value
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tugas'),
        actions: [
          // Delete button
          IconButton(
            onPressed: _isLoading ? null : _showDeleteConfirmation,
            icon: const Icon(Icons.delete),
            tooltip: 'Hapus Tugas',
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
                        'Progres Tugas',
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
                  
                  // Progress slider
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
                          divisions: 20, // 5% increments
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
                  
                  // Progress percentage display
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
              decoration: const InputDecoration(
                labelText: 'Nama Tugas *',
                hintText: 'Masukkan nama tugas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tugas tidak boleh kosong';
                }
                if (value.trim().length < 3) {
                  return 'Nama tugas minimal 3 karakter';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Course name field
            TextFormField(
              controller: _courseController,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah *',
                hintText: 'Masukkan nama mata kuliah',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mata kuliah tidak boleh kosong';
                }
                if (value.trim().length < 2) {
                  return 'Mata kuliah minimal 2 karakter';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Instructor name field
            TextFormField(
              controller: _instructorController,
              decoration: const InputDecoration(
                labelText: 'Nama Dosen *',
                hintText: 'Masukkan nama dosen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama dosen tidak boleh kosong';
                }
                if (value.trim().length < 2) {
                  return 'Nama dosen minimal 2 karakter';
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
                      'Perubahan pada deadline atau progres akan memperbarui notifikasi secara otomatis.',
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
                    : const Text('Perbarui Tugas'),
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