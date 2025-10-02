import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_feed_item.dart';

/// Provide Supabase client everywhere
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class VideoFeedNotifier extends StateNotifier<AsyncValue<List<VideoFeedItem>>> {
  VideoFeedNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchVideos(); // initial fetch
  }

  final Ref ref;

  /// Pagination control
  final int limit = 10;
  int offset = 0;
  bool hasMore = true;
  bool isFetching = false;

  /// Fetch next batch of videos
  Future<void> fetchVideos() async {
    if (!hasMore || isFetching) return;

    isFetching = true;

    try {
      final supabase = ref.read(supabaseProvider);

      final response = await supabase.rpc(
        'get_for_you_feed',
        params: {
          'p_user_id': supabase.auth.currentUser!.id,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) {
        throw Exception("No response from Supabase");
      }

      final newVideos = (response as List).map((video) {
        return VideoFeedItem(
          id: video['video_id'] ?? '',
          videoUrl: video['video_path'] ?? '',
          caption: video['caption'] ?? '',
          userId: video['user_id'] ?? '',
          username: video['username'] ?? 'Unknown',
          thumbnailUrl: video['thumbnail_url'] ?? '',
          profileImageUrl: video['avatar_url'] ?? '',
          likesCount: video['like_count'] ?? 0,
          commentsCount: video['comment_count'] ?? 0,
          sharesCount: video['share_count'] ?? 0,
          viewsCount: video['view_count'] ?? 0,
          createdAt:
              DateTime.tryParse(video['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();

      offset += newVideos.length;
      if (newVideos.length < limit) hasMore = false;

      // append to state
      state = AsyncValue.data([
        ...state.value ?? [],
        ...newVideos,
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      isFetching = false;
    }
  }

  /// Reset feed (useful for pull-to-refresh)
  Future<void> refreshFeed() async {
    offset = 0;
    hasMore = true;
    state = const AsyncValue.loading();
    await fetchVideos();
  }

  
}

/// Provider for the video feed
final videoFeedProvider =
    StateNotifierProvider<VideoFeedNotifier, AsyncValue<List<VideoFeedItem>>>(
  (ref) => VideoFeedNotifier(ref),
);


