import 'package:dopa_shorts/models/share_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ShareRepository {
  Future<Share> shareVideo(String userId, String videoId) async {
    final response = await supabase
        .from('shares')
        .insert({'user_id': userId, 'video_id': videoId})
        .select()
        .single();

    return Share.fromMap(response);
  }

  Future<int> getShareCount(String videoId) async {
    final response = await supabase
        .from('shares')
        .select('id')
        .eq('video_id', videoId)
        .count();

    return response.count;
  }
}
