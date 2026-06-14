// lib/features/persons/models/person.dart

class Person {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? contact;
  final String? role;
  final String? postName;
  final String? unitName;
  final int? postId;

  const Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.contact,
    this.role,
    this.postName,
    this.unitName,
    this.postId,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String?,
        contact: json['contact'] as String?,
        role: json['role'] as String?,
        postName: json['postName'] as String?,
        unitName: json['unitName'] as String?,
        postId: json['postId'] as int?,
      );

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  String get roleLabel {
    switch (role?.toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'ADMIN':
        return 'Administrateur';
      case 'TECHNICIEN':
        return 'Technicien';
      case 'LOGISTICIEN':
        return 'Logisticien';
      case 'USER':
        return 'Utilisateur';
      default:
        return role ?? '—';
    }
  }
}
