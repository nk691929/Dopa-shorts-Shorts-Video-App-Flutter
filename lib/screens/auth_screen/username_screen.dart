import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserNameScreen extends StatefulWidget {
  final String userId; // Pass logged in user id

  const UserNameScreen({super.key, required this.userId});

  @override
  State<UserNameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UserNameScreen> {
  final usernameController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool checkingUser = true; // ✅ To show loader while checking

  @override
  void initState() {
    super.initState();
    _checkIfUserHasUsername();
  }

  Future<void> _checkIfUserHasUsername() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from("profiles")
          .select("username")
          .eq("id", widget.userId)
          .maybeSingle();

      if (data != null && data["username"] != null && data["username"].toString().isNotEmpty) {
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

  Future<void> saveUsername() async {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        errorMessage = "Username cannot be empty";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 🔍 Check if username already exists
      final existing = await supabase
          .from("profiles")
          .select()
          .eq("username", username)
          .maybeSingle();

      if (existing != null) {
        setState(() {
          errorMessage = "⚠️ Username already taken";
          isLoading = false;
        });
        return;
      }

      // ✅ Save username
     Map<String, dynamic> updates = {};

     if (username.isNotEmpty) {
      updates['username'] = username;
    }

     if (updates.isNotEmpty) {
      try {
        await supabase
            .from('profiles')
            .update(updates)
            .eq('id', widget.userId)
            .select();
      } catch (e) {
        print('Error updating user: $e');
      }
    }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Username saved successfully!")),
        );
        Navigator.pushReplacementNamed(context, '/tabs');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        print(e);
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // ✅ While checking if user already has a username
    if (checkingUser) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Card(
            elevation: 10,
            color: Colors.grey.shade900,
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Choose a Username",
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      fontFamily: "popins",
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.pink),
                      labelText: "Username",
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: errorMessage,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 50,
                    width: width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: InkWell(
                      onTap: isLoading ? null : saveUsername,
                      child: Center(
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Save",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "popins",
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
