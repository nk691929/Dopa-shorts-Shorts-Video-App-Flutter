import 'package:dopa_shorts/models/view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;

class ViewRepository {
  Future<View> addView(String userId, String videoId) async {
    final response = await supabase
        .from('views')
        .insert({'user_id': userId, 'video_id': videoId})
        .select()
        .single();

    return View.fromMap(response);
  }

  Future<int> getViewCount(String videoId) async {
    final response = await supabase
        .from('views')
        .select('id')
        .eq('video_id', videoId)
        .count();

    return response.count;
  }
}
