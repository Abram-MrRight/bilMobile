import 'package:bilSend/modules/admin/admin_upload_proofs/admin_proofs.dart';
import 'package:bilSend/modules/auth/Login/login_binding.dart';
import 'package:bilSend/modules/auth/Login/login_screen.dart';
import 'package:bilSend/modules/auth/Register/register_binding.dart';
import 'package:bilSend/modules/auth/Register/register_screen.dart';
import 'package:bilSend/shared/splashScreen/splashBinding.dart';
import 'package:bilSend/shared/splashScreen/splashScreen.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import '../modules/admin/admin_home/admin_home_screen.dart';
import '../modules/admin/admin_home/admin_home_binding.dart';
import '../modules/client/client_home/client_home_binding.dart';
import '../modules/client/client_home/client_home_screen.dart';
import '../modules/client/upload_proofs/proofs_binding.dart';
import '../modules/client/upload_proofs/proofs_screen.dart';
import '../shared/profile/UserProfileScreen.dart';
part 'app_routes.dart';

class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashScreen(title: 'Splash'),
      binding: SplashBinding(),
    ),
    GetPage(name: Routes.CLIENTHOMESCEEN, page: () => ClientHomeScreen(), binding: ClientHomeBinding()),

    GetPage(
      name: Routes.LOGIN,
      page: () => LoginScreen(title: 'Login'),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterScreen(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.UPLOADPROOF,
      page: () =>  UploadProofScreen(), // Placeholder for Settings Screen
      binding: UploadProofBinding(), // Uncomment if you have a binding for Settings
    ),

    //admin
    GetPage(
        name: Routes.ADMINHOMESCREEN,
        page: () => AdminHomeScreen(),
        binding: AdminHomeBinding()),

    GetPage(
      name: Routes.ADMINUPLOADPROOF,
      page: () =>  AdminProofsScreen(), // Placeholder for Settings Screen
      binding: AdminProofsBinding(), // Uncomment if you have a binding for Settings
    ),

    GetPage(
      name: Routes.PROFILE,
      page: () => UserProfileScreen(),
    ),

  ];
}
