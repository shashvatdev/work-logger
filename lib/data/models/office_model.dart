class OfficeModel {
  final String id, name;
  final String? address;
  final double latitude, longitude, radiusInMeters;
  final bool isActive;

  OfficeModel({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.isActive,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    return OfficeModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      radiusInMeters: (json['radiusInMeters'] ?? 100).toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }
}
