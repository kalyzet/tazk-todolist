import 'dart:convert';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class BackupService {
  final TaskRepository _taskRepository = TaskRepository();
  
  /// Export all tasks to JSON format
  /// Returns a JSON string containing all task data with metadata
  Future<String> exportToJson() async {
    try {
      final tasks = await _taskRepository.findAll();
      
      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      throw Exception('Failed to export tasks: $e');
    }
  }
  
  /// Import tasks from JSON format with validation and deduplication
  /// Returns the number of tasks successfully imported
  Future<int> importFromJson(String jsonData) async {
    try {
      // Validate JSON format first
      if (!validateJsonFormat(jsonData)) {
        throw FormatException('Invalid JSON format for task import');
      }
      
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      final List<dynamic> tasksJson = importData['tasks'] as List<dynamic>;
      
      // Get existing tasks for deduplication
      final existingTasks = await _taskRepository.findAll();
      final existingTaskKeys = existingTasks.map((task) => _generateTaskKey(task)).toSet();
      
      int importedCount = 0;
      
      for (final taskJson in tasksJson) {
        try {
          final task = Task.fromJson(taskJson as Map<String, dynamic>);
          
          // Skip if task already exists (deduplication)
          final taskKey = _generateTaskKey(task);
          if (existingTaskKeys.contains(taskKey)) {
            continue; // Skip duplicate task
          }
          
          // Validate task before importing
          if (!task.isValid()) {
            continue; // Skip invalid tasks
          }
          
          // Create new task without ID to let database auto-generate
          final newTask = Task(
            name: task.name,
            courseName: task.courseName,
            instructorName: task.instructorName,
            deadline: task.deadline,
            semester: task.semester,
            period: task.period,
            progress: task.progress,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(), // Update timestamp for import
          );
          
          await _taskRepository.insert(newTask);
          
          // Add the new task key to existing keys to prevent duplicates within the same import
          existingTaskKeys.add(taskKey);
          importedCount++;
          
        } catch (e) {
          // Skip individual task if it fails to parse or insert
          continue;
        }
      }
      
      return importedCount;
      
    } catch (e) {
      throw Exception('Failed to import tasks: $e');
    }
  }
  
  /// Validate JSON format for import data integrity
  /// Returns true if JSON format is valid for task import
  bool validateJsonFormat(String jsonData) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      
      // Check required top-level fields
      if (!data.containsKey('version') || !data.containsKey('tasks')) {
        return false;
      }
      
      // Validate version is a string
      if (data['version'] is! String) {
        return false;
      }
      
      // Validate tasks is a list
      if (data['tasks'] is! List) {
        return false;
      }
      
      final List<dynamic> tasks = data['tasks'] as List<dynamic>;
      
      // Validate each task has required fields
      for (final taskData in tasks) {
        if (taskData is! Map<String, dynamic>) {
          return false;
        }
        
        final Map<String, dynamic> task = taskData as Map<String, dynamic>;
        
        // Check required task fields
        final requiredFields = [
          'name',
          'course_name',
          'instructor_name',
          'deadline',
          'semester',
          'period',
          'progress',
          'created_at',
          'updated_at',
        ];
        
        for (final field in requiredFields) {
          if (!task.containsKey(field)) {
            return false;
          }
        }
        
        // Validate field types
        if (task['name'] is! String ||
            task['course_name'] is! String ||
            task['instructor_name'] is! String ||
            task['deadline'] is! String ||
            task['semester'] is! String ||
            task['period'] is! String ||
            task['progress'] is! int ||
            task['created_at'] is! String ||
            task['updated_at'] is! String) {
          return false;
        }
        
        // Validate date strings can be parsed
        try {
          DateTime.parse(task['deadline'] as String);
          DateTime.parse(task['created_at'] as String);
          DateTime.parse(task['updated_at'] as String);
        } catch (e) {
          return false;
        }
        
        // Validate progress range
        final int progress = task['progress'] as int;
        if (progress < 0 || progress > 100) {
          return false;
        }
        
        // Validate period value
        final String period = task['period'] as String;
        if (period != 'UTS' && period != 'UAS') {
          return false;
        }
      }
      
      return true;
      
    } catch (e) {
      return false;
    }
  }
  
  /// Generate a unique key for task deduplication
  /// Uses combination of name, course, instructor, deadline, semester, and period
  String _generateTaskKey(Task task) {
    return '${task.name}|${task.courseName}|${task.instructorName}|'
           '${task.deadline.toIso8601String()}|${task.semester}|${task.period}';
  }
}