class Report {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final String status;
  final String? managerResponse;
  final DateTime createdAt;
  final String? userName;

  Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.status,
    this.managerResponse,
    required this.createdAt,
    this.userName,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
      status: map['status'] as String,
      managerResponse: map['manager_response'] as String?,
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
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'status': status,
      'manager_response': managerResponse,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isResolved => status == 'resolved';
  bool get isOpen => status == 'open';
}