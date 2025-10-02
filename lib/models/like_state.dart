class LikeState {
  final int count;
  final bool isLiked;

  LikeState({
    required this.count,
    required this.isLiked,
  });

  LikeState copyWith({
    int? count,
    bool? isLiked,
  }) {
    return LikeState(
      count: count ?? this.count,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
