import 'package:bilSend/modules/auth/Register/register_controller.dart';
import 'package:bilSend/services/api/api_repository.dart';
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
