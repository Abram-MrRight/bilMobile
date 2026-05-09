import 'package:bilSend/shared/bindings/initial_binding.dart';
import 'package:bilSend/shared/drawer/ThemeController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'Routes/app_pages.dart';
import 'modules/admin/admin_upload_proofs/admin_proofs_controller.dart';
import 'modules/announcements/announcement_controller.dart';
import 'modules/client/upload_proofs/ProofBadgeService.dart';
import 'modules/client/upload_proofs/proofs_controller.dart';
import 'services/api/api_repository.dart';


// Future<void> deleteDB() async {
//   final dbPath = await getDatabasesPath();
//   final path = join(dbPath, 'bilSend.db');
//   await deleteDatabase(path);
//   print('🗑️ Local SQLite database deleted');
// }
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // await deleteDB();


  // Register ApiRepository here
  Get.put<ApiRepository>(ApiRepository());
  Get.put(ProofBadgeService());
  Get.put(AdminProofsController(apiRepository: Get.find()));
  Get.put(UploadProofController(apiRepository: Get.find()));
  Get.put(AnnouncementController(apiRepository: Get.find()));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ThemeController themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GetMaterialApp(
        theme: themeController.isDarkTheme ? ThemeData.dark() : ThemeData.light(), // Use the public getter
        debugShowCheckedModeBanner: false,
         initialBinding: InitialBinding(),
        initialRoute: Routes.SPLASH,
        getPages: AppPages.routes,
        // builder: EasyLoading.init(),
      );
    });
  }
}


