import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api/api_repository.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation, delayedAnimation, leftCurve;

  final ApiRepository api = ApiRepository();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String email = "";
  bool _autoValidate = false;
  bool _showInput = false;

  String? _infoMessage;
  Color _infoMessageColor = Colors.green;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    animation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    delayedAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
          parent: animationController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    leftCurve = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    animationController.forward();
    _showInput = true;
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Show loader
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );

      try {
        final response = await api.passwordResetRequest(email: email);
        Get.back(); // close loader

        setState(() {
          if (response['success'] == true) {
            _infoMessage =
            "A password reset link has been sent to your email: $email. Please check your inbox.";
            _infoMessageColor = Colors.white;
          } else {
            _infoMessage =
                response['message'] ?? "Unable to send reset link. Please try again.";
            _infoMessageColor = Colors.red;
          }
        });
      } on dio.DioException catch (e) {
        Get.back(); // close loader

        String message = "Something went wrong. Try again.";
        if (e.response?.data != null) {
          if (e.response!.data is Map<String, dynamic> &&
              e.response!.data.containsKey('message')) {
            message = e.response!.data['message'];
          } else {
            message = e.response!.statusMessage ?? message;
          }
        }

        setState(() {
          _infoMessage = message;
          _infoMessageColor = Colors.red;
        });
      }
    } else {
      setState(() => _autoValidate = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (!_showInput) return const SizedBox.shrink();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: [
            // Animated header (title + logo)
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.translationValues(animation.value * width, 0, 0),
                  child: Column(
                    children: [
                      const Text(
                        'Forgot Password',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: Colors.black38,
                                  offset: Offset(2, 2),
                                  blurRadius: 4)
                            ]),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: width * 0.5,
                        height: width * 0.5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Form and button animations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.translationValues(
                              leftCurve.value * width, 0, 0),
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                            onSaved: (value) => email = value!.trim(),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email, color: Colors.white),
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white24,
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(color: Colors.white)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.translationValues(
                              delayedAnimation.value * width, 0, 0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              minimumSize: Size(width, 50),
                              elevation: 8,
                            ),
                            onPressed: _submit,
                            child: const Text(
                              'Send Reset Link',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ✅ Info message displayed inline
                    if (_infoMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _infoMessageColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _infoMessageColor),
                        ),
                        child: Text(
                          _infoMessage!,
                          style: TextStyle(
                            color: _infoMessageColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Remembered password?',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
