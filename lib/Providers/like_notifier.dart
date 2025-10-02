import 'package:dopa_shorts/models/like_state.dart';
import 'package:dopa_shorts/repositories/like_repo.dart';
import 'package:dopa_shorts/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LikeNotifier extends StateNotifier<AsyncValue<LikeState>> {
  final LikeRepository repository;
  final String videoId;
  final String userId;
  final String vidOwnerId;
  LikeNotifier(this.repository, this.videoId, this.userId,this.vidOwnerId)
    : super(const AsyncValue.loading()) {
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    try {
      final count = await repository.getLikeCount(videoId);

      // check if user already liked
      final res = await supabase
          .from('likes')
          .select('id')
          .eq('video_id', videoId)
          .eq('user_id', userId);

      final isLiked = res.isNotEmpty;

      state = AsyncValue.data(LikeState(count: count, isLiked: isLiked));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLike() async {
    try {
      final current = state.value;
      if (current == null) return;

      // Optimistic update
      if (current.isLiked) {
        state = AsyncValue.data(
          current.copyWith(isLiked: false, count: current.count - 1),
        );

        // DB update
        await repository.unlikeVideo(userId, videoId);
      } else {
        state = AsyncValue.data(
          current.copyWith(isLiked: true, count: current.count + 1),
        );

        final notificationService = NotificationService();
        // When user likes a post
        if (vidOwnerId != userId) {
          await notificationService.sendLike(
            likerId: userId,
            postId: videoId,
          );
        }
        // DB update
        await repository.likeVideo(userId, videoId);
      }

      // Optional: refresh count from DB for accuracy
      _loadLikes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final likeProvider =
    StateNotifierProvider.family<
      LikeNotifier,
      AsyncValue<LikeState>,
      ({String videoId, String userId,String vidOwnerId})
    >((ref, params) {
      return LikeNotifier(LikeRepository(), params.videoId, params.userId,params.vidOwnerId);
    });
