import 'package:dopa_shorts/models/comment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CommentRepository {
  Future<Comment> addComment(String userId, String videoId, String text) async {
    final response = await supabase
        .from('comments')
        .insert({'user_id': userId, 'video_id': videoId, 'text': text})
        .select()
        .single();

    return Comment.fromMap(response);
  }

  Future<List<Comment>> getVideoComments(String videoId) async {
    final response = await supabase
        .from('comments')
        .select()
        .eq('video_id', videoId)
        .order('created_at', ascending: false);

    return (response as List).map((c) => Comment.fromMap(c)).toList();
  }
}
