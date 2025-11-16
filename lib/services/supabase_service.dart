import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // User methods
  static Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return AppUser.fromMap(response);
    } catch (e) {
      Text('Error getting current user: $e');
      return null;
    }
  }

  static Future<List<AppUser>> getEmployees() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'employee')
          .order('full_name');

      return (response as List).map((user) => AppUser.fromMap(user)).toList();
    } catch (e) {
      Text('Error getting employees: $e');
      return [];
    }
  }

  static Future<void> createUser(AppUser user, String password) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
      );

      if (authResponse.user != null) {
        // Create user profile
        await _supabase.from('users').insert({
          'id': authResponse.user!.id,
          'email': user.email,
          'role': user.role,
          'full_name': user.fullName,
        });
      }
    } catch (e) {
      Text('Error creating user: $e');
      rethrow;
    }
  }

  // Task methods
  static Future<List<Task>> getTasks({
    String? assignedTo,
    DateTime? dueDate,
    bool? isCompleted,
  }) async {
    try {
      // FIXED: Chain methods properly
      if (assignedTo != null && dueDate != null && isCompleted != null) {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .eq('assigned_to', assignedTo)
            .eq('due_date', dueDate.toIso8601String().split('T')[0])
            .eq('is_completed', isCompleted)
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      } else if (assignedTo != null && dueDate != null) {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .eq('assigned_to', assignedTo)
            .eq('due_date', dueDate.toIso8601String().split('T')[0])
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      } else if (assignedTo != null && isCompleted != null) {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .eq('assigned_to', assignedTo)
            .eq('is_completed', isCompleted)
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      } else if (dueDate != null && isCompleted != null) {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .eq('due_date', dueDate.toIso8601String().split('T')[0])
            .eq('is_completed', isCompleted)
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      } else if (assignedTo != null) {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .eq('assigned_to', assignedTo)
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      } else if (dueDate != null) {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .eq('due_date', dueDate.toIso8601String().split('T')[0])
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      } else if (isCompleted != null) {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .eq('is_completed', isCompleted)
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      } else {
        final response = await _supabase
            .from('tasks')
            .select('*, users(full_name)')
            .order('due_time')
            .order('created_at');
        return (response as List).map((task) => Task.fromMap(task)).toList();
      }
    } catch (e) {
      Text('Error getting tasks: $e');
      return [];
    }
  }

  static Future<void> createTask(Task task) async {
    try {
      await _supabase.from('tasks').insert(task.toMap());
    } catch (e) {
      Text('Error creating task: $e');
      rethrow;
    }
  }

  static Future<void> updateTask(Task task) async {
    try {
      await _supabase.from('tasks').update(task.toMap()).eq('id', task.id);
    } catch (e) {
      Text('Error updating task: $e');
      rethrow;
    }
  }

  static Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      Text('Error deleting task: $e');
      rethrow;
    }
  }

  // Attendance methods
  // Attendance methods
static Future<void> markAttendance({
  required String userId,
  required String status,
  DateTime? startTime,
  DateTime? endTime,
}) async {
  try {
    final now = DateTime.now();
    
    if (status == 'present') {
      await _supabase.from('attendance').insert({
        'user_id': userId,
        'date': now.toIso8601String().split('T')[0],
        'start_time': startTime?.toIso8601String() ?? now.toIso8601String(),
        'status': 'present',
      });
    } else {
      // ALTERNATIVE: Get the record first, then update if end_time is null
      final todayAttendance = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('date', now.toIso8601String().split('T')[0])
          .maybeSingle();

      if (todayAttendance != null && todayAttendance['end_time'] == null) {
        await _supabase
            .from('attendance')
            .update({
              'end_time': endTime?.toIso8601String() ?? now.toIso8601String(),
            })
            .eq('id', todayAttendance['id'] as String);
      }
    }
  } catch (e) {
    Text('Error marking attendance: $e');
    rethrow;
  }
}

  static Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    try {
      final today = DateTime.now();
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('date', today.toIso8601String().split('T')[0])
          .maybeSingle();

      return response;
    } catch (e) {
      Text('Error getting today attendance: $e');
      return null;
    }
  }

  // Report methods
  static Future<List<Map<String, dynamic>>> getReports({String? userId}) async {
    try {
      // FIXED: Chain methods properly
      if (userId != null) {
        final response = await _supabase
            .from('reports')
            .select('*, users(full_name)')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return response;
      } else {
        final response = await _supabase
            .from('reports')
            .select('*, users(full_name)')
            .order('created_at', ascending: false);
        return response;
      }
    } catch (e) {
      Text('Error getting reports: $e');
      return [];
    }
  }

  static Future<void> updateReportStatus(String reportId, String status, {String? managerResponse}) async {
    try {
      await _supabase.from('reports').update({
        'status': status,
        'manager_response': managerResponse,
      }).eq('id', reportId);
    } catch (e) {
      Text('Error updating report status: $e');
      rethrow;
    }
  }

  // Report methods - ADD THESE TO YOUR EXISTING SupabaseService CLASS
