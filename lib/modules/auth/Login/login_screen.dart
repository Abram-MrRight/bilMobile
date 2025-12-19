import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

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
    with SingleTickerProviderStateMixin {
  late double width;
  late Animation<double> animation,
      delayedAnimation,
      muchDelayedAnimation,
      leftCurve;
  late AnimationController animationController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginController loginController = Get.put(
    LoginController(apiRepository: Get.find()),
  );

  bool _autoValidate = false;
  bool _showPassword = false;
  late String _password;
  late String _phoneNumber;

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

  void _validateInputs() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      loginController.loginUser(_phoneNumber, _password);
    } else {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
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
              children: <Widget>[
                Transform(
                  transform: Matrix4.translationValues(animation.value * width, 0, 0),
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
                            padding: const EdgeInsets.all(22.0), // optional: reduce padding for better fit
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.fill, // cover ensures it fills the circle
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Transform(
                  transform: Matrix4.translationValues(leftCurve.value * width, 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      child: Column(
                        children: [
                          TextFormField(
                            validator: (value) {
                              if (value == null || value.trim().isEmpty || value.length < 9) {
                                return "Enter a valid phone number";
                              }
                              return null;
                            },
                            onSaved: (value) => _phoneNumber = value!.trim(),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone, color: Colors.white),
                              labelText: 'Phone Number',
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
                          const SizedBox(height: 20),
                          TextFormField(
                            validator: (val) {
                              if (val!.isEmpty) return "Enter valid password";
                              return null;
                            },
                            onSaved: (val) => _password = val!,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Colors.white),
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white24,
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(color: Colors.white)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none),
                              suffixIcon: IconButton(
                                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Transform(
                  transform: Matrix4.translationValues(delayedAnimation.value * width, 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Get.to(() => ForgetPassword());
                        },
                        child: const Text(
                          "Forgot password?",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Transform(
                  transform: Matrix4.translationValues(muchDelayedAnimation.value * width, 0, 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
                      onPressed: _validateInputs,
                      child: Obx(() {
                        return loginController.isLoading.value
                            ? const CircularProgressIndicator(color: Colors.teal)
                            : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New here?', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.REGISTER),
                      child: const Text('Register',
                          style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
