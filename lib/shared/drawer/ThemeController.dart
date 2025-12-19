import 'package:get/get.dart';

class ThemeController extends GetxController {
  var _isDarkTheme = false.obs;

  bool get isDarkTheme => _isDarkTheme.value;

  void toggleTheme() {
    _isDarkTheme.value = !_isDarkTheme.value;
    // Additional logic to apply the theme can be added here
  }
}
