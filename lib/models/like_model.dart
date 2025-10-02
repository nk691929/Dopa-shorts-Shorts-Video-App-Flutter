class Like {
  final String id;
  final String userId;
  final String videoId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.createdAt,
  });

  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      videoId: map['video_id'] as String,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'video_id': videoId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
