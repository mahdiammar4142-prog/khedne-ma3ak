/// User profile stored in Firestore for the social layer.
class UserProfileModel {
  final String id;
  final String displayName;
  final String? handle;
  final String? email;
  final String? photoUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> connectionIds;
  final List<String> savedPlaceIds;

  const UserProfileModel({
    required this.id,
    required this.displayName,
    this.handle,
    this.email,
    this.photoUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.connectionIds = const [],
    this.savedPlaceIds = const [],
  });

  factory UserProfileModel.fromMap(String id, Map<String, dynamic> map) {
    return UserProfileModel(
      id: id,
      displayName: map['displayName'] as String? ?? '',
      handle: map['handle'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      connectionIds: List<String>.from(map['connectionIds'] ?? []),
      savedPlaceIds: List<String>.from(map['savedPlaceIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'displayNameLower': displayName.trim().toLowerCase(),
        'handle': handle,
        'handleLower': handle?.trim().toLowerCase(),
        'email': email,
        'emailLower': email?.trim().toLowerCase(),
        'photoUrl': photoUrl,
        'bio': bio,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'connectionIds': connectionIds,
        'savedPlaceIds': savedPlaceIds,
      };

  UserProfileModel copyWith({
    String? displayName,
    String? handle,
    String? email,
    String? photoUrl,
    String? bio,
    DateTime? updatedAt,
    List<String>? connectionIds,
    List<String>? savedPlaceIds,
  }) {
    return UserProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      connectionIds: connectionIds ?? this.connectionIds,
      savedPlaceIds: savedPlaceIds ?? this.savedPlaceIds,
    );
  }
}
