class Comment {
  final String id;
  final String userId;
  final String videoId;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final String? parentId;

  Comment({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    this.parentId,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      videoId: map['video_id'] as String,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at']),
      likeCount: (map['like_count'] ?? 0) as int,
      parentId: map['parent_id'] as String?,
    );
  }
}
