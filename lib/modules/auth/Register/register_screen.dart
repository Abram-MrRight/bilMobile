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
    with SingleTickerProviderStateMixin {
  late double width;
  late Animation<double> animation, delayedAnimation, muchDelayedAnimation, leftCurve;
  late AnimationController animationController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RegisterController controller = Get.put(
    RegisterController(apiRepository: Get.find()),
  );

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
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    muchDelayedAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );
    leftCurve = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      bool result = await controller.registerUser(
        fullname: fullname,
        email: email.isEmpty ? null : email,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        location: location.isEmpty ? null : location,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (result) Get.offAllNamed(Routes.LOGIN);
    }
  }

  InputDecoration _buildInputDecoration(String label, {bool isPassword = false, VoidCallback? toggle}) {
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
        icon: Icon(isPassword
            ? (_showPassword ? Icons.visibility : Icons.visibility_off)
            : (_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
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
      animation: animationController,
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
                Transform(
                  transform: Matrix4.translationValues(animation.value * width, 0, 0),
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
                      Container(
                        width: width * 0.5,
                        height: width * 0.5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
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
                            validator: (val) => val!.isEmpty ? 'Enter full name' : null,
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
                            validator: (val) => val!.isEmpty ? 'Enter phone number' : null,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          // Location
                          TextFormField(
                            decoration: _buildInputDecoration('Location'),
                            onSaved: (val) => location = val!.trim(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          // Password
                          TextFormField(
                            decoration: _buildInputDecoration(
                              'Password',
                              isPassword: true,
                              toggle: () => setState(() => _showPassword = !_showPassword),
                            ),
                            obscureText: !_showPassword,
                            onSaved: (val) => password = val!.trim(),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter password';
                              if (val.length < 6) return 'Password must be 6+ chars';
                              return null;
                            },
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          // Confirm Password
                          TextFormField(
                            decoration: _buildInputDecoration(
                              'Confirm Password',
                              isPassword: true,
                              toggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            obscureText: !_showConfirmPassword,
                            onSaved: (val) => confirmPassword = val!.trim(),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Confirm password';
                              if (val != password) return 'Passwords do not match';
                              return null;
                            },
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 25),
                          // Register Button
                          Transform(
                            transform: Matrix4.translationValues(muchDelayedAnimation.value * width, 0, 0),
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
                              onPressed: _submitForm,
                              child: Obx(() {
                                return controller.isLoading.value
                                    ? const CircularProgressIndicator(color: Colors.teal)
                                    : const Text(
                                  'Register',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?', style: TextStyle(color: Colors.white70)),
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