static Future<void> submitReport({
  required String userId,
  required String title,
  required String description,
  String? imageUrl,
}) async {
  try {
    await _supabase.from('reports').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    Text('Error submitting report: $e');
    rethrow;
  }
}

// Image upload method for reports
static Future<String?> uploadReportImage(String imagePath) async {
  try {
    final file = File(imagePath);
    final fileBytes = await file.readAsBytes();
    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    final response = await _supabase.storage
        .from('reports')
        .uploadBinary(fileName, fileBytes);
    
    final publicUrl = _supabase.storage
        .from('reports')
        .getPublicUrl(fileName);
    
    return publicUrl;
  } catch (e) {
    Text('Error uploading report image: $e');
    return null;
  }
}

// Get reports for a specific user
static Future<List<Map<String, dynamic>>> getUserReports(String userId) async {
  try {
    final response = await _supabase
        .from('reports')
        .select('*, users(full_name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return response;
  } catch (e) {
    Text('Error getting user reports: $e');
    return [];
  }
}

// Update report status (for managers)
static Future<void> updateReport(String reportId, String status, {String? managerResponse}) async {
  try {
    await _supabase
        .from('reports')
        .update({
          'status': status,
          'manager_response': managerResponse,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId);
  } catch (e) {
    Text('Error updating report: $e');
    rethrow;
  }
}

  // Analytics methods
  static Future<List<Map<String, dynamic>>> getAttendanceAnalytics({
    required String period,
    String? userId,
  }) async {
    try {
      // Add date filtering based on period
      final now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'weekly':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'yearly':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default: // daily
          startDate = now;
      }

      // FIXED: Chain methods properly with conditional logic
      if (userId != null) {
        final response = await _supabase
            .from('attendance')
            .select('*, users(full_name)')
            .eq('user_id', userId)
            .gte('date', startDate.toIso8601String().split('T')[0])
            .order('date', ascending: false);
        return response;
      } else {
        final response = await _supabase
            .from('attendance')
            .select('*, users(full_name)')
            .gte('date', startDate.toIso8601String().split('T')[0])
            .order('date', ascending: false);
        return response;
      }
    } catch (e) {
      Text('Error getting attendance analytics: $e');
      return [];
    }
  }

  // Additional methods
  static Future<void> moveIncompleteTasksToTomorrow() async {
    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      
      // FIXED: Chain methods properly
      final incompleteTasks = await _supabase
          .from('tasks')
          .select()
          .eq('due_date', today.toIso8601String().split('T')[0])
          .eq('is_completed', false)
          .eq('is_recurring', true);

      for (final task in incompleteTasks) {
        await _supabase
            .from('tasks')
            .update({
              'due_date': tomorrow.toIso8601String().split('T')[0],
            })
            .eq('id', task['id'] as String);
      }
    } catch (e) {
      Text('Error moving incomplete tasks: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTaskStatistics() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('is_completed, due_date');

      final now = DateTime.now();
      final totalTasks = response.length;
      final completedTasks = response.where((task) => task['is_completed'] == true).length;
      final overdueTasks = response.where((task) {
        final dueDate = DateTime.parse(task['due_date'] as String);
        return task['is_completed'] == false && dueDate.isBefore(now);
      }).length;

      return [
        {'label': 'Total Tasks', 'value': totalTasks},
        {'label': 'Completed', 'value': completedTasks},
        {'label': 'Overdue', 'value': overdueTasks},
      ];
    } catch (e) {
      Text('Error getting task statistics: $e');
      return [];
    }
  }

  static Future<void> updateUserProfile(String userId, String fullName, String email) async {
    try {
      await _supabase
          .from('users')
          .update({
            'full_name': fullName,
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      Text('Error updating user profile: $e');
      rethrow;
    }
  }

  // Test connection method
  static Future<bool> testConnection() async {
    try {
      final response = await _supabase.from('users').select().limit(1);
      Text('✅ Supabase connection test successful');
      return true;
    } catch (e) {
      Text('❌ Supabase connection test failed: $e');
      return false;
    }
  }
}