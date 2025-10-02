import 'package:dopa_shorts/screens/auth_screen/username_screen.dart';
import 'package:dopa_shorts/services/auth_services/auth_services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var _obscureText = false;
  final authSerice = AuthServices();
  bool isLoading = false;

 void login() async {
  setState(() {
    isLoading = true;
  });

  final authSerice = AuthServices();
  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  try {
    final response = await authSerice.signInWithEmailAndPassword(
      email,
      password,
    );

    if (response.user != null) {
      final supabase = Supabase.instance.client;

      // 🔄 Refresh session to get latest user info
      await supabase.auth.refreshSession();
      final refreshedUser = supabase.auth.currentUser;

      if (refreshedUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Login failed, please try again.")),
        );
        setState(() => isLoading = false);
        return;
      }

      // ✅ Check if email confirmed
      if (refreshedUser.emailConfirmedAt != null) {
        // Save FCM token
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await supabase.from('user_tokens').upsert({
            'user_id': refreshedUser.id,
            'token': token,
          });
          print("✅ FCM token saved: $token");
        }

        // Optional: save user profile in profiles table
        // await supabase.from('profiles').upsert({
        //   'id': refreshedUser.id,
        //   'email': refreshedUser.email,
        //   'username': email.split('@')[0],
        //   'created_at': DateTime.now().toIso8601String(),
        // });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Logged in successfully!")),
        );

        setState(() => isLoading = false);

        // Navigate to UserNameScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserNameScreen(userId: refreshedUser.id),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Please confirm your email before logging in."),
          ),
        );
        setState(() => isLoading = false);
      }
    }
  } on AuthApiException catch (e) {
    if (e.code == "email_not_confirmed") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please confirm your email before logging in."),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth error: ${e.message}")),
      );
      print("AuthApiException: $e");
    }
    setState(() => isLoading = false);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      print("Error: $e");
    }
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Center(
                child: Card(
                  elevation: 10.0,
                  color: Colors.grey.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.w600,
                            fontSize: 30,
                            fontFamily: "popins",
                          ),
                        ),
                        SizedBox(
                          width: width * 0.8,
                          height: height * 0.15,
                          child: Image.asset(
                            'assets/icons/dopaIcon.png',
                            color: Colors.white,
                          ),
                        ),
                        textField(
                          "Email",
                          emailController,
                          Icon(Icons.email),
                          12,
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscureText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.grey.shade200,
                            hoverColor: Colors.pink,
                            prefixIcon: Icon(Icons.password),
                            suffixIcon: IconButton(
                              icon: _obscureText
                                  ? Icon(Icons.remove_red_eye)
                                  : Icon(Icons.remove_red_eye_outlined),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            label: Text(
                              "Password",
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            prefixIconColor: Colors.pink,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          height: 50,
                          width: width * .8,
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () => login(),
                              child: Center(
                                child: isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        "Login",
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
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have Account? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                                fontFamily: "popins",
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/signup',
                                );
                              },
                              child: Text(
                                " Sign Up",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.pink,
                                  fontFamily: "popins",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/forgot');
                          },
                          child: Text(
                            "Forgot Password",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.pink,
                              fontFamily: "popins",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextField textField(
  String label,
  TextEditingController controller,
  Icon icon,
  double rad,
) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.visiblePassword,
    style: const TextStyle(color: Colors.white, fontSize: 16),
    decoration: InputDecoration(
      prefixIcon: icon,
      focusColor: Colors.pink,
      label: Text(label, style: TextStyle(color: Colors.grey.shade400)),
      prefixIconColor: Colors.pink,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(rad)),
      ),
    ),
  );
}

ClipRRect loginButton(
  double rad,
  String title,
  Color color,
  double fontSize,
  Color textColor,
  FontWeight fontWeight,
  double height,
  double width,
  Function onPressed,
) {
  return ClipRRect(
    borderRadius: BorderRadiusGeometry.all(Radius.circular(rad)),
    child: Container(
      width: width,
      height: height,
      color: color,
      child: InkWell(
        onTap: onPressed(),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ),
    ),
  );
}
