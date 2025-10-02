import 'package:dopa_shorts/models/comment_model.dart';
import 'package:dopa_shorts/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CommentState {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;

  CommentState({required this.comments, this.isLoading = false, this.error});

  CommentState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CommentNotifier extends StateNotifier<CommentState> {
  CommentNotifier() : super(CommentState(comments: []));

  /// Load top-level comments for a video
  Future<void> loadComments(String videoId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await supabase
          .from('comments')
          .select()
          .eq('video_id', videoId)
          .filter('parent_id', 'is', null) // <-- correct way to check NULL
          .order('created_at', ascending: false);

      final comments = (response as List)
          .map((c) => Comment.fromMap(c as Map<String, dynamic>))
          .toList();

      state = state.copyWith(comments: comments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load replies for a given comment
  Future<List<Comment>> loadReplies(String commentId) async {
    final response = await supabase
        .from('comments')
        .select()
        .eq('parent_id', commentId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((c) => Comment.fromMap(c as Map<String, dynamic>))
        .toList();
  }

  /// Add a comment (or reply if parentId provided)
  Future<void> addComment(
    String videoId,
    String userId,
    String text, {
    String? parentId,
    String? vidOwnerId,
  }) async {
    try {
      final newComment = await supabase
          .from('comments')
          .insert({
            'user_id': userId,
            'video_id': videoId,
            'text': text,
            'parent_id': parentId,
          })
          .select()
          .single();

      final comment = Comment.fromMap(newComment);
      state = state.copyWith(comments: [comment, ...state.comments]);

       final notificationService = NotificationService();
        // When user likes a post
        if ( vidOwnerId!= userId) {
          await notificationService.sendComment(commenterId: userId, postId: videoId, comment: comment.text);
        }
    } catch (e) {

      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);
      state = state.copyWith(
        comments: state.comments.where((c) => c.id != commentId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Like a comment
  Future<void> likeComment(String commentId, String userId) async {
    await supabase.from('comment_likes').insert({
      'user_id': userId,
      'comment_id': commentId,
    });
  }

  /// Unlike a comment
  Future<void> unlikeComment(String commentId, String userId) async {
    await supabase
        .from('comment_likes')
        .delete()
        .eq('user_id', userId)
        .eq('comment_id', commentId);
  }

  /// Update a comment
  Future<void> updateComment(String commentId, String newText) async {
    try {
      final updated = await supabase
          .from('comments')
          .update({'text': newText})
          .eq('id', commentId)
          .select()
          .single();

      final updatedComment = Comment.fromMap(updated);

      state = state.copyWith(
        comments: state.comments.map((c) {
          if (c.id == commentId) return updatedComment;
          return c;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<int> getCommentCount(String videoId) async {
    final res = await supabase
        .from('comments')
        .select('*') // select data (or specific columns)
        .eq('video_id', videoId) // filter by video
        .count(CountOption.exact); // <- new API (exact count)

    // `res.count` contains the total matching rows
    return res.count;
  }
}

final commentProvider = StateNotifierProvider<CommentNotifier, CommentState>((
  ref,
) {
  return CommentNotifier();
});

final commentCountProvider = FutureProvider.family<int, String>((
  ref,
  videoId,
) async {
  final response = await supabase
      .from('comments')
      .select('id')
      .eq('video_id', videoId)
      .count(CountOption.exact);

  return response.count;
});
