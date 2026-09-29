class AssignedOffice {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final bool isActive;

  AssignedOffice({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.isActive,
  });

  factory AssignedOffice.fromJson(Map<String, dynamic> json) {
    return AssignedOffice(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusInMeters: (json['radiusInMeters'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
