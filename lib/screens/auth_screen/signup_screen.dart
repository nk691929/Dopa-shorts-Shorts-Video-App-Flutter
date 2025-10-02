import 'package:dopa_shorts/screens/auth_screen/login_screen.dart';
import 'package:dopa_shorts/services/auth_services/auth_services.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final secondPasswordController = TextEditingController();
  var _obscureText = false;
  bool isLoading = false;

  void signUp() async {
    setState(() {
      isLoading = true;
    });
    final authSerice = AuthServices();

    final email = emailController.text;
    final password = passwordController.text;
    final secondPassword = secondPasswordController.text;

    if (password != secondPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Password does't match!")));
      return;
    }

    try {
      final response = await authSerice.signUpWithEmailAndPassword(
        email,
        password,
      );

      if (response?.user != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Sign Up! Check your mail")));
        setState(() {
          isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        print(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$e")));
      }
      setState(() {
        isLoading = false;
      });
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
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
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

                        TextFormField(
                          controller: secondPasswordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscureText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
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
                              "Enter Pssword again",
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
                              onTap: () => signUp(),
                              child: Center(
                                child: isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        "SignUp",
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
                              "Already Have an Account? ",
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
                                  '/login',
                                );
                              },
                              child: Text(
                                "Login",
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
