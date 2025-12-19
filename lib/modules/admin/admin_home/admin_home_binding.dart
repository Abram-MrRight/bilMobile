import 'package:chat_app/services/api/api_repository.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'admin_home_controller.dart';

class AdminHomeBinding extends Bindings {
  @override
  void dependencies() {

    // Initialize HomeController with ApiRepository
    // Use permanent: true so it stays alive for the app lifecycle
    Get.put(AdminHomeController(apiRepository: ApiRepository()), permanent: true);
  }
}
