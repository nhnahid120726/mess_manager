class MemberModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'member'
  final bool isAuthorized;

  MemberModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isAuthorized,
  });

  // Convert Firebase Document to MemberModel
  factory MemberModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MemberModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      isAuthorized: data['isAuthorized'] ?? false,
    );
  }

  // Convert MemberModel to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isAuthorized': isAuthorized,
    };
  }
}
