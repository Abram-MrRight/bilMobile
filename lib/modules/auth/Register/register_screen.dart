import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Routes/app_pages.dart';
import 'register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  late double width;

  // Entry animations
  late AnimationController entryController;
  late Animation<double> slideAnimation;
  late Animation<double> delayedAnimation;
  late Animation<double> muchDelayedAnimation;
  late Animation<double> leftCurve;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Orbit animation
  late AnimationController orbitController;
  late Animation<double> orbitAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RegisterController controller =
  Get.put(RegisterController(apiRepository: Get.find()));

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String fullname = '';
  String email = '';
  String phoneNumber = '';
  String location = '';
  String password = '';
  String confirmPassword = '';

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

    leftCurve = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: entryController, curve: Curves.easeInOut),
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

  void _submitForm() async {
    try {
      // Validate form first
      if (!_formKey.currentState!.validate()) {
        return;
      }

      _formKey.currentState!.save();

      // Validate that either email or phone is provided
      if (email.isEmpty && phoneNumber.isEmpty) {
        Get.snackbar(
          "Validation Error",
          "Please provide either an email address or phone number",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Validate email format if provided
      if (email.isNotEmpty && !GetUtils.isEmail(email)) {
        Get.snackbar(
          "Invalid Email",
          "Please enter a valid email address",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final result = await controller.registerUser(
        fullname: fullname,
        email: email.isEmpty ? null : email,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        location: location.isEmpty ? null : location,
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );

      if (!result) return;

      // After successful registration, proceed with OTP
      if (email.isEmpty) {
        Get.snackbar(
          "Warning",
          "Email is required for OTP verification",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        final otpResult = await controller.apiRepository.generateOtp(
          email: email,
        );

        Get.back(); // Close loading dialog

        if (otpResult['success'] == true) {
          Get.toNamed(
            Routes.OTP,
            arguments: {
              'email': email,
            },
          );
        } else {
          String errorMsg = otpResult['message'] ?? 'Failed to send OTP';
          Get.snackbar(
            "OTP Error",
            errorMsg,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        }
      } catch (otpError) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          "OTP Error",
          "Failed to send verification code. Please try again later.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "An unexpected error occurred. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label,
      {bool isPassword = false, VoidCallback? toggle}) {
    return InputDecoration(
      prefixIcon: Icon(
        isPassword ? Icons.lock : Icons.person,
        color: Colors.white,
      ),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white24,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      suffixIcon: toggle != null
          ? IconButton(
        icon: Icon(
            isPassword
                ? (_showPassword ? Icons.visibility : Icons.visibility_off)
                : (_showConfirmPassword
                ? Icons.visibility
                : Icons.visibility_off),
            color: Colors.white),
        onPressed: toggle,
      )
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: entryController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
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
                /// TITLE + LOGO WITH ORBITING COMET
                Transform(
                  transform:
                  Matrix4.translationValues(slideAnimation.value * width, 0, 0),
                  child: Column(
                    children: [
                      const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
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
                              padding: const EdgeInsets.all(20),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback if image fails to load
                                    return Container(
                                      color: Colors.teal,
                                      child: const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Orbiting comet dots
                            AnimatedBuilder(
                              animation: orbitAnimation,
                              builder: (_, __) {
                                final radius = (width * 0.45) / 2;
                                return Stack(
                                  children: List.generate(5, (index) {
                                    final double angle =
                                        orbitAnimation.value - (index * 0.35);
                                    final double opacity =
                                    (1 - (index * 0.18)).clamp(0.0, 1.0);
                                    final double size =
                                    (10 - index * 1.5).clamp(4.0, 10.0);

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
                const SizedBox(height: 25),

                /// FORM
                Transform(
                  transform: Matrix4.translationValues(leftCurve.value * width, 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Full Name
                          TextFormField(
                            decoration: _buildInputDecoration('Full Name'),
                            onSaved: (val) => fullname = val!.trim(),
                            validator: (val) =>
                            val!.isEmpty ? 'Enter full name' : null,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          // Email
                          TextFormField(
                            decoration: _buildInputDecoration('Email'),
                            onSaved: (val) => email = val!.trim(),
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          // Phone Number
                          TextFormField(
                            decoration: _buildInputDecoration('Phone Number'),
                            onSaved: (val) => phoneNumber = val!.trim(),
                            keyboardType: TextInputType.phone,
                            validator: (val) =>
                            val!.isEmpty ? 'Enter phone number' : null,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          // Location
                          // TextFormField(
                          //   decoration: _buildInputDecoration('Location'),
                          //   onSaved: (val) => location = val!.trim(),
                          //   style: const TextStyle(color: Colors.white),
                          // ),
                          // Password
                          const SizedBox(height: 10),
                          // Confirm Password
                          TextFormField(
                            controller: passwordController,
                            decoration: _buildInputDecoration(
                              'Password',
                              isPassword: true,
                              toggle: () => setState(() => _showPassword = !_showPassword),
                            ),
                            obscureText: !_showPassword,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter password';
                              if (val.length < 6) return 'Password must be 6+ chars';
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),

                          TextFormField(
                            controller: confirmPasswordController,
                            decoration: _buildInputDecoration(
                              'Confirm Password',
                              isPassword: true,
                              toggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            obscureText: !_showConfirmPassword,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Confirm password';
                              if (val != passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),
                          // Register Button
                          Transform(
                            transform: Matrix4.translationValues(
                                muchDelayedAnimation.value * width, 0, 0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                minimumSize: Size(width, 50),
                                elevation: 8,
                              ),
                              onPressed: _submitForm,
                              child: Obx(() {
                                return controller.isLoading.value
                                    ? const CircularProgressIndicator(
                                    color: Colors.teal)
                                    : const Text(
                                  'Register',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?',
                                  style: TextStyle(color: Colors.white70)),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () => Get.toNamed(Routes.LOGIN),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
