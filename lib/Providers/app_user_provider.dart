import 'dart:io';
import 'package:dopa_shorts/models/app_user.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserState {
  final bool isLoading;
  final AppUser? user;

  UserState({required this.isLoading, this.user});

  factory UserState.loading() => UserState(isLoading: true);
  factory UserState.data(AppUser user) =>
      UserState(isLoading: false, user: user);
}

class UserNotifier extends StateNotifier<UserState> {
  final SupabaseClient supabase;

  UserNotifier(this.supabase) : super(UserState.loading()) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      state = UserState(isLoading: false, user: null);
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle(); // returns null if not found

      if (data != null) {
        state = UserState.data(AppUser.fromMap(data));
      } else {
        state = UserState(isLoading: false, user: null);
      }
    } catch (e) {
      state = UserState(isLoading: false, user: null);
      print('Error loading user: $e');
    }
  }

  Future<void> updateProfile({String? fullName,String? username, File? newProfilePic}) async {
    if (state.user == null) return;

    final currentUser = state.user!;
    Map<String, dynamic> updates = {};

    // Update full_name
    if (fullName != null && fullName.isNotEmpty) {
      updates['full_name'] = fullName;
    }

     if (username != null && username.isNotEmpty) {
      updates['username'] = username;
    }

    // Upload new profile picture
    if (newProfilePic != null) {
      final fileName = path.basename(newProfilePic.path);
      final storagePath = 'profile_pics/${currentUser.id}/$fileName';

      try {
        await supabase.storage
            .from('profiles')
            .upload(storagePath, newProfilePic);
      } catch (e) {
        print('Error uploading profile picture: $e');
        return;
      }

      // Get public URL (returns String)
      final publicUrl = supabase.storage
          .from('profiles')
          .getPublicUrl(storagePath);
      updates['avatar_url'] = publicUrl;
    }

    // Update database
    if (updates.isNotEmpty) {
      try {
        final response = await supabase
            .from('profiles')
            .update(updates)
            .eq('id', currentUser.id)
            .select();

        final updatedData =
            response as List<dynamic>?; // response is List<dynamic>
        if (updatedData != null && updatedData.isNotEmpty) {
          state = UserState.data(
            AppUser.fromMap(updatedData[0] as Map<String, dynamic>),
          );
        }
      } catch (e) {
        print('Error updating user: $e');
      }
    }
  }

  Stream<AppUser?> streamUser(String userId) {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) {
          if (event.isNotEmpty) {
            return AppUser.fromMap(event.first);
          }
          return null;
        });
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final supabase = Supabase.instance.client;
  return UserNotifier(supabase);
});

final userStreamProvider = StreamProvider.family<AppUser?, String>((ref, userId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((event) {
        if (event.isNotEmpty) {
          return AppUser.fromMap(event.first);
        }
        return null;
      });
});
