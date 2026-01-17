import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_context.dart';

class PreferencesRepository {
  static const String _lastContextKey = 'last_academic_context';
  static const String _sortPreferenceKey = 'sort_preference';
  
  // Valid sort options for validation
  static const List<String> validSortOptions = [
    'deadline',
    'progress', 
    'course_name',
    'task_name'
  ];
  
  /// Save the last used academic context to SharedPreferences
  Future<bool> saveLastContext(AcademicContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextJson = json.encode(context.toJson());
      return await prefs.setString(_lastContextKey, contextJson);
    } catch (e) {
      // Return false if saving fails
      return false;
    }
  }
  
  /// Retrieve the last used academic context from SharedPreferences
  /// Returns null if no context is saved or if retrieval fails
  Future<AcademicContext?> getLastContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextJson = prefs.getString(_lastContextKey);
      
      if (contextJson == null) {
        return null;
      }
      
      final contextMap = json.decode(contextJson) as Map<String, dynamic>;
      final context = AcademicContext.fromJson(contextMap);
      
      // Validate the retrieved context before returning
      if (context.isValid()) {
        return context;
      } else {
        // If context is invalid, remove it and return null
        await clearLastContext();
        return null;
      }
    } catch (e) {
      // If parsing fails, clear the corrupted data and return null
      await clearLastContext();
      return null;
    }
  }
  
  /// Clear the last used academic context from SharedPreferences
  Future<bool> clearLastContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_lastContextKey);
    } catch (e) {
      return false;
    }
  }
  
  /// Save sort preference with validation
  /// Only accepts valid sort options: deadline, progress, course_name, task_name
  Future<bool> saveSortPreference(String sortBy) async {
    try {
      // Validate sort preference before saving
      if (!validSortOptions.contains(sortBy)) {
        throw ArgumentError('Invalid sort option: $sortBy. Valid options are: ${validSortOptions.join(', ')}');
      }
      
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_sortPreferenceKey, sortBy);
    } catch (e) {
      return false;
    }
  }
  
  /// Retrieve sort preference from SharedPreferences
  /// Returns 'deadline' as default if no preference is saved or if retrieval fails
  Future<String> getSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortPreference = prefs.getString(_sortPreferenceKey);
      
      // Return default if no preference is saved
      if (sortPreference == null) {
        return 'deadline'; // Default sort by deadline
      }
      
      // Validate retrieved preference
      if (validSortOptions.contains(sortPreference)) {
        return sortPreference;
      } else {
        // If invalid preference is stored, clear it and return default
        await clearSortPreference();
        return 'deadline';
      }
    } catch (e) {
      // If retrieval fails, return default
      return 'deadline';
    }
  }
  
  /// Clear sort preference from SharedPreferences
  Future<bool> clearSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_sortPreferenceKey);
    } catch (e) {
      return false;
    }
  }
  
  /// Clear all preferences (useful for testing or reset functionality)
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contextResult = await prefs.remove(_lastContextKey);
      final sortResult = await prefs.remove(_sortPreferenceKey);
      return contextResult && sortResult;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if last context exists
  Future<bool> hasLastContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_lastContextKey);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if sort preference exists
  Future<bool> hasSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_sortPreferenceKey);
    } catch (e) {
      return false;
    }
  }
  
  /// Get all valid sort options
  static List<String> getValidSortOptions() {
    return List.from(validSortOptions);
  }
  
  /// Validate if a sort option is valid
  static bool isValidSortOption(String sortBy) {
    return validSortOptions.contains(sortBy);
  }
}