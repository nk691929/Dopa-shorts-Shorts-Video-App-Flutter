import 'package:dopa_shorts/Providers/like_notifier.dart';
import 'package:dopa_shorts/widgets/comment_section.dart';
import 'package:dopa_shorts/widgets/video_player_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dynamic screen for a single video (from share link or deep link)
class DynamicVideoScreen extends ConsumerWidget {
  final String videoId;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const DynamicVideoScreen({
    super.key,
    required this.videoId,
    required this.routeObserver
  });

  Future<Map<String, dynamic>?> _fetchVideo(String id) async {
    final supabase = Supabase.instance.client;
    final video = await supabase
        .from('videos')
        .select('id, video_url, user_id, profile_image_url, comments_count, shares_count')
        .eq('id', id)
        .maybeSingle();
    return video;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchVideo(videoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "Video not found",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final video = snapshot.data!;
        final supabase = Supabase.instance.client;
        final getVideoUrl =
            supabase.storage.from('videos').getPublicUrl(video['video_url']);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 🎥 video player
              Positioned.fill(
                child: VideoPlayerComponent(videoUrl: getVideoUrl,routeObserver: routeObserver, videoId: videoId,),
              ),

              // ❤️ + 💬 + 🔗 overlay
              Positioned(
                right: 16,
                bottom: 80,
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(video['profile_image_url'] ?? ""),
                      radius: 25,
                    ),
                    const SizedBox(height: 20),

                    // ❤️ Like button
                    Consumer(
                      builder: (context, ref, _) {
                        final currentUserId =
                            Supabase.instance.client.auth.currentUser!.id;
                        final likeAsync = ref.watch(
                          likeProvider((
                            videoId: video['id'] as String,
                            userId: currentUserId,
                            vidOwnerId: video['user_id'],
                          )),
                        );

                        return InkWell(
                          onTap: () {
                            ref
                                .read(
                                  likeProvider((
                                    videoId: video['id'] as String,
                                    userId: currentUserId,
                                    vidOwnerId: video['user_id'] as String,
                                  )).notifier,
                                )
                                .toggleLike();
                          },
                          child: Column(
                            children: [
                              likeAsync.when(
                                data: (like) => Icon(
                                  Icons.favorite,
                                  color: like.isLiked
                                      ? Colors.red
                                      : Colors.white,
                                  size: 35,
                                ),
                                loading: () => const Icon(
                                  Icons.favorite,
                                  color: Colors.grey,
                                  size: 35,
                                ),
                                error: (_, __) => const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                              const SizedBox(height: 5),
                              likeAsync.when(
                                data: (like) => Text(
                                  like.count.toString(),
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                                loading: () => const Text(
                                  "...",
                                  style: TextStyle(color: Colors.white),
                                ),
                                error: (_, __) => const Text(
                                  "0",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // 💬 Comment button
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.grey.shade900,
                          builder: (context) {
                            return CommentSection(
                              videoId: video['id'],
                              userId: supabase.auth.currentUser!.id,
                              vidOwnerId: video['user_id'],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.comment,
                          color: Colors.white, size: 30),
                    ),
                    Text(
                      (video['comments_count'] ?? 0).toString(),
                      style: const TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 20),

                    // 🔗 Share button
                    Icon(Icons.share, color: Colors.white, size: 30),
                    Text(
                      (video['shares_count'] ?? 0).toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
