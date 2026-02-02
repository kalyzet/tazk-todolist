import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/academic_context.dart';
import '../services/task_service.dart';
import '../repositories/preferences_repository.dart';

/// Provider for managing task state and UI interactions
/// 
/// Handles:
/// - Task list state management
/// - Context switching with proper state updates
/// - Sorting functionality with preference persistence
/// - Loading states and error handling for UI feedback
/// 
/// Requirements: 6.5, 7.1, 7.2
class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;
  final PreferencesRepository _preferencesRepository;

  // State variables
  List<Task> _tasks = [];
  AcademicContext? _currentContext;
  String _currentSortBy = 'deadline';
  bool _isLoading = false;
  String? _errorMessage;

  // Constructor
  TaskProvider({
    TaskService? taskService,
    PreferencesRepository? preferencesRepository,
  }) : _taskService = taskService ?? TaskService(),
       _preferencesRepository = preferencesRepository ?? PreferencesRepository();

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  AcademicContext? get currentContext => _currentContext;
  String get currentSortBy => _currentSortBy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasContext => _currentContext != null;
  bool get hasTasks => _tasks.isNotEmpty;

  /// Initialize the provider by loading saved preferences and context
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      // Load saved sort preference
      _currentSortBy = await _preferencesRepository.getSortPreference();
      
      // Load saved context
      _currentContext = await _preferencesRepository.getLastContext();
      
      // If we have a context, load tasks for that context
      if (_currentContext != null) {
        await _loadTasksForCurrentContext();
      }
    } catch (e) {
      _setError('Gagal memuat data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Switch to a new academic context
  /// Requirements: 6.5 - Context switching functionality with proper state updates
  Future<void> switchContext(AcademicContext newContext) async {
    if (!newContext.isValid()) {
      _setError('Context tidak valid: ${newContext.displayName}');
      return;
    }

    // Don't reload if switching to the same context
    if (_currentContext == newContext) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Save the new context as last used
      final saved = await _preferencesRepository.saveLastContext(newContext);
      if (!saved) {
        _setError('Gagal menyimpan context');
        return;
      }

      // Update current context
      _currentContext = newContext;
      
      // Load tasks for the new context
      await _loadTasksForCurrentContext();
    } catch (e) {
      _setError('Gagal mengganti konteks: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Change sort preference and re-sort tasks
  /// Requirements: 7.1, 7.2 - Sorting functionality with preference persistence
  Future<void> changeSortBy(String sortBy) async {
    if (!PreferencesRepository.isValidSortOption(sortBy)) {
      _setError('Opsi sorting tidak valid: $sortBy');
      return;
    }

    // Don't re-sort if already using this sort option
    if (_currentSortBy == sortBy) {
      return;
    }

    try {
      // Save the new sort preference
      final saved = await _preferencesRepository.saveSortPreference(sortBy);
      if (!saved) {
        _setError('Gagal menyimpan preferensi sorting');
        return;
      }

      // Update current sort preference
      _currentSortBy = sortBy;
      
      // Re-sort current tasks
      _sortTasks();
      
      notifyListeners();
    } catch (e) {
      _setError('Gagal mengganti sorting: ${e.toString()}');
    }
  }

  /// Refresh tasks for the current context
  Future<void> refreshTasks() async {
    if (_currentContext == null) {
      _setError('Tidak ada context yang aktif');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _loadTasksForCurrentContext();
    } catch (e) {
      _setError('Gagal memuat ulang tasks: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new task to the current context
  Future<Task?> addTask(Task task) async {
    if (_currentContext == null) {
      _setError('Tidak ada context yang aktif');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      // Ensure task is assigned to current context
      final taskWithContext = task.copyWith(
        semester: _currentContext!.semester,
        period: _currentContext!.period,
      );

      // Create the task
      final createdTask = await _taskService.createTask(taskWithContext);
      
      // Add to local list and sort
      _tasks.add(createdTask);
      _sortTasks();
      
      notifyListeners();
      return createdTask;
    } catch (e) {
      _setError('Gagal menambah task: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing task
  Future<Task?> updateTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      // Update the task
      final updatedTask = await _taskService.updateTask(task);
      
      // Update in local list
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _sortTasks();
      }
      
      notifyListeners();
      return updatedTask;
    } catch (e) {
      _setError('Gagal mengupdate task: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a task
  Future<bool> deleteTask(int taskId) async {
    _setLoading(true);
    _clearError();

    try {
      // Delete the task
      await _taskService.deleteTask(taskId);
      
      // Remove from local list
      _tasks.removeWhere((task) => task.id == taskId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal menghapus task: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific task by ID
  Task? getTaskById(int taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Reset provider state (useful for testing)
  void reset() {
    _tasks.clear();
    _currentContext = null;
    _currentSortBy = 'deadline';
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper methods

  /// Load tasks for the current context
  Future<void> _loadTasksForCurrentContext() async {
    if (_currentContext == null) {
      _tasks.clear();
      notifyListeners();
      return;
    }

    try {
      _tasks = await _taskService.getTasksByContext(_currentContext!);
      _sortTasks();
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat tasks: ${e.toString()}');
      _tasks.clear();
      notifyListeners();
    }
  }

  /// Sort tasks based on current sort preference
  void _sortTasks() {
    switch (_currentSortBy) {
      case 'deadline':
        _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'progress':
        _tasks.sort((a, b) => a.progress.compareTo(b.progress));
        break;
      case 'course_name':
        _tasks.sort((a, b) => a.courseName.toLowerCase().compareTo(b.courseName.toLowerCase()));
        break;
      case 'task_name':
        _tasks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      default:
        // Default to deadline sorting
        _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Get available sort options with Indonesian labels
  static Map<String, String> get sortOptions => {
    'deadline': 'Deadline',
    'progress': 'Progress',
    'course_name': 'Mata Kuliah',
    'task_name': 'Nama Tugas',
  };

  /// Get Indonesian label for current sort option
  String get currentSortLabel => sortOptions[_currentSortBy] ?? 'Deadline';

  /// Get task statistics for current context
  Map<String, int> get taskStats {
    if (_tasks.isEmpty) {
      return {
        'total': 0,
        'completed': 0,
        'in_progress': 0,
        'overdue': 0,
      };
    }

    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    
    int completed = 0;
    int overdue = 0;
    
    for (final task in _tasks) {
      if (task.progress == 100) {
        completed++;
      } else {
        final deadlineDate = DateTime(task.deadline.year, task.deadline.month, task.deadline.day);
        if (deadlineDate.isBefore(currentDate)) {
          overdue++;
        }
      }
    }

    return {
      'total': _tasks.length,
      'completed': completed,
      'in_progress': _tasks.length - completed - overdue,
      'overdue': overdue,
    };
  }
}