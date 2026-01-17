class AcademicContext {
  String semester;
  String period;

  AcademicContext({
    required this.semester,
    required this.period,
  });

  /// Validates that semester is not empty
  bool validateSemester() {
    return semester.trim().isNotEmpty;
  }

  /// Validates that period is either 'UTS' or 'UAS'
  bool validatePeriod() {
    return period == 'UTS' || period == 'UAS';
  }

  /// Validates both semester and period
  bool isValid() {
    return validateSemester() && validatePeriod();
  }

  /// Returns Indonesian display name for the context
  String get displayName => '$semester - $period';

  /// Returns Indonesian formatted display name with full terminology
  String get indonesianDisplayName {
    final periodName = period == 'UTS' ? 'Ujian Tengah Semester' : 'Ujian Akhir Semester';
    return '$semester - $periodName';
  }

  /// Creates a copy of this context with updated fields
  AcademicContext copyWith({
    String? semester,
    String? period,
  }) {
    return AcademicContext(
      semester: semester ?? this.semester,
      period: period ?? this.period,
    );
  }

  /// Converts AcademicContext to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'semester': semester,
      'period': period,
    };
  }

  /// Creates AcademicContext from JSON Map
  factory AcademicContext.fromJson(Map<String, dynamic> json) {
    return AcademicContext(
      semester: json['semester'] as String,
      period: json['period'] as String,
    );
  }

  /// Converts AcademicContext to Map for SharedPreferences storage
  Map<String, dynamic> toMap() {
    return {
      'semester': semester,
      'period': period,
    };
  }

  /// Creates AcademicContext from Map (SharedPreferences)
  factory AcademicContext.fromMap(Map<String, dynamic> map) {
    return AcademicContext(
      semester: map['semester'] as String,
      period: map['period'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AcademicContext &&
           other.semester == semester &&
           other.period == period;
  }

  @override
  int get hashCode {
    return Object.hash(semester, period);
  }

  @override
  String toString() {
    return 'AcademicContext(semester: $semester, period: $period)';
  }

  /// Static method to get list of valid periods
  static List<String> get validPeriods => ['UTS', 'UAS'];

  /// Static method to get Indonesian period names
  static Map<String, String> get periodIndonesianNames => {
    'UTS': 'Ujian Tengah Semester',
    'UAS': 'Ujian Akhir Semester',
  };

  /// Gets Indonesian name for the current period
  String get periodIndonesianName {
    return periodIndonesianNames[period] ?? period;
  }
}