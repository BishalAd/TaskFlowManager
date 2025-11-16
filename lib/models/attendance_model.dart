class Attendance {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final DateTime createdAt;
  final String? userName;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    this.startTime,
    this.endTime,
    required this.status,
    required this.createdAt,
    this.userName,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: DateTime.parse(map['date'] as String),
      startTime: map['start_time'] != null 
          ? DateTime.parse(map['start_time'] as String) 
          : null,
      endTime: map['end_time'] != null 
          ? DateTime.parse(map['end_time'] as String) 
          : null,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      userName: map['users'] != null 
          ? (map['users'] as Map<String, dynamic>)['full_name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get hoursWorked {
    if (startTime == null || endTime == null) return 0.0;
    return endTime!.difference(startTime!).inMinutes / 60.0;
  }

  bool get isCompleted => startTime != null && endTime != null;
}