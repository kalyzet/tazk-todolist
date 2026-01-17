import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/task.dart';

class TaskRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  /// Insert a new task into the database
  Future<int> insert(Task task) async {
    final db = await _databaseHelper.database;
    
    // Create a copy without the id for insertion
    final taskMap = task.toMap();
    taskMap.remove('id'); // Remove id to let SQLite auto-generate it
    
    return await db.insert(
      DatabaseHelper.tasksTable,
      taskMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Update an existing task in the database
  Future<int> update(Task task) async {
    final db = await _databaseHelper.database;
    
    if (task.id == null) {
      throw ArgumentError('Task ID cannot be null for update operation');
    }
    
    return await db.update(
      DatabaseHelper.tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }
  
  /// Delete a task from the database
  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;
    
    return await db.delete(
      DatabaseHelper.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Find a task by its ID
  Future<Task?> findById(int id) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Task.fromMap(maps.first);
  }
  
  /// Find tasks by academic context (semester and period)
  Future<List<Task>> findByContext(String semester, String period) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tasksTable,
      where: 'semester = ? AND period = ?',
      whereArgs: [semester, period],
      orderBy: 'deadline ASC', // Order by deadline using ISO-8601 format for proper sorting
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  /// Find all tasks (used for backup operations)
  Future<List<Task>> findAll() async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tasksTable,
      orderBy: 'created_at DESC', // Order by creation date, newest first
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  /// Find tasks by semester only (useful for context switching)
  Future<List<Task>> findBySemester(String semester) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tasksTable,
      where: 'semester = ?',
      whereArgs: [semester],
      orderBy: 'deadline ASC',
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  /// Find tasks by period only
  Future<List<Task>> findByPeriod(String period) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tasksTable,
      where: 'period = ?',
      whereArgs: [period],
      orderBy: 'deadline ASC',
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  /// Find tasks with upcoming deadlines (within specified days)
  Future<List<Task>> findUpcomingDeadlines(int daysAhead) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tasksTable,
      where: 'deadline <= ? AND deadline >= ? AND progress < 100',
      whereArgs: [
        futureDate.toIso8601String(),
        now.toIso8601String(),
      ],
      orderBy: 'deadline ASC',
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  /// Find overdue tasks (deadline has passed and progress < 100%)
  Future<List<Task>> findOverdueTasks() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tasksTable,
      where: 'deadline < ? AND progress < 100',
      whereArgs: [now.toIso8601String()],
      orderBy: 'deadline ASC',
    );
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }
  
  /// Count total tasks
  Future<int> count() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tasksTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Count tasks by context
  Future<int> countByContext(String semester, String period) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.tasksTable} WHERE semester = ? AND period = ?',
      [semester, period],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Clear all tasks (useful for testing)
  Future<void> clear() async {
    final db = await _databaseHelper.database;
    await db.delete(DatabaseHelper.tasksTable);
  }
}