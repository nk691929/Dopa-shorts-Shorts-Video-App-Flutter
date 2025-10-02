import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_feed_item.dart';
import 'supabase_provider.dart';

class UserVideoNotifier extends StateNotifier<AsyncValue<List<VideoFeedItem>>> {
  UserVideoNotifier(this.ref, this.userId) : super(const AsyncValue.loading()) {
    fetchUserVideos();
  }

  final Ref ref;
  final String userId;
  final int limit = 10;
  int offset = 0;
  bool hasMore = true;
  bool isFetching = false;

  Future<void> fetchUserVideos() async {
    if (!hasMore || isFetching) return;

    isFetching = true;

    try {
      final supabase = ref.read(supabaseProvider);

      final response = await supabase
          .from('videos')
          .select('''
            *,
            profiles (
              username,
              avatar_url
            ),
            likes (id),
            comments (id),
            shares (id),
            views (id)
          ''')
          .eq('user_id', userId) // ✅ Only this user's videos
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final userVideos = (response as List).map((video) {
        return VideoFeedItem(
          id: video['id'],
          videoUrl: video['video_path'],
          caption: video['caption'] ?? '',
          userId: video['user_id'],
          username: video['profiles']['username'],
          thumbnailUrl: video['thumbnail_url'] ?? '',
          thumbnailPath: video['thumbnail_path']??"", // 📂 from DB
          profileImageUrl: video['profiles']['avatar_url'],
          likesCount: (video['like_count']),
          commentsCount: (video['comment_count']),
          sharesCount: (video['share_count']),
          viewsCount: (video['view_count']),
          createdAt: DateTime.parse(video['created_at']),
        );
      }).toList();

      offset += userVideos.length;
      if (userVideos.length < limit) hasMore = false;

      state = AsyncValue.data([...state.value ?? [], ...userVideos]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      isFetching = false;
    }
  }

  String getStoragePathVid(String publicUrl) {
    final parts = publicUrl.split('/videos/');
    return parts.length > 1 ? parts[1] : publicUrl;
  }

  Future<void> deleteVideo(VideoFeedItem video, String videoUrl) async {
    try {
      final supabase = ref.read(supabaseProvider);

      // 1. Delete the video row (cascade will handle likes, comments, shares, views)
      await supabase.from('videos').delete().eq('id', video.id);

      // 2. Optionally, delete the video file from storage
      await supabase.storage.from('videos').remove([
        getStoragePathVid(videoUrl),
      ]);
    
      // 3️⃣ Delete thumbnail if path exists
    if (video.thumbnailPath != null && video.thumbnailPath!.isNotEmpty) {
      await supabase.storage.from('thumbnails').remove([video.thumbnailPath!]);
      print("✅ Thumbnail deleted successfully");
    }

      // 3. Update local state (remove the video from provider list)
      final currentVideos = state.value ?? [];
      state = AsyncValue.data(
        currentVideos.where((video) => video.id != video.id).toList(),
      );

      print("✅ Video deleted successfully: ${video.id}");
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print("❌ Error deleting video: $e");
    }
  }
}

final userVideoProvider =
    StateNotifierProvider.family<
      UserVideoNotifier,
      AsyncValue<List<VideoFeedItem>>,
      String
    >((ref, userId) {
      return UserVideoNotifier(ref, userId);
    });
