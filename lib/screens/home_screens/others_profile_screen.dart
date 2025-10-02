import 'package:dopa_shorts/Providers/app_user_provider.dart';
import 'package:dopa_shorts/Providers/view_share_provider.dart';
import 'package:dopa_shorts/screens/home_screens/profile_video_screen.dart';
import 'package:dopa_shorts/screens/home_screens/view_user_list.dart';
import 'package:dopa_shorts/widgets/follow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OthersProfileScreen extends ConsumerStatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  final String userId;

  const OthersProfileScreen({
    super.key,
    required this.userId,
    required this.routeObserver,
  });

  @override
  ConsumerState<OthersProfileScreen> createState() =>
      _UploadProfileScreenState();
}

class _UploadProfileScreenState extends ConsumerState<OthersProfileScreen> {
  final picker = ImagePicker();

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final supabase = Supabase.instance.client;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', widget.userId)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> _getUserVideos() async {
    final supabase = Supabase.instance.client;

    final videos = await supabase
        .from('videos')
        .select()
        .eq('user_id', widget.userId);
    return (videos as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        future: Future.wait([_getUserProfile(), _getUserVideos()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data![0] as Map<String, dynamic>?;
          final videos = snapshot.data![1] as List<Map<String, dynamic>>;

          if (profile == null) {
            return const Center(child: Text("No profile data found."));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (profile['avatar_url'] != null
                          ? NetworkImage(profile['avatar_url']) as ImageProvider
                          : const AssetImage("assets/default_avatar.png")),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  profile['full_name'] ?? "Unknown User",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                const SizedBox(height: 20),
                //Row for following and followers
                Consumer(
                  builder: (context, ref, _) {
                    final userAsync = ref.watch(
                      userStreamProvider(profile["id"]),
                    );

                    return userAsync.when(
                      data: (user) {
                        if (user == null) {
                          return const Text("No user data");
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {},
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FollowListScreen(
                                        userId: profile["id"],
                                        showFollowers: true,
                                        routeObserver: widget.routeObserver
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: Colors.pink,
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Followers: ${user.followerCount}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {},
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FollowListScreen(
                                        userId: profile["id"],
                                        showFollowers: false,
                                        routeObserver: widget.routeObserver
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Following: ${user.followingCount}",
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text("Error: $e"),
                    );
                  },
                ),

                SizedBox(height: 10),
                FollowActionButton(profileUserId: widget.userId),
                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  "Videos",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                videos.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "You haven't uploaded any videos yet.",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                            ),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileVideoScreen(
                                    userId: profile["id"],
                                    startIndex:
                                        index, // opens from the tapped video
                                    routeObserver: widget.routeObserver,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              color:
                                  Colors.black12, // fallback background color
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // ✅ Thumbnail
                                  videos[index]['thumbnail_url'] != null &&
                                          videos[index]['thumbnail_url']
                                              .isNotEmpty
                                      ? Image.network(
                                          videos[index]['thumbnail_url'],
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.grey,
                                        ), // fallback if no thumbnail
                                  // ✅ Play icon
                                  Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.pink.shade400,
                                    size: 40,
                                  ),
                                  Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final viewsAsync = ref.watch(
                                          viewsProvider(videos[index]["id"]),
                                        );
                                        return viewsAsync.when(
                                          data: (count) => Text(
                                            "$count views",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          loading: () => Text(
                                            "...",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          error: (_, __) => Text(
                                            "0 views",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
