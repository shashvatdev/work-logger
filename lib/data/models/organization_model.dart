import '../../core/utils/date_extensions.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String? websiteUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int userCount;
  final int geofenceCount;
  final int projectCount;

  const OrganizationModel({
    required this.id,
    required this.name,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.websiteUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.userCount = 0,
    this.geofenceCount = 0,
    this.projectCount = 0,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    final usersList = json['users'] as List? ?? [];
    final geofencesList = json['geofenceZones'] as List? ?? [];
    final projectsList = json['projects'] as List? ?? [];

    return OrganizationModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      address: json['address'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseBackendTime(json['createdAt'] as String?),
      updatedAt: parseBackendTime(json['updatedAt'] as String?),
      userCount: json['userCount'] as int? ?? usersList.length,
      geofenceCount: json['geofenceCount'] as int? ?? geofencesList.length,
      projectCount: json['projectCount'] as int? ?? projectsList.length,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'address': address,
        'websiteUrl': websiteUrl,
        'isActive': isActive,
      };
}

class CreateOrganizationRequest {
  final String name;
  final String contactEmail;
  final String adminName;
  final String adminEmail;
  final String adminPassword;

  const CreateOrganizationRequest({
    required this.name,
    required this.contactEmail,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'contactEmail': contactEmail.trim(),
        'adminName': adminName.trim(),
        'adminEmail': adminEmail.trim(),
        'adminPassword': adminPassword,
      };
}

