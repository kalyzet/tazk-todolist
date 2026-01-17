import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = 'academic_task_manager.db';
  static const int _databaseVersion = 1;
  
  // Table names
  static const String tasksTable = 'tasks';
  
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  
  static Database? _database;
  
  // Test database support
  static String? _testDatabaseName;
  
  /// Get database instance, creating it if it doesn't exist
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  /// Set test database name for test isolation
  static void setTestDatabaseName(String? testName) {
    _testDatabaseName = testName;
    _database = null; // Force recreation with new name
  }
  
  /// Initialize the database with proper schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbName = _testDatabaseName ?? _databaseName;
    final path = join(databasesPath, dbName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  /// Create database tables and indexes
  Future<void> _onCreate(Database db, int version) async {
    // Create tasks table with proper schema
    await db.execute('''
      CREATE TABLE $tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        course_name TEXT NOT NULL,
        instructor_name TEXT NOT NULL,
        deadline TEXT NOT NULL,
        semester TEXT NOT NULL,
        period TEXT NOT NULL CHECK (period IN ('UTS', 'UAS')),
        progress INTEGER NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Create composite index on (semester, period) for efficient context filtering
    await db.execute('''
      CREATE INDEX idx_tasks_context ON $tasksTable (semester, period)
    ''');
    
    // Create index on deadline for sorting and deadline calculations
    await db.execute('''
      CREATE INDEX idx_tasks_deadline ON $tasksTable (deadline)
    ''');
  }
  
  /// Handle database migrations for future schema changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic will be added here for future schema changes
    // For now, we only have version 1, so no migrations needed
    
    if (oldVersion < 2) {
      // Example migration for future version 2:
      // await db.execute('ALTER TABLE $tasksTable ADD COLUMN new_field TEXT');
    }
  }
  
  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
  
  /// Delete the database (useful for testing)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbName = _testDatabaseName ?? _databaseName;
    final path = join(databasesPath, dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
  
  /// Get database path (useful for debugging)
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    final dbName = _testDatabaseName ?? _databaseName;
    return join(databasesPath, dbName);
  }
}