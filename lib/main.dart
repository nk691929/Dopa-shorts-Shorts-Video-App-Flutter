import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dopa_shorts/screens/dynamic_video_screen.dart';
import 'package:dopa_shorts/screens/home_screens/others_profile_screen.dart';
import 'package:dopa_shorts/utils/notifiaction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:app_links/app_links.dart';

// Screens
import 'package:dopa_shorts/screens/splash_screen.dart';
import 'package:dopa_shorts/screens/auth_screen/login_screen.dart';
import 'package:dopa_shorts/screens/auth_screen/signup_screen.dart';
import 'package:dopa_shorts/screens/auth_screen/forgot_password.dart';
import 'package:dopa_shorts/screens/home_screens/home_screen.dart';
import 'package:dopa_shorts/screens/home_screens/home_tabs.dart';
import 'package:dopa_shorts/screens/home_screens/profile_screen.dart';

// Services
import 'package:dopa_shorts/services/auth_services/auth_gate.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// -------------------------------
/// Local Notifications Plugin
/// -------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final SUPABASE_URL = "https://fpfalmifcswyqxlwtzvt.supabase.co";
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// -------------------------------
/// Background Notification Handler
/// -------------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  // Show local notification with payload
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? message.data['title'],
    message.notification?.body ?? message.data['body'],
    platformDetails,
    payload: jsonEncode(message.data), // <-- attach payload
  );
}

//Configure background service func onStart task 2
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fpfalmifcswyqxlwtzvt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwZmFsbWlmY3N3eXF4bHd0enZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2OTcwOTMsImV4cCI6MjA3MjI3MzA5M30.XP3VktHD5BENmJCbFHUf5tIvgmzqIzV8W_4AiQsE6wk',
  );

  service.on("upload_video").listen((event) async {
    try {
      if (event == null) return;

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final videoPath = event["video_path"];
      final caption = event["caption"];

      final fileName =
          "${user.id}/${DateTime.now().millisecondsSinceEpoch}.mp4";
      final dio = Dio();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(videoPath, filename: fileName),
      });

      final storageUrl = "$SUPABASE_URL/storage/v1/object/videos/$fileName";

      await dio.post(
        storageUrl,
        data: formData,
        options: Options(
          headers: {
            'Authorization':
                'Bearer ${supabase.auth.currentSession!.accessToken}',
          },
        ),
        onSendProgress: (sent, total) {
          final progress = sent / total;
          service.invoke("upload_progress", {"progress": progress});
          NotificationHelper.show((progress * 100).toInt());
        },
      );

      // Insert into videos table
      final response = await supabase
          .from('videos')
          .insert({
            'user_id': user.id,
            'video_path': fileName,
            'caption': caption,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final videoId = response['id'] as String;

      // Generate thumbnail
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );

      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        final thumbnailName = "${user.id}/${videoId}_thumb.jpg";

        await supabase.storage
            .from('thumbnails')
            .upload(thumbnailName, thumbnailFile);

        final thumbnailUrl = supabase.storage
            .from('thumbnails')
            .getPublicUrl(thumbnailName);

        await supabase
            .from('videos')
            .update({
              'thumbnail_url': thumbnailUrl,
              'thumbnail_path': thumbnailName,
            })
            .eq('id', videoId);
      }

      service.invoke("upload_done");
      NotificationHelper.show(100);
      service.stopSelf();
    } catch (e) {
      service.invoke("upload_error", {"error": e.toString()});
      service.stopSelf();
    }
  });
}

/// -------------------------------
/// Main Function
/// -------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fpfalmifcswyqxlwtzvt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwZmFsbWlmY3N3eXF4bHd0enZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2OTcwOTMsImV4cCI6MjA3MjI3MzA5M30.XP3VktHD5BENmJCbFHUf5tIvgmzqIzV8W_4AiQsE6wk',
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  // Setup token refresh listener if user is logged in
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user != null) {
    setupTokenRefreshListener();
  }

  // Load environment variables
  await dotenv.load(fileName: ".env");

  //Configure background service task 4
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    "upload_channel",
    "Upload Video",
    description: "This channel is used for video upload notifications.",
    importance: Importance.low,
  );

  //Configure background service task 5
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  //Configure background service task 1
  FlutterBackgroundService().configure(
    iosConfiguration: IosConfiguration(onForeground: onStart),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      autoStartOnBoot: false,
      notificationChannelId: "upload_channel",
      foregroundServiceNotificationId: 12,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
  );

  // Initialize local notifications
  // const AndroidInitializationSettings androidSettings =
  //     AndroidInitializationSettings('@mipmap/ic_launcher');

  // const InitializationSettings initSettings = InitializationSettings(
  //   android: androidSettings,
  // );
  flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: (details) {
      if (details.payload != null) {
        final data = jsonDecode(details.payload!);
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => _getScreenFromNotification(data)),
        );
      }
    },
  );

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final data = message.data;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => _getScreenFromNotification(data)),
    );
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

