class VideoFeedItem {
  final String id;
  final String videoUrl;
  final String? thumbnailUrl;   // 🌍 Public URL
  final String? thumbnailPath;  // 📂 Storage path
  final String caption;
  final String userId;
  final String username;
  final String profileImageUrl;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final DateTime createdAt;

  VideoFeedItem({
    required this.id,
    required this.videoUrl,
    this.thumbnailUrl,
    this.thumbnailPath,
    required this.caption,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.viewsCount,
    required this.createdAt,
  });

  factory VideoFeedItem.fromJson(Map<String, dynamic> json) {
    return VideoFeedItem(
      id: json['id'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,   // 🌍 from DB
      thumbnailPath: json['thumbnail_path'] as String?, // 📂 from DB
      caption: json['caption'] ?? '',
      userId: json['user_id'] as String,
      username: json['users']?['username'] ?? 'Unknown',
      profileImageUrl: json['users']?['profile_image_url'] ?? '',
      likesCount: json['like_count'] ?? 0,
      commentsCount: json['comment_count'] ?? 0,
      sharesCount: json['share_count'] ?? 0,
      viewsCount: json['view_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
