import 'package:dopa_shorts/Providers/auth_state_provider.dart';
import 'package:dopa_shorts/screens/home_screens/home_tabs.dart';
import 'package:dopa_shorts/screens/auth_screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends ConsumerStatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  const AuthGate({super.key, required this.routeObserver});

  @override
  ConsumerState<AuthGate> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<AuthGate> {
  bool checkingUser = true;
  var userId="";

  @override
  void initState() {
    getUserId();
    _checkIfUserHasUsername();
    super.initState();
  }

   Future<void> getUserId()async{
     userId=Supabase.instance.client.auth.currentUser!.id;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (session != null) {
      // if(checkingUser){
      return HomeTabs(routeObserver: widget.routeObserver);
      // }else{
      //   return UserNameScreen(userId: Supabase.instance.client.auth.currentUser!.id);
      // }
    } else {
      return LoginScreen();
    }
  }

  Future<void> _checkIfUserHasUsername() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from("profiles")
          .select("username")
          .eq("id", supabase.auth.currentUser!.id)
          .maybeSingle();

      if (data != null &&
          data["username"] != null &&
          data["username"].toString().isNotEmpty) {
        // ✅ Username already exists → Go to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/tabs');
        }
      }
    } catch (e) {
      print("Error checking username: $e");
    } finally {
      if (mounted) {
        setState(() {
          checkingUser = false;
        });
      }
    }
  }
}
