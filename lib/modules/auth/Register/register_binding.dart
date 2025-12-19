import 'package:chat_app/modules/auth/Register/register_controller.dart';
import 'package:chat_app/services/api/api_repository.dart';
import 'package:get/get.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    // No need for ApiProvider anymore
    Get.lazyPut<ApiRepository>(() => ApiRepository());

    Get.lazyPut<RegisterController>(
      () => RegisterController(apiRepository: Get.find<ApiRepository>()),
    );
  }
}
