class ClassMember {
  const ClassMember({required this.id, required this.username, this.role = 'student'});

  final String id;
  final String username;
  final String role;

  factory ClassMember.fromJson(Map<String, dynamic> json) => ClassMember(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        role: json['role']?.toString() ?? 'student',
      );
}

class ClassModel {
  const ClassModel({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.teacherName,
    required this.teacherId,
    required this.studentCount,
    this.description = '',
  });

  final String id;
  final String name;
  final String joinCode;
  final String teacherName;
  final String teacherId;
  final int studentCount;
  final String description;

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacherId'];
    final teacherName = teacher is Map
        ? teacher['username']?.toString() ?? ''
        : teacher?.toString() ?? '';
    final teacherId = teacher is Map
        ? teacher['_id']?.toString() ?? teacher['id']?.toString() ?? ''
        : teacher?.toString() ?? '';

    final students = json['students'];
    final studentCount = students is List ? students.length : 0;

    return ClassModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      joinCode: json['joinCode']?.toString() ?? '',
      teacherName: teacherName,
      teacherId: teacherId,
      studentCount: studentCount,
      description: json['description']?.toString() ?? '',
    );
  }
}
