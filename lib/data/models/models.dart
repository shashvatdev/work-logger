enum UserRole { admin, employee }

// ─────────────────────────────────────────────────────────────────────────────
// UserModel
// ─────────────────────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final bool hasLoggedToday;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.hasLoggedToday = false,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: (json['role'] as String).toLowerCase() == 'admin'
          ? UserRole.admin
          : UserRole.employee,
      isActive: json['isActive'] as bool? ?? true,
      hasLoggedToday: json['hasLoggedToday'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': isAdmin ? 'Admin' : 'Employee',
        'isActive': isActive,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ProjectModel
// ─────────────────────────────────────────────────────────────────────────────
class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final bool archived;
  final DateTime createdAt;
  final List<String> memberIds;
  final int memberCount;
  final String? createdByName;

  const ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.archived = false,
    required this.createdAt,
    this.memberIds = const [],
    this.memberCount = 0,
    this.createdByName,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Members may come as a list of member objects (GET /projects/{id})
    // or as memberUserIds array (GET /projects list view)
    final membersList = json['members'] as List?;
    final memberUserIdsList = json['memberUserIds'] as List?;

    final memberIds = membersList
            ?.map((m) => m['userId'] as String)
            .toList() ??
        memberUserIdsList
            ?.map((id) => id.toString())
            .toList() ??
        [];

    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      archived: json['isArchived'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      memberIds: memberIds,
      memberCount: json['memberCount'] as int? ?? memberIds.length,
      createdByName: json['createdByName'] as String?,
    );
  }

  ProjectModel copyWith({
    String? name,
    String? description,
    bool? archived,
    List<String>? memberIds,
    int? memberCount,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      createdByName: createdByName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DailyLogModel
// ─────────────────────────────────────────────────────────────────────────────
class DailyLogModel {
  final String id;
  final String userId;
  final String date; // yyyy-MM-dd (from logDate field)
  final List<LogEntryModel> entries;
  final int entryCount;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const DailyLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.entries,
    this.entryCount = 0,
    this.updatedAt,
    this.createdAt,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    final entriesList = json['entries'] as List? ?? [];
    return DailyLogModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      date: json['logDate'] as String? ?? json['date'] as String? ?? '',
      entries:
          entriesList.map((e) => LogEntryModel.fromJson(e)).toList(),
      entryCount: json['entryCount'] as int? ?? entriesList.length,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  DailyLogModel copyWith({
    List<LogEntryModel>? entries,
    int? entryCount,
    DateTime? updatedAt,
  }) {
    return DailyLogModel(
      id: id,
      userId: userId,
      date: date,
      entries: entries ?? this.entries,
      entryCount: entryCount ?? this.entryCount,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LogEntryModel
// ─────────────────────────────────────────────────────────────────────────────
class LogEntryModel {
  final String id;
  final String logId;
  final String projectId;
  final String? projectName;
  String description;
  String? timeSpent;
  final List<AttachmentModel> attachments;

  LogEntryModel({
    required this.id,
    required this.logId,
    required this.projectId,
    this.projectName,
    required this.description,
    this.timeSpent,
    this.attachments = const [],
  });

  factory LogEntryModel.fromJson(Map<String, dynamic> json) {
    final attachmentsList = json['attachments'] as List? ?? [];
    return LogEntryModel(
      id: json['id'] as String,
      logId: json['dailyLogId'] as String? ?? '',
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String?,
      description: json['description'] as String,
      timeSpent: json['timeSpent'] as String? ?? json['hoursSpent'] as String? ?? json['duration'] as String?,
      attachments:
          attachmentsList.map((a) => AttachmentModel.fromJson(a)).toList(),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        if (id.isNotEmpty) 'id': id,
        'projectId': projectId,
        'description': description,
        if (timeSpent != null && timeSpent!.isNotEmpty) 'timeSpent': timeSpent,
      };

  LogEntryModel copyWith({
    String? projectId,
    String? description,
    String? timeSpent,
    List<AttachmentModel>? attachments,
  }) {
    return LogEntryModel(
      id: id,
      logId: logId,
      projectId: projectId ?? this.projectId,
      projectName: projectName,
      description: description ?? this.description,
      timeSpent: timeSpent ?? this.timeSpent,
      attachments: attachments ?? this.attachments,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AttachmentModel
// ─────────────────────────────────────────────────────────────────────────────
enum AttachmentType { image, pdf, zip, apk, video, other }

class AttachmentModel {
  final String id;
  final String fileName;
  final AttachmentType type;
  final String? url;
  final int? fileSizeBytes;
  final DateTime? uploadedAt;

  const AttachmentModel({
    required this.id,
    required this.fileName,
    required this.type,
    this.url,
    this.fileSizeBytes,
    this.uploadedAt,
  });

  String get fullUrl {
    if (url == null) return '';
    if (url!.startsWith('http://') || url!.startsWith('https://')) {
      return url!;
    }
    return 'https://worktracker.addonshareware.com$url';
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    final fileType = json['fileType'] as String? ?? 'other';
    return AttachmentModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      type: _parseType(fileType),
      url: json['storageUrl'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String)
          : null,
    );
  }

  static AttachmentType _parseType(String t) {
    switch (t.toLowerCase()) {
      case 'image':
        return AttachmentType.image;
      case 'pdf':
        return AttachmentType.pdf;
      case 'zip':
        return AttachmentType.zip;
      case 'apk':
        return AttachmentType.apk;
      case 'video':
        return AttachmentType.video;
      default:
        return AttachmentType.other;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchResult
// ─────────────────────────────────────────────────────────────────────────────
class SearchResult {
  final String date;
  final String projectName;
  final String projectId;
  final String excerpt;
  final String userId;
  final String userName;
  final String logId;
  final String logEntryId;

  const SearchResult({
    required this.date,
    required this.projectName,
    required this.projectId,
    required this.excerpt,
    required this.userId,
    required this.userName,
    required this.logId,
    required this.logEntryId,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      date: json['logDate'] as String,
      projectName: json['projectName'] as String,
      projectId: json['projectId'] as String,
      excerpt: json['excerpt'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      logId: json['logEntryId'] as String,
      logEntryId: json['logEntryId'] as String,
    );
  }
}
