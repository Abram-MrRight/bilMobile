import 'package:get/get.dart';
import '../../services/api/api_repository.dart';
import 'announcement_controller.dart';

class AnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure ApiRepository is already registered in the app
    final apiRepository = Get.find<ApiRepository>();

    // Put AnnouncementController in memory permanently
    Get.put<AnnouncementController>(
      AnnouncementController(apiRepository: apiRepository),
      permanent: true,
    );
  }
}
