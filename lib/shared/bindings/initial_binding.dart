import 'package:get/get.dart';

import '../../modules/admin/admin_upload_proofs/admin_proofs_controller.dart';
import '../../modules/announcements/announcement_controller.dart';
import '../../modules/client/upload_proofs/ProofBadgeService.dart';
import '../../modules/client/upload_proofs/proofs_controller.dart';
import '../../services/api/api_repository.dart';


class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiRepository>(ApiRepository(), permanent: true);
    Get.put(ProofBadgeService(), permanent: true);
    Get.put(AdminProofsController(apiRepository: Get.find()), permanent: true);
    Get.put(UploadProofController(apiRepository: Get.find()), permanent: true);
    Get.put(AnnouncementController(apiRepository: Get.find()), permanent: true);
  }
}
