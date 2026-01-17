import '../models/task.dart';
import '../models/academic_context.dart';
import '../repositories/task_repository.dart';

/// Service class for managing tasks with business logic and validation
class TaskService {
  final TaskRepository _taskRepository;

  TaskService({TaskRepository? taskRepository})
      : _taskRepository = taskRepository ?? TaskRepository();

  /// Creates a new task with validation and automatic progress initialization
  /// 
  /// Requirements: 3.2, 3.4, 3.5
  /// - Validates all required fields are not empty (3.1, 3.3)
  /// - Initializes progress to 0% automatically (3.2)
  /// - Prevents creation of tasks with past deadlines (3.5)
  /// - Stores task in SQLite database (3.4)
  Future<Task> createTask(Task task) async {
    // Validate required fields are not empty
    if (!task.validateRequiredFields()) {
      throw ArgumentError('Semua field wajib harus diisi');
    }

    // Validate period is UTS or UAS
    if (!task.validatePeriod()) {
      throw ArgumentError('Period harus UTS atau UAS');
    }

    // Validate deadline is not in the past
    if (!task.validateDeadlineNotPast()) {
      throw ArgumentError('Deadline tidak boleh di masa lalu');
    }

    // Ensure progress is initialized to 0% for new tasks
    final newTask = task.copyWith(
      progress: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Validate progress range (should be 0 for new tasks)
    if (!newTask.validateProgressRange()) {
      throw ArgumentError('Progress harus antara 0-100%');
    }

    // Insert task into database
    final taskId = await _taskRepository.insert(newTask);
    
    // Return the created task with the generated ID
    return newTask.copyWith(id: taskId);
  }

  /// Updates an existing task with notification rescheduling logic
  /// 
  /// Requirements: 4.2
  /// - Validates progress range (0-100)
  /// - Automatically marks task as completed when progress reaches 100%
  /// - Updates task in database
  /// - Handles notification rescheduling (will be implemented when NotificationService is available)
  Future<Task> updateTask(Task task) async {
    if (task.id == null) {
      throw ArgumentError('Task ID tidak boleh null untuk update');
    }

    // Validate required fields
    if (!task.validateRequiredFields()) {
      throw ArgumentError('Semua field wajib harus diisi');
    }

    // Validate period
    if (!task.validatePeriod()) {
      throw ArgumentError('Period harus UTS atau UAS');
    }

    // Validate progress range
    if (!task.validateProgressRange()) {
      throw ArgumentError('Progress harus antara 0-100%');
    }

    // Create updated task with current timestamp
    final updatedTask = task.copyWith(
      updatedAt: DateTime.now(),
    );

    // Update task in database
    final rowsAffected = await _taskRepository.update(updatedTask);
    
    if (rowsAffected == 0) {
      throw StateError('Task dengan ID ${task.id} tidak ditemukan');
    }

    // TODO: Handle notification rescheduling when NotificationService is implemented
    // - Cancel existing notifications for this task
    // - Reschedule notifications if progress < 100% and deadline is in future
    
    return updatedTask;
  }

  /// Deletes a task with notification cleanup
  /// 
  /// Requirements: Task deletion with proper cleanup
  /// - Removes task from database
  /// - Handles notification cleanup (will be implemented when NotificationService is available)
  Future<void> deleteTask(int taskId) async {
    // Check if task exists
    final existingTask = await _taskRepository.findById(taskId);
    if (existingTask == null) {
      throw StateError('Task dengan ID $taskId tidak ditemukan');
    }

    // TODO: Cancel all notifications for this task when NotificationService is implemented
    
    // Delete task from database
    final rowsAffected = await _taskRepository.delete(taskId);
    
    if (rowsAffected == 0) {
      throw StateError('Gagal menghapus task dengan ID $taskId');
    }
  }

  /// Retrieves tasks filtered by academic context
  /// 
  /// Requirements: 6.4
  /// - Returns tasks matching the specified semester and period
  /// - Orders tasks by deadline (earliest first)
  Future<List<Task>> getTasksByContext(AcademicContext context) async {
    // Validate context
    if (!context.isValid()) {
      throw ArgumentError('Context tidak valid: semester dan period harus diisi dengan benar');
    }

    // Retrieve tasks from repository
    return await _taskRepository.findByContext(context.semester, context.period);
  }

  /// Retrieves a specific task by ID
  Future<Task?> getTaskById(int taskId) async {
    return await _taskRepository.findById(taskId);
  }

  /// Retrieves all tasks (used for backup operations)
  Future<List<Task>> getAllTasks() async {
    return await _taskRepository.findAll();
  }

  /// Retrieves tasks with upcoming deadlines (within specified days)
  Future<List<Task>> getUpcomingTasks(int daysAhead) async {
    if (daysAhead < 0) {
      throw ArgumentError('Days ahead harus >= 0');
    }
    
    return await _taskRepository.findUpcomingDeadlines(daysAhead);
  }

  /// Retrieves overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    return await _taskRepository.findOverdueTasks();
  }

  /// Counts total tasks
  Future<int> getTaskCount() async {
    return await _taskRepository.count();
  }

  /// Counts tasks by context
  Future<int> getTaskCountByContext(AcademicContext context) async {
    if (!context.isValid()) {
      throw ArgumentError('Context tidak valid');
    }
    
    return await _taskRepository.countByContext(context.semester, context.period);
  }

  /// Validates if a task can be created (used for validation before UI submission)
  bool canCreateTask(Task task) {
    return task.validateRequiredFields() &&
           task.validatePeriod() &&
           task.validateDeadlineNotPast();
  }

  /// Validates if a task can be updated (used for validation before UI submission)
  bool canUpdateTask(Task task) {
    return task.id != null &&
           task.validateRequiredFields() &&
           task.validatePeriod() &&
           task.validateProgressRange();
  }
}