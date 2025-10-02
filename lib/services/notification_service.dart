// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles sending notifications via Supabase Edge Function
class NotificationService {
  // Your deployed Edge Function URL
  static const String _functionUrl =
      'https://fpfalmifcswyqxlwtzvt.functions.supabase.co/send-notification';

  /// Core request method
  Future<void> _sendNotification(Map<String, dynamic> payload) async {
    try {
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;

      if (accessToken == null) {
        print("❌ No auth token available, user might not be logged in.");
        return;
      }

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent: ${payload['event']}");
      } else {
        print("❌ Failed: ${response.statusCode} -> ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending notification: $e");
    }
  }

  /// Follow notification
  Future<void> sendFollow({
    required String followerId,
    required String followingId,
  }) async {
    await _sendNotification({
      'event': 'follow',
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  /// Like notification (Edge Function expects user_id & video_id)
  Future<void> sendLike({
    required String likerId,
    required String postId,
  }) async {
    await _sendNotification({
      'event': 'like',
      'user_id': likerId,   // 👈 matches Edge Function
      'video_id': postId,   // 👈 matches Edge Function
    });
  }

  /// Comment notification (Edge Function expects user_id, video_id, text)
  Future<void> sendComment({
    required String commenterId,
    required String postId,
    required String comment,
  }) async {
    await _sendNotification({
      'event': 'comment',
      'user_id': commenterId, // 👈 matches Edge Function
      'video_id': postId,     // 👈 matches Edge Function
      'text': comment,        // 👈 matches Edge Function
    });
  }
}
