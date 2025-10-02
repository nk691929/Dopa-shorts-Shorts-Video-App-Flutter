import 'package:dopa_shorts/Providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final viewsProvider = FutureProvider.family<int, String>((
  ref,
  String videoId,
) async {
  final supabase = ref.read(supabaseProvider);

  try {
    final response = await supabase
        .from('views')
        .select('id') // just fetch ids
        .eq('video_id', videoId);

    final list = response as List<dynamic>;
    return list.length;
  } catch (e) {
    // handle/log if you want
    return 0;
  }
});

Future<void> addView(String videoId) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    print('⚠️ No user logged in, skipping view insert');
    return;
  }

  try {
    // Check if this user already viewed this video
    final existing = await supabase
        .from('views')
        .select('id')
        .eq('video_id', videoId)
        .eq('user_id', userId) // 👈 no .toString()
        .maybeSingle();

    if (existing == null) {
      await supabase.from('views').insert({
        'user_id': userId,
        'video_id': videoId,
        // 'created_at': DateTime.now().toIso8601String(), // optional
      });
      print("✅ View added for $videoId by $userId");
    } else {
      print("ℹ️ View already exists for $videoId by $userId");
    }
  } catch (e) {
    print('❌ addView error: $e');
  }
}



final sharesProvider = FutureProvider.family<int, String>((ref, videoId) async {
  final supabase = ref.read(supabaseProvider);
  final res = await supabase
      .from('shares')
      .select('id')
      .eq('video_id', videoId)
      .count();
  return res.count;
});
