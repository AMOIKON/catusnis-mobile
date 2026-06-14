// lib/core/models/user_model.dart

import 'dart:convert';

class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? contact;
  final int? partnerId;
  final String? partnerName;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.contact,
    this.partnerId,
    this.partnerName,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get fullName => '$firstName $lastName';
  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAdmin => role == 'ADMIN';
  bool get isTechnicien => role == 'TECHNICIEN';
  bool get canCreate => isSuperAdmin || isAdmin || isTechnicien;
  bool get canDelete => isSuperAdmin || isAdmin;

  // ── JSON ──────────────────────────────────────────────────────────────────
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: (json['email'] as String?) ?? '',
        firstName: (json['firstName'] as String?) ?? '',
        lastName: (json['lastName'] as String?) ?? '',
        role: (json['role'] as String?) ?? 'USER',
        contact: json['contact'] as String?,
        partnerId: json['partnerId'] as int?,
        partnerName: json['partnerName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'contact': contact,
        'partnerId': partnerId,
        'partnerName': partnerName,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String s) =>
      UserModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

// ── Réponse login API ─────────────────────────────────────────────────────────
// Votre backend renvoie : { success: true, data: { token: "...", person: {...} } }
class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return AuthResponse(
      token:
          (data['accessToken'] as String?) ?? (data['token'] as String?) ?? '',
      user: UserModel.fromJson(
        (data['person'] as Map<String, dynamic>?) ?? data,
      ),
    );
  }
}
