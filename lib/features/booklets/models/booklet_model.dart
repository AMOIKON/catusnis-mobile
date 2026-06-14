// lib/features/booklets/models/booklet_model.dart

class BookletModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? contact;
  final String? email;
  final int? regionId;
  final String? regionName;
  final int? districtId;
  final String? districtName;
  final int? postId;
  final String? postName;
  final int? statusId;
  final String? statusName;

  const BookletModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.contact,
    this.email,
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
    this.postId,
    this.postName,
    this.statusId,
    this.statusName,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  factory BookletModel.fromJson(Map<String, dynamic> json) => BookletModel(
        id: json['id'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        contact: json['contact'] as String?,
        email: json['email'] as String?,
        regionId: (json['region'] as Map<String, dynamic>?)?['id'] as int?,
        regionName:
            (json['region'] as Map<String, dynamic>?)?['regionName'] as String?,
        districtId: (json['district'] as Map<String, dynamic>?)?['id'] as int?,
        districtName: (json['district']
            as Map<String, dynamic>?)?['districtName'] as String?,
        postId: (json['post'] as Map<String, dynamic>?)?['id'] as int?,
        postName:
            (json['post'] as Map<String, dynamic>?)?['postName'] as String?,
        statusId: (json['status'] as Map<String, dynamic>?)?['id'] as int?,
        statusName:
            (json['status'] as Map<String, dynamic>?)?['statusName'] as String?,
      );
}

class BookletStatusModel {
  final int id;
  final String statusName;

  const BookletStatusModel({required this.id, required this.statusName});

  factory BookletStatusModel.fromJson(Map<String, dynamic> json) =>
      BookletStatusModel(
        id: json['id'] as int,
        statusName: json['statusName'] as String,
      );
}
