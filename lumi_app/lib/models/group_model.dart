import 'user_model.dart';

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.members,
  });

  final String id;
  final String name;
  final String adminId;
  final List<UserModel> members;

  factory GroupModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return GroupModel(
      id: _readString(data, ['id', '_id']),
      name: _readString(data, ['name']),
      adminId: _readAdminId(data['adminId']),
      members: _readMembers(data['members']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'adminId': adminId,
      'members': members.map((member) => member.toJson()).toList(),
    };
  }

  static List<UserModel> _readMembers(dynamic rawMembers) {
    if (rawMembers is! List) {
      return const <UserModel>[];
    }

    return rawMembers.map((member) {
      if (member is Map<String, dynamic>) {
        return UserModel.fromJson(member);
      }
      if (member is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(member));
      }
      return UserModel.fromJson({'id': member?.toString() ?? ''});
    }).toList();
  }

  static String _readAdminId(dynamic rawAdmin) {
    if (rawAdmin is Map<String, dynamic>) {
      return _readString(rawAdmin, ['id', '_id']);
    }
    if (rawAdmin is Map) {
      return _readString(Map<String, dynamic>.from(rawAdmin), ['id', '_id']);
    }
    return rawAdmin?.toString().trim() ?? '';
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}