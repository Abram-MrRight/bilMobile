import 'package:get/get.dart';

import '../../../services/api/api_repository.dart';
import 'admin_proofs_controller.dart';

class AdminProofsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminProofsController>(
          () => AdminProofsController(apiRepository: Get.find<ApiRepository>()),
    );
  }
}
