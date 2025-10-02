import 'package:dopa_shorts/Providers/comment_provider.dart';
import 'package:dopa_shorts/Providers/like_notifier.dart';
import 'package:dopa_shorts/Providers/video_feed_provider.dart';
import 'package:dopa_shorts/screens/home_screens/others_profile_screen.dart';
import 'package:dopa_shorts/screens/home_screens/search_screen.dart';
import 'package:dopa_shorts/widgets/comment_section.dart';
import 'package:dopa_shorts/widgets/follow_button.dart';
import 'package:dopa_shorts/widgets/video_player_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends ConsumerWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  HomeScreen({super.key, required this.routeObserver});
  // final Map<String, GlobalKey<VideoPlayerComponentState>> _videoKeys = {};

  void shareVideo(String videoId) {
    final link = "https://dopashorts.com/watch?id=$videoId";
    Share.share("Check out this video! $link");
  }

  final currentuserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoFeed = ref.watch(videoFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        scrolledUnderElevation: 0,
        title: Text(
          "Shorts",
          style: TextStyle(
            color: Colors.pink,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchUsersScreen(routeObserver: routeObserver),
                ),
              );
            },
            icon: const Icon(Icons.search, color: Colors.white, size: 25),
          ),
        ],
      ),
      body: videoFeed.when(
        data: (videos) {
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];

              // Assign a key for each video
              // final videoKey = _videoKeys.putIfAbsent(
              //   video.id,
              //   () => GlobalKey<VideoPlayerComponentState>(),
              // );

              final supabase = Supabase.instance.client;
              final getVideoUrl = supabase.storage
                  .from('videos')
                  .getPublicUrl(video.videoUrl);

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Stack(
                  children: [
                    VideoPlayerComponent(
                      videoUrl: getVideoUrl,
                      routeObserver: routeObserver,
                      videoId: video.id,
                    ),
                    Positioned(
                      right: 16,
                      bottom: 80,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // videoKey.currentState?.pauseVideo();
                              if (Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser!
                                      .id !=
                                  video.userId) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OthersProfileScreen(
                                      userId: video.userId,
                                      routeObserver: routeObserver,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/profile');
                              }
                            },
                            child:
                                Supabase.instance.client.auth.currentUser!.id !=
                                    video.userId
                                ? SizedBox(
                                    width: 50,
                                    height: 90,
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            video.profileImageUrl,
                                          ),
                                          radius: 25,
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          child: FollowActionButton(
                                            profileUserId: video.userId,
                                            height: 30,
                                            width: 50,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      video.profileImageUrl,
                                    ),
                                    radius: 25,
                                  ),
                          ),
                          const SizedBox(height: 20),
                          // ❤️ Like button
                          // inside your video card Stack → Positioned → Column
                          Consumer(
                            builder: (context, ref, _) {
                              final currentUserId =
                                  Supabase.instance.client.auth.currentUser!.id;
                              final likeAsync = ref.watch(
                                likeProvider((
                                  videoId: video.id,
                                  userId: currentUserId,
                                  vidOwnerId: video.userId,
                                )),
                              );

                              return InkWell(
                                onTap: () async {
                                  ref
                                      .read(
                                        likeProvider((
                                          videoId: video.id,
                                          userId: currentUserId,
                                          vidOwnerId: video.userId,
                                        )).notifier,
                                      )
                                      .toggleLike();
                                  // );
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
                                    userId: currentuserId,
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
                          IconButton(
                            onPressed: () async {
                              // final videoId = video.id;
                              // final deepLink = 'dopashorts://watch?id=$videoId';
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
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(err.toString(), style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
