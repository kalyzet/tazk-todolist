class Task {
  int? id;
  String name;
  String courseName;
  String instructorName;
  DateTime deadline;
  String semester;
  String period; // 'UTS' or 'UAS'
  int progress; // 0-100
  DateTime createdAt;
  DateTime updatedAt;

  Task({
    this.id,
    required this.name,
    required this.courseName,
    required this.instructorName,
    required this.deadline,
    required this.semester,
    required this.period,
    this.progress = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Validates all required fields are not empty
  bool validateRequiredFields() {
    return name.trim().isNotEmpty &&
           courseName.trim().isNotEmpty &&
           instructorName.trim().isNotEmpty &&
           semester.trim().isNotEmpty &&
           period.trim().isNotEmpty;
  }

  /// Validates progress is within 0-100 range
  bool validateProgressRange() {
    return progress >= 0 && progress <= 100;
  }

  /// Validates period is either 'UTS' or 'UAS'
  bool validatePeriod() {
    return period == 'UTS' || period == 'UAS';
  }

  /// Validates deadline is not in the past
  bool validateDeadlineNotPast() {
    final now = DateTime.now();
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final currentDate = DateTime(now.year, now.month, now.day);
    return deadlineDate.isAfter(currentDate) || deadlineDate.isAtSameMomentAs(currentDate);
  }

  /// Validates all task fields
  bool isValid() {
    return validateRequiredFields() &&
           validateProgressRange() &&
           validatePeriod() &&
           validateDeadlineNotPast();
  }

  /// Creates a copy of this task with updated fields
  Task copyWith({
    int? id,
    String? name,
    String? courseName,
    String? instructorName,
    DateTime? deadline,
    String? semester,
    String? period,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      courseName: courseName ?? this.courseName,
      instructorName: instructorName ?? this.instructorName,
      deadline: deadline ?? this.deadline,
      semester: semester ?? this.semester,
      period: period ?? this.period,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts Task to JSON Map using ISO-8601 date format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'course_name': courseName,
      'instructor_name': instructorName,
      'deadline': deadline.toIso8601String(),
      'semester': semester,
      'period': period,
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates Task from JSON Map, parsing ISO-8601 date strings
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      name: json['name'] as String,
      courseName: json['course_name'] as String,
      instructorName: json['instructor_name'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      semester: json['semester'] as String,
      period: json['period'] as String,
      progress: json['progress'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts Task to database Map using ISO-8601 date format
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'course_name': courseName,
      'instructor_name': instructorName,
      'deadline': deadline.toIso8601String(),
      'semester': semester,
      'period': period,
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates Task from database Map, parsing ISO-8601 date strings
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      name: map['name'] as String,
      courseName: map['course_name'] as String,
      instructorName: map['instructor_name'] as String,
      deadline: DateTime.parse(map['deadline'] as String),
      semester: map['semester'] as String,
      period: map['period'] as String,
      progress: map['progress'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
           other.id == id &&
           other.name == name &&
           other.courseName == courseName &&
           other.instructorName == instructorName &&
           other.deadline == deadline &&
           other.semester == semester &&
           other.period == period &&
           other.progress == progress &&
           other.createdAt == createdAt &&
           other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      courseName,
      instructorName,
      deadline,
      semester,
      period,
      progress,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, name: $name, courseName: $courseName, '
           'instructorName: $instructorName, deadline: $deadline, '
           'semester: $semester, period: $period, progress: $progress, '
           'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}