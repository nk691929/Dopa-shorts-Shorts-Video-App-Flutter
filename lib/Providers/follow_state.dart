import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'supabase_provider.dart'; // your existing provider

class FollowState {
  final int followersCount;
  final bool isFollowing;

  FollowState({required this.followersCount, required this.isFollowing});

  FollowState copyWith({
    int? followersCount,
    bool? isFollowing,
  }) {
    return FollowState(
      followersCount: followersCount ?? this.followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class FollowNotifier extends StateNotifier<AsyncValue<FollowState>> {
  final SupabaseClient supabase;
  final String userId; // profile user ID

  FollowNotifier(this.supabase, this.userId) : super(const AsyncValue.loading()) {
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      final followersRes = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', userId);

      final existing = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', userId);

      state = AsyncValue.data(
        FollowState(
          followersCount: followersRes.length,
          isFollowing: existing.isNotEmpty,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // New: Send follow notification to Edge Function
  Future<void> _sendFollowNotification(String followerId) async {
    try {
      final url = Uri.parse(
          'https://fpfalmifcswyqxlwtzvt.functions.supabase.co/send-notification');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwZmFsbWlmY3N3eXF4bHd0enZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjY5NzA5MywiZXhwIjoyMDcyMjczMDkzfQ.1RbPUG3s72UpbpOCPoTj1L7i_OGuDDWRbBLpjdvG5VM',
        },
        body: jsonEncode({
          'event': 'follow',
          'follower_id': followerId,
          'following_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> toggleFollow() async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      if (state.value?.isFollowing == true) {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', userId);
      } else {
        final insertRes = await supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
        });

        // Call notification only if follow is successful
        if (insertRes == null) {
          await _sendFollowNotification(currentUserId);
        }
      }

      await _loadFollowers();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

//test fuctions

  Future<void> toggleFollowOnBackend() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final wasFollowing = state.value?.isFollowing ?? true;

    try {
      if (wasFollowing) {
        // unfollow
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUser.id)
            .eq('following_id', userId);
      } else {
        // follow
        await supabase.from('follows').insert({
          'follower_id': currentUser.id,
          'following_id': userId,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

}

final followProviderState =
    StateNotifierProvider.family<FollowNotifier, AsyncValue<FollowState>, String>(
        (ref, userId) {
  final supabase = ref.read(supabaseProvider);
  return FollowNotifier(supabase, userId);
});
