import 'package:get/get.dart';

class SplashController extends GetxController {
  var currentIndex = 0.obs;

  void nextPage() {
    if (currentIndex < 2) {
      currentIndex++;
    } else {
      // Navigate to the main screen
      Get.offNamed('/home');
    }
  }

  void previousPage() {
    if (currentIndex > 0) {
      currentIndex--;
    }
  }
}
