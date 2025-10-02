import 'dart:io';
import 'package:dopa_shorts/Providers/view_share_provider.dart';
import 'package:dopa_shorts/screens/home_screens/profile_edit_screen.dart';
import 'package:dopa_shorts/screens/home_screens/profile_video_screen.dart';
import 'package:dopa_shorts/screens/home_screens/view_user_list.dart';
import 'package:dopa_shorts/services/auth_services/auth_services.dart';
import 'package:dopa_shorts/widgets/dialog_box.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UploadProfileScreen extends ConsumerStatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  const UploadProfileScreen({super.key, required this.routeObserver});

  @override
  ConsumerState<UploadProfileScreen> createState() =>
      _UploadProfileScreenState();
}

class _UploadProfileScreenState extends ConsumerState<UploadProfileScreen>
    with RouteAware {
  final picker = ImagePicker();
  File? _imageFile;
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<Map<String, dynamic>>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _profileFuture = _getUserProfile();
    _videosFuture = _getUserVideos();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    _refreshData();
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> _getUserVideos() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final videos = await supabase
        .from('videos')
        .select()
        .eq('user_id', user.id);
    return (videos as List).cast<Map<String, dynamic>>();
  }

  Future<void> removeTokenOnLogout() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await supabase.from('user_tokens').delete().match({
          'user_id': user.id,
          'token': token,
        });
        print("🗑️ Token removed for user: ${user.id}");
      }
    }

    // finally, sign out
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => CustomDialog.show(
              context: context,
              title: "Logout",
              message: 'Do you want to logout?',
              icon: Icons.logout,
              onConfirmed: () async {
                removeTokenOnLogout();
                final authService = AuthServices();
                await authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_profileFuture, _videosFuture]),
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
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (profile['avatar_url'] != null
                                ? NetworkImage(profile['avatar_url'])
                                      as ImageProvider
                                : const AssetImage(
                                    "assets/images/default_avatar.png",
                                  )),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileEditScreen(),
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.pink,
                          radius: 18,
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
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

                //Row for following and followers
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.all(
                          Radius.circular(5),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowListScreen(
                                  userId: profile["id"],
                                  showFollowers: true, routeObserver: widget.routeObserver,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.pink,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
                                "Followers: ${profile["follower_count"]}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    InkWell(
                      onTap: () {},
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.all(
                          Radius.circular(5),
                        ),
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
                          child: Container(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
                                "Following: ${profile["following_count"]}",
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  "Your Videos",
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
                          print("$index = ${videos[index]['thumbnail_url']}");
                          return Container(
                            key: ValueKey(videos[index]['id']),
                            color: Colors.grey.shade700,
                            child: GestureDetector(
                              onTap: () {
                                final id = Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser!
                                    .id;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileVideoScreen(
                                      userId: id,
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
                                    // ✅ Thumbnail with caching
                                    videos[index]['thumbnail_url'] != null &&
                                            videos[index]['thumbnail_url']
                                                .isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                videos[index]['thumbnail_url'],
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                                      color: Colors.grey,
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                          )
                                        : Container(
                                            color: Colors.grey,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white54,
                                            ),
                                          ),

                                    // ✅ Play icon overlay
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
