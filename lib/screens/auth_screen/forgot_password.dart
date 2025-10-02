import 'package:dopa_shorts/screens/auth_screen/login_screen.dart';
import 'package:dopa_shorts/services/auth_services/auth_services.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final emailController = TextEditingController();
  bool isLoading = true;

  void forgotPasswordFunc() {
    setState(() {
      isLoading = true;
    });
    final authSerice = AuthServices();

    final email = emailController.text;

    try {
      authSerice.forgotPassword(email);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Email sent for reset password")));
      setState(() {
        isLoading = false;
      });
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() {
          isLoading = false;
        });
      }
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
                          "Forgot Password",
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
                              onTap: () => forgotPasswordFunc(),
                              child: Center(
                                child: Text(
                                  "Send",
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
