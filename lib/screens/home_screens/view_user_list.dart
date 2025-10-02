import 'package:dopa_shorts/screens/home_screens/others_profile_screen.dart';
import 'package:dopa_shorts/widgets/follow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Provider to fetch followers or following list
final followListProvider = FutureProvider.family
    .autoDispose<
      List<Map<String, dynamic>>,
      ({String userId, bool showFollowers})
    >((ref, params) async {
      final supabase = Supabase.instance.client;
      const relationTable = "follows";

      print(
        "🔵 Provider called with userId=${params.userId}, showFollowers=${params.showFollowers}",
      );
      print("🟡 Executing Supabase query...");

      final query = params.showFollowers
          ? supabase
                .from(relationTable)
                .select("""
            follower_id,
            follower:profiles!follows_follower_id_fkey (
              id, full_name, avatar_url
            )
            """)
                .eq('following_id', params.userId)
          : supabase
                .from(relationTable)
                .select("""
            following_id,
            following:profiles!follows_following_id_fkey (
              id, full_name, avatar_url
            )
            """)
                .eq('follower_id', params.userId);

      final data = await query;

      print("📊 Query result: $data");

      return (data as List).cast<Map<String, dynamic>>();
    });

class FollowListScreen extends ConsumerWidget {
  final String userId;
  final bool showFollowers; // true = followers list, false = following list
  final RouteObserver<ModalRoute<void>> routeObserver;

  const FollowListScreen({
    Key? key,
    required this.userId,
    required this.showFollowers,
    required this.routeObserver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = showFollowers ? "Followers" : "Following";

    print(
      "🔵 Building FollowListScreen: userId=$userId, showFollowers=$showFollowers",
    );

    final asyncUsers = ref.watch(
      followListProvider((userId: userId, showFollowers: showFollowers)),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "User's $title",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: asyncUsers.when(
        data: (users) {
          print("✅ Data received in UI: ${users.length} users");
          if (users.isEmpty) {
            return Center(
              child: Text(
                "No $title found.",
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final row = users[index];
              final user = showFollowers ? row["follower"] : row["following"];
              print("👤 Rendering user: $user");

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OthersProfileScreen(
                        userId: user['id'],
                        routeObserver: routeObserver,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: user["avatar_url"] != null
                      ? CachedNetworkImageProvider(user["avatar_url"])
                      : const AssetImage("assets/images/default_avatar.png")
                            as ImageProvider,
                ),
                title: Text(
                  user["full_name"] ?? "Unknown",
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: FollowActionButton(profileUserId:user['id'] ),
              );
            },
          );
        },
        loading: () {
          print("⏳ UI in loading state...");
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, st) {
          print("❌ Error in UI: $e\n$st");
          return Center(
            child: Text(
              "Error loading $title",
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
