import 'package:dopa_shorts/screens/dynamic_video_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkHandler extends StatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  const DeepLinkHandler({super.key, required this.routeObserver});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    // Handle initial link (when app is opened from a link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Handle link when app is already running
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) {
        print("Deep link error: $err");
      },
    );
  }

  void _handleDeepLink(Uri uri) async {
    print("🔗 Deep link received: $uri");

    // Case 1: Watch video link
    if (uri.host == "watch") {
      final videoId = uri.queryParameters["id"];
      if (videoId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicVideoScreen(
              videoId: videoId,
              routeObserver: widget.routeObserver,
            ),
          ),
        );
      }
    }

    // Case 2: Supabase email confirmation
    if (uri.host == "email-confirm") {
      final refreshToken = uri.queryParameters["refresh_token"];

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await Supabase.instance.client.auth.setSession(refreshToken);
          print("✅ Email verified & Supabase session restored");

          // Optionally navigate to home after verification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Email verified successfully!")),
            );
            // Example: Navigate to home/dashboard
            // Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (e) {
          print("❌ Error restoring session: $e");
        }
      } else {
        print("⚠️ Missing refresh token in email confirmation link.");
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Home Screen")));
  }
}
