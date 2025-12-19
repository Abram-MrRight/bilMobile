import 'package:chat_app/modules/client/upload_proofs/proofs_controller.dart';
import 'package:get/get.dart';
import 'package:chat_app/services/api/api_repository.dart';

class UploadProofBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UploadProofController>(
      () => UploadProofController(apiRepository: Get.find<ApiRepository>()),
    );
  }
}
