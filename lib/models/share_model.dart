class Share {
  final String id;
  final String userId;
  final String videoId;
  final DateTime createdAt;

  Share({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.createdAt,
  });

  factory Share.fromMap(Map<String, dynamic> map) {
    return Share(
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
