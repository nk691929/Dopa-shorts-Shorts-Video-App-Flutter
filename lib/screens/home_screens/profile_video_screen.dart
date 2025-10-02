import 'package:dopa_shorts/Providers/comment_provider.dart';
import 'package:dopa_shorts/Providers/like_notifier.dart';
import 'package:dopa_shorts/Providers/user_videos_provider.dart';
import 'package:dopa_shorts/widgets/comment_section.dart';
import 'package:dopa_shorts/widgets/dialog_box.dart';
import 'package:dopa_shorts/widgets/video_player_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ProfileVideoScreen extends ConsumerWidget {
  final String userId;
  final int startIndex;
  final RouteObserver<ModalRoute<void>> routeObserver;
  const ProfileVideoScreen({
    super.key,
    required this.userId,
    this.startIndex = 0,
    required this.routeObserver,
  });

  void shareVideo(String videoId) {
    final link = "https://yourdomain.com/watch?id=$videoId";
    Share.share("Check out this video! $link");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userVideos = ref.watch(userVideoProvider(userId));
    final pageController = PageController(initialPage: startIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        title: const Text(
          "Your Videos",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: userVideos.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Text(
                "No videos uploaded yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Stack(
            children: [
              Positioned(
                right: 0,
                left: 0,
                bottom: 60,
                top: 0,
                child: PageView.builder(
                  controller: pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];

                    final supabase = Supabase.instance.client;
                    final getVideoUrl = supabase.storage
                        .from('videos')
                        .getPublicUrl(video.videoUrl);

                    return Stack(
                      children: [
                        // 🎥 video player
                        VideoPlayerComponent(
                          videoUrl: getVideoUrl,
                          routeObserver: routeObserver,
                          videoId: video.id,
                        ),

                        // ❤️ + 💬 + 🔗 overlay buttons
                        Positioned(
                          right: 16,
                          bottom: 80,
                          child: Column(
                            children: [
                              video.profileImageUrl.isNotEmpty || video.profileImageUrl!=null?CircleAvatar(
                                backgroundImage: NetworkImage(
                                  video.profileImageUrl,
                                ),
                                radius: 25,
                              ): const CircleAvatar(
                                backgroundImage: AssetImage(
                                  'assets/default_profile.png',
                                ),
                                radius: 25,
                              ),
                              const SizedBox(height: 20),

                              // ❤️ Like button
                              Consumer(
                                builder: (context, ref, _) {
                                  final currentUserId = Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser!
                                      .id;
                                  final likeAsync = ref.watch(
                                    likeProvider((
                                      videoId: video.id,
                                      userId: currentUserId,
                                      vidOwnerId: video.userId,
                                    )),
                                  );

                                  return InkWell(
                                    onTap: () {
                                      ref
                                          .read(
                                            likeProvider((
                                              videoId: video.id,
                                              userId: currentUserId,
                                              vidOwnerId: video.userId,
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          loading: () => const Text(
                                            "...",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          error: (_, __) => const Text(
                                            "0",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled:
                                        true, // important for full/half screen
                                    backgroundColor:
                                        Colors.grey.shade800, // optional
                                    builder: (context) {
                                      return CommentSection(
                                        videoId: video.id,
                                        userId: video.userId,
                                        vidOwnerId: video.userId,
                                      );
                                    },
                                  );
                                },
                                icon: Icon(
                                  Icons.comment,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                               Consumer(
                            builder: (context, ref, _) {
                              final asyncCount = ref.watch(
                                commentCountProvider(video.id),
                              );

                              return asyncCount.when(
                                data: (count) => Text(
                                  count.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                loading: () => const Text("..."),
                                error: (e, _) => Text("0"),
                              );
                            },
                          ),
                              const SizedBox(height: 20),

                              //share
                              IconButton(
                                onPressed: () async {
                                  await Share.share(
                                    'Check out this video on Dopa Shorts!\n$getVideoUrl',
                                    subject: 'Dopa Shorts',
                                  );
                                },
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 20),
                              IconButton(
                                onPressed: () => CustomDialog.show(
                                  context: context,
                                  title: "Delete",
                                  message:
                                      "Are you sure you want to delete this video?",
                                  icon: Icons.delete,
                                  onConfirmed: () async {
                                    final notifier = ref.read(
                                      userVideoProvider(userId).notifier,
                                    );
                                    await notifier.deleteVideo(
                                      video,
                                      video.videoUrl,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }
}
