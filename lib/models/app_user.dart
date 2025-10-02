class AppUser {
  final String id;
  final String username;
  final String fullname;
  final String email;
  final String? profilePicUrl;
  final DateTime createdAt;
  final int followerCount;
  final int followingCount;

  AppUser({
    required this.id,
    this.username = "",
    this.fullname = "",
    required this.email,
    this.profilePicUrl,
    required this.createdAt,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  AppUser copyWith({
    String? username,
    String? fullname,
    String? profilePicUrl,
    int? followerCount,
    int? followingCount,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      fullname: fullname ?? this.fullname,
      email: email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      createdAt: createdAt,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      username: map['username'] as String,
      fullname: map['full_name'] as String,
      email: map['email'] as String,
      profilePicUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      followerCount: map['follower_count'] as int? ?? 0,
      followingCount: map['following_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullname,
      'email': email,
      'avatar_url': profilePicUrl,
      'created_at': createdAt.toIso8601String(),
      'follower_count': followerCount,
      'following_count': followingCount,
    };
  }
}
