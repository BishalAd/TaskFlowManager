class Task {
  final String id;
  final String title;
  final String? description;
  final String? assignedTo;
  final String assignedBy;
  final DateTime dueDate;
  final String? dueTime;
  final bool isRecurring;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final bool isPersonal;
  final String? assignedUserName;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    required this.assignedBy,
    required this.dueDate,
    this.dueTime,
    this.isRecurring = false,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.isPersonal = false,
    this.assignedUserName,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      assignedTo: map['assigned_to'] as String?,
      assignedBy: map['assigned_by'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      dueTime: map['due_time'] as String?,
      isRecurring: map['is_recurring'] as bool? ?? false,
      isCompleted: map['is_completed'] as bool? ?? false,
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at'] as String) 
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      isPersonal: map['is_personal'] as bool? ?? false,
      assignedUserName: map['users'] != null 
          ? (map['users'] as Map<String, dynamic>)['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'due_time': dueTime,
      'is_recurring': isRecurring,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_personal': isPersonal,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? assignedBy,
    DateTime? dueDate,
    String? dueTime,
    bool? isRecurring,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    bool? isPersonal,
    String? assignedUserName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isRecurring: isRecurring ?? this.isRecurring,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      isPersonal: isPersonal ?? this.isPersonal,
      assignedUserName: assignedUserName ?? this.assignedUserName,
    );
  }
}