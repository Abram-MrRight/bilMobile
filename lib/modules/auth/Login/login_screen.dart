import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Routes/app_pages.dart';
import 'forgot_password.dart';
import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  final String title;

  const LoginScreen({required this.title, Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late double width;

  // 🎬 Entry animations
  late AnimationController entryController;
  late Animation<double> slideAnimation;
  late Animation<double> delayedAnimation;
  late Animation<double> muchDelayedAnimation;

  // 🔵 Orbit animation
  late AnimationController orbitController;
  late Animation<double> orbitAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginController loginController =
  Get.put(LoginController(apiRepository: Get.find()));

  bool _autoValidate = false;
  bool _showPassword = false;
  late String _password;
  late String _phoneNumber;

  @override
  void initState() {
    super.initState();

    /// ENTRY CONTROLLER
    entryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    slideAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: entryController, curve: Curves.easeOut),
    );

    delayedAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: entryController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    muchDelayedAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: entryController,
        curve: const Interval(0.6, 1, curve: Curves.easeOut),
      ),
    );

    entryController.forward();

    /// ORBIT CONTROLLER
    orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    orbitAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(orbitController);
  }

  @override
  void dispose() {
    entryController.dispose();
    orbitController.dispose();
    super.dispose();
  }

  void _validateInputs() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      loginController.loginUser(_phoneNumber, _password);
    } else {
      setState(() => _autoValidate = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: entryController,
      builder: (context, _) {
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
                /// TITLE + LOGO
                Transform(
                  transform:
                  Matrix4.translationValues(slideAnimation.value * width, 0, 0),
                  child: Column(
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// LOGO WITH RUNNING / COMET DOT
                      SizedBox(
                        width: width * 0.45,
                        height: width * 0.45,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Logo
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(22),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // Running comet trail
                            AnimatedBuilder(
                              animation: orbitAnimation,
                              builder: (_, __) {
                                final radius = (width * 0.45) / 2;

                                return Stack(
                                  children: List.generate(5, (index) {
                                    final double angle =
                                        orbitAnimation.value - (index * 0.35);
                                    final double opacity = (1 - (index * 0.18)).clamp(0.0, 1.0);
                                    final double size = (10 - index * 1.5).clamp(4.0, 10.0);

                                    return Transform.translate(
                                      offset: Offset(
                                        radius * cos(angle),
                                        radius * sin(angle),
                                      ),
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Container(
                                          width: size,
                                          height: size,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.yellowAccent,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.yellow.withOpacity(opacity),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// FORM
                Transform(
                  transform:
                  Matrix4.translationValues(delayedAnimation.value * width, 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      child: Column(
                        children: [
                          _inputField(
                            icon: Icons.phone,
                            label: "Phone Number",
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                            v == null || v.length < 9 ? "Invalid phone number" : null,
                            onSaved: (v) => _phoneNumber = v!,
                          ),
                          const SizedBox(height: 20),
                          _inputField(
                            icon: Icons.lock,
                            label: "Password",
                            obscure: !_showPassword,
                            validator: (v) => v!.isEmpty ? "Enter password" : null,
                            onSaved: (v) => _password = v!,
                            suffix: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// FORGOT PASSWORD
                Transform(
                  transform:
                  Matrix4.translationValues(delayedAnimation.value * width, 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Get.to(() => ForgetPassword()),
                        child: const Text(
                          "Forgot password?",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                /// LOGIN BUTTON
                Transform(
                  transform:
                  Matrix4.translationValues(muchDelayedAnimation.value * width, 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ElevatedButton(
                      onPressed: _validateInputs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Obx(() {
                        return loginController.isLoading.value
                            ? const CircularProgressIndicator(color: Colors.teal)
                            : const Text(
                          "Login",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// REGISTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New here?", style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.REGISTER),
                      child: const Text(
                        "Register",
                        style: TextStyle(
                            color: Colors.yellowAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputField({
    required IconData icon,
    required String label,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Function(String?)? onSaved,
  }) {
    return TextFormField(
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
