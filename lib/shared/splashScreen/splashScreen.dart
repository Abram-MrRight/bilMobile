import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  final String title;

  const SplashScreen({required this.title, Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late double width;
  late Animation<double> animation, delayedAnimation, muchDelayedAnimation, leftCurve;
  late AnimationController animationController;

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
      CurvedAnimation(parent: animationController, curve: Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    muchDelayedAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Interval(0.8, 1.0, curve: Curves.easeIn)),
    );

    leftCurve = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    animationController.forward();

    // Navigate to the home screen after a delay
    Future.delayed(Duration(seconds: 10), () {
      Get.offNamed('/LoginScreen'); // Use GetX to navigate to the home screen
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
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Transform(
                  transform: Matrix4.translationValues(animation.value * width, 0.0, 0.0),
                  child: Text(
                    'BILchat!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 5.0),
                Transform(
                  transform: Matrix4.translationValues(leftCurve.value * width, 0, 0),
                  child: Container(
                    alignment: Alignment.center,
                    width: width, // Ensure the container takes the full width of the screen
                    height: MediaQuery.of(context).size.height * 0.4, // Adjust height as needed
                    child: Image.asset(
                      'assets/images/SecondImage.jpg', // Your logo image
                      fit: BoxFit.contain, // You can also use BoxFit.cover
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Transform(
                  transform: Matrix4.translationValues(animation.value * width, 0.0, 0.0),
                  child: Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 20.0),
                Transform(
                  transform: Matrix4.translationValues(muchDelayedAnimation.value * width, 0, 0),
                  child: Text(
                    'Powered by Bior Investments',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
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
