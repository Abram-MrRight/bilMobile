import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  final String title;

  const SplashScreen({required this.title, Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late double width;
  late Animation<double> slideAnimation, fadeAnimation;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    slideAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    animationController.forward();

    Future.delayed(const Duration(seconds: 10), () {
      Get.offNamed('/LoginScreen');
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Column(
              children: [
                const SizedBox(height: 30),

                ///  BRAND NAME
                FadeTransition(
                  opacity: fadeAnimation,
                  child: Text(
                    'bilSend',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                ///  TAGLINE
                FadeTransition(
                  opacity: fadeAnimation,
                  child: Text(
                    'Fast • Secure • Reliable',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                const Spacer(),

                ///HERO IMAGE
                Transform.translate(
                  offset: Offset(slideAnimation.value * width, 0),
                  child: Image.asset(
                    'assets/images/SecondImage.jpg',
                    height: height * 0.22,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 25),

                /// HEADLINE
                FadeTransition(
                  opacity: fadeAnimation,
                  child: Text(
                    'Send Money Instantly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// ===== SUB HEADLINE =====
                FadeTransition(
                  opacity: fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Trusted by thousands of happy clients for fast and secure money transfers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ///  BIG LOTTIE ANIMATION
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Lottie.asset(
                    'assets/animations/businessRocket.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(),

                ///  COMPANY NAME
                FadeTransition(
                  opacity: fadeAnimation,
                  child: Text(
                    'Bior Investments LTD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