Widget _getScreenFromNotification(Map<String, dynamic> data) {
  switch (data['event']) {
    case 'follow':
      return OthersProfileScreen(
        userId: data['actor_id'],
        routeObserver: routeObserver /*error*/,
      );
    case 'like':
    case 'comment':
      return DynamicVideoScreen(
        videoId: data['video_id'],
        routeObserver: routeObserver /*error*/,
      );
    default:
      return HomeScreen(routeObserver: RouteObserver<ModalRoute<void>>());
  }
}

/// -------------------------------
/// MyApp Widget
/// -------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      } else {
        debugPrint('Received null URI in uriLinkStream');
      }
    }, onError: (e) => debugPrint('Error in uriLinkStream: $e'));

    // Handle initial deep link
    _handleInitialLink();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? message.data['title'],
        message.notification?.body ?? message.data['body'],
        platformDetails,
      );
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleNotificationNavigation(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message.data);
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final event = data['event'];

    switch (event) {
      case 'follow':
        final userId = data['actor_id'];
        if (userId != null) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => OthersProfileScreen(
                userId: userId,
                routeObserver: routeObserver,
              ),
            ),
          );
        }
        break;

      case 'like':
      case 'comment':
        final videoId = data['video_id'];
        if (videoId != null) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => DynamicVideoScreen(
                videoId: videoId,
                routeObserver: routeObserver,
              ),
            ),
          );
        }
        break;

      default:
        print("Unknown notification type: $event");
    }
  }

  Future<void> _handleInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial deep link: $initialUri');
        _handleDeepLink(initialUri);
      } else {
        debugPrint('No initial deep link found');
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('🔗 Handling deep link: $uri');

    if (uri.scheme != 'dopashorts' || uri.host != 'email-confirm') {
      debugPrint("🚫 Not a valid dopashorts://email-confirm link");
      return;
    }

    final accessToken = uri.queryParameters['access_token'];
    final code = uri.queryParameters['code'];
    final type = uri.queryParameters['type'];
    final error = uri.queryParameters['error'];
    final errorCode = uri.queryParameters['error_code'];
    final errorDescription = uri.queryParameters['error_description'];

    debugPrint(
      "🧐 Query params → access_token: ${accessToken != null}, code: $code, type: $type, error: $error, error_code: $errorCode, error_description: $errorDescription",
    );

    final ctx = _navigatorKey.currentContext;

    // Handle errors
    if (error != null || errorCode != null || errorDescription != null) {
      debugPrint(
        '❌ Deep link contains error: $errorDescription (code: $errorCode)',
      );
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Error confirming email: $errorDescription'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      User? user;

      if (accessToken != null) {
        // Magic link flow
        debugPrint("🔑 Using access token to set session...");
        final sessionResponse = await Supabase.instance.client.auth.setSession(
          accessToken,
        );
        user = sessionResponse.user;
      } else if (code != null) {
        // Email confirmation code flow
        debugPrint("🔑 Exchanging code for session...");
        final response = await Supabase.instance.client.auth
            .exchangeCodeForSession(code);
        user = response.session.user;
      } else {
        debugPrint(
          '⚠️ Missing access_token or code in deep link. Full URI: $uri',
        );
        return;
      }

      if (user == null) {
        debugPrint("⚠️ No user object returned after session restore");
        return;
      }

      debugPrint('✅ Session restored. User: ${user.email}, ID: ${user.id}');

      // Insert user into profiles if not exists
      final existing = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        debugPrint("➕ User not found, inserting...");
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'username': user.email?.split('@')[0],
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint("✅ User inserted into profiles table");
      } else {
        debugPrint("ℹ️ User already exists in profiles table");
      }

      // Show success and navigate
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              'Email verified successfully! (type: ${type ?? 'unknown'})',
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          _navigatorKey.currentState?.pushReplacementNamed('/auth_gate');
        });
      }
    } catch (e) {
      debugPrint('❌ Error restoring session: $e');
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Error restoring session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dopa Shorts',
        navigatorKey: _navigatorKey,
        navigatorObservers: [routeObserver],
        initialRoute: '/auth_gate',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/home': (context) => HomeScreen(routeObserver: routeObserver),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/forgot': (context) => ForgotPassword(),
          '/auth_gate': (context) => AuthGate(routeObserver: routeObserver),
          '/tabs': (context) => HomeTabs(routeObserver: routeObserver),
          '/profile': (context) =>
              UploadProfileScreen(routeObserver: routeObserver),
        },
      ),
    );
  }
}

/// -------------------------------
/// FCM Token Refresh
/// -------------------------------
void setupTokenRefreshListener() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      await supabase.from('user_tokens').upsert({
        'user_id': user.id,
        'token': newToken,
      });
    }
  });
}
