import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../Models/DatabaseHelper.dart';
import '../../Models/announcements.dart';
import '../../services/api/api_repository.dart';
import '../client/upload_proofs/ProofBadgeService.dart';


class AnnouncementController extends GetxController {
  final ApiRepository apiRepository;

  AnnouncementController({required this.apiRepository});

  // List of announcements
  var announcements = <Announcement>[].obs;

  // Loading states
  var isLoading = false.obs;
  var isCreating = false.obs;
  var isUpdating = false.obs;
  var isDeleting = false.obs;

  // Error messages
  var errorMessage = ''.obs;

  // Selected announcement for editing/viewing
  var selectedAnnouncement = Rxn<Announcement>();

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
  }

  /// Fetch all announcements
  Future<void> fetchAnnouncements() async {
    try {
      isLoading.value = true;

      // STEP 1: Load Local First
      final local = await DatabaseHelper().getLocalAnnouncements();
      if (local.isNotEmpty) {
        announcements.value = local;
        print("📌 Loaded announcements from LOCAL DB");
      }

      // STEP 2: Fetch Remote
      final response = await apiRepository.getAnnouncements();
      print('📌 Remote Announcement Response: $response');

      if (response['success'] == true) {
        final remoteList = (response['data'] as List)
            .map((e) => Announcement.fromJson(e))
            .toList();

        announcements.value = remoteList;

        // STEP 3: Save Remote into Local DB
        await DatabaseHelper().insertAnnouncementList(remoteList);

        print("💾 Saved remote announcements → local DB");

        // Refresh admin badges
        if (Get.isRegistered<ProofBadgeService>()) {
          Get.find<ProofBadgeService>().refresh();
        }
      } else {
        print("⚠️ Remote fetch failed → using local cache only");
      }
    } catch (e) {
      print("❌ Error fetching announcements: $e");
    } finally {
      isLoading.value = false;
    }
  }


  /// Create new announcement
  Future<bool> createAnnouncement({
    required String title,
    String? description,
    String? imagePath,
  }) async {
    try {
      isCreating.value = true;
      // print("[DEBUG] Creating announcement with title: $title, description: $description, imagePath: $imagePath");

      final response = await apiRepository.createAnnouncement(
        title: title,
        description: description,
        imagePath: imagePath,
      );

      // print("[DEBUG] API Response: $response");

      if (response['success'] == true) {
        await fetchAnnouncements();
        return true;
      } else {
        errorMessage.value = response['message'] ?? "Unknown error from server";
        print("[ERROR] Failed to create announcement: ${errorMessage.value}");
        return false;
      }
    } on DioException catch (dioError) {
      errorMessage.value = (dioError.response?.data.toString() ?? dioError.message)!;
      return false;
    } catch (e, stackTrace) {
      errorMessage.value = e.toString();
      // print("[EXCEPTION] $e");
      // print("[STACKTRACE] $stackTrace");
      return false;
    } finally {
      isCreating.value = false;
      // print("[DEBUG] isCreating set to false");
    }
  }


  /// Update announcement
  Future<bool> editAnnouncement({
    required int id,
    String? title,
    String? description,
    String? imagePath,
  }) async {
    try {
      isUpdating.value = true;
      final response = await apiRepository.editAnnouncement(
        id: id,
        title: title,
        description: description,
        imagePath: imagePath,
      );

      if (response['success']) {
        fetchAnnouncements();
        return true;
      } else {
        errorMessage.value = response['message'];
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Delete announcement
  Future<bool> deleteAnnouncement(int id) async {
    try {
      isDeleting.value = true;
      final response = await apiRepository.deleteAnnouncement(id);

      if (response['success']) {
        // Remove from local list
        announcements.removeWhere((a) => a.id == id);
        return true;
      } else {
        errorMessage.value = response['message'];
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  /// Select an announcement (for editing/viewing)
  void selectAnnouncement(Announcement announcement) {
    selectedAnnouncement.value = announcement;
  }

  /// Clear selected announcement
  void clearSelection() {
    selectedAnnouncement.value = null;
  }
}
