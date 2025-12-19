import 'package:chat_app/services/api/api_repository.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'client_home_controller.dart';

class ClientHomeBinding extends Bindings {
  @override
  void dependencies() {

    // Initialize HomeController with ApiRepository
    Get.put(ClientHomeController(apiRepository: ApiRepository()), permanent: true);
  }
}
