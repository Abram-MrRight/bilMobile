import 'package:chat_app/modules/admin/admin_upload_proofs/admin_proofs_controller.dart';
import 'package:get/get.dart';
import 'package:chat_app/services/api/api_repository.dart';

class AdminProofsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminProofsController>(
          () => AdminProofsController(apiRepository: Get.find<ApiRepository>()),
    );
  }
}
