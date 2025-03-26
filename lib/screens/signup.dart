import 'package:classcare/screens/login.dart';
import 'package:classcare/screens/student/hometStudent.dart';
import 'package:classcare/screens/teacher/homeTeacher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classcare/widgets/Colors.dart';
class SignupPage extends StatefulWidget {
  final String post;
  const SignupPage({super.key, required this.post});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = "Passwords do not match";
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 🔄 Send verification email
        await userCredential.user!.sendEmailVerification();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'role': widget.post,
          'name': _nameController.text.trim(),
          'isVerified': false, // Optional: Track verification status
        });

        setState(() {
          _isLoading = false;
          _errorMessage = "Verification email sent! Please check your inbox.";
        });

        // 🔄 Show a dialog prompting the user to verify their email
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Verify Your Email"),
            content: const Text(
                "A verification email has been sent to your inbox. Please verify to proceed."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginPage(post: widget.post)),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'SIGN UP',
                    style: TextStyle(
                      fontSize: 64,
                      color: Color.fromARGB(255, 101, 170, 181),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.white), // White outline
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.person, color: Colors.white),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(
                        color: Color.fromARGB(
                            255, 101, 170, 181)), // Custom text color
                    validator: (value) =>
                        value!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 20),

// Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.email, color: Colors.white),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(
                        color: Color.fromARGB(
                            255, 101, 170, 181)), // Custom text color
                    validator: (value) =>
                        value!.isEmpty ? "Enter your email" : null,
                  ),
                  const SizedBox(height: 20),

// Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(
                        color: Color.fromARGB(
                            255, 101, 170, 181)), // Custom text color
                    validator: (value) =>
                        value!.length < 6 ? "Password too short" : null,
                  ),
                  const SizedBox(height: 20),

// Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(
                        color: Color.fromARGB(
                            255, 101, 170, 181)), // Custom text color
                    validator: (value) =>
                        value!.isEmpty ? "Confirm password" : null,
                  ),

                  // Error Message
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Color.fromARGB(255, 101, 170, 181),
                          fontSize: 14),
                    ),
                  const SizedBox(height: 90),

                  // Sign Up Button (Outlined)
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 114, 196, 203),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.blueGrey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    LoginPage(post: widget.post)),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  // Already have an account? Login
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}