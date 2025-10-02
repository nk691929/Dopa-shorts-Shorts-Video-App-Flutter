import 'package:dopa_shorts/models/like_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class LikeRepository {
  Future<Like> likeVideo(String userId, String videoId) async {
    final response = await supabase
        .from('likes')
        .insert({'user_id': userId, 'video_id': videoId})
        .select()
        .single();

    return Like.fromMap(response);
  }

  Future<void> unlikeVideo(String userId, String videoId) async {
    await supabase
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('video_id', videoId);
  }

  Future<int> getLikeCount(String videoId) async {
     final res = await supabase
        .from('likes')
        .select('id')
        .eq('video_id', videoId)
        .count();

    return res.count;

  }
}
