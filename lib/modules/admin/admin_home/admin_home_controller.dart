import 'dart:async';
import 'package:dio/src/dio.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../../../Models/DatabaseHelper.dart';
import '../../../Models/transaction_model.dart';
import '../../../Models/upload_proof_model.dart';
import '../../../Routes/app_pages.dart';
import '../../../services/TransactionService.dart';
import '../../../services/api/api_repository.dart';
import '../../../services/storage/storage_service.dart';
import '../../client/upload_proofs/ProofBadgeService.dart';
  class AdminHomeController extends GetxController {
    final ApiRepository apiRepository;
    final Logger logger = Logger();

    late final TransactionService transactionService;

    AdminHomeController({required this.apiRepository}) {
      transactionService = TransactionService(apiRepository);
    }

    final RxBool isLoading = false.obs;
    final RxString errorMessage = ''.obs;
    final RxString currentUserName = ''.obs;
    final RxInt currentUserId = 0.obs;
    final RxBool isSyncing = false.obs;

    // In AdminHomeController
    final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
    final RxList<Proof> proofs = <Proof>[].obs;
    final RxInt activeUsersCount = 0.obs;
    final RxInt proofUpdateCount = 0.obs;


    // --- NEW: For Bottom Navigation Bar ---
    final RxInt selectedPageIndex = 0.obs;
    final RxString searchQuery = ''.obs;

    final RxInt unreadAdminProofs = 0.obs;
    RxString profileImage = ''.obs;
    final ProofBadgeService badgeService = Get.find<ProofBadgeService>();
    Timer? _pollingTimer;
    final List<String> pageRoutes = [
      Routes.ADMINHOMESCREEN,
      Routes.ADMINUPLOADPROOF,

    ];


    @override
    void onInit() {
      super.onInit();
      _initializeUserData();

      loadTransactions(forceRefresh: true);

      // Poll proofs every 60s
      _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
        await refreshUnreadProofsCount();
        await loadTransactions(forceRefresh: true);
      });
    }


    @override
    void onClose() {
      _pollingTimer?.cancel();
      super.onClose();
    }

    Future<void> _initializeUserData() async {
      await loadUserDetails();
    }

    Future<void> loadUserDetails() async {
      try {
        final userDetails = await StorageService.getUserDetails();

        if (userDetails != null) {
          currentUserName.value = userDetails['fullname'] ?? userDetails['name'] ?? '';
          currentUserId.value = userDetails['id'] as int? ?? 0;

          if (currentUserName.isEmpty) {
            logger.w('Fullname exists but is empty in user details', error: {
              'userDetails': userDetails
            });
          } else {
            logger.i('Loaded current user name: ${currentUserName.value}');
          }
          logger.i('Loaded current user ID: ${currentUserId.value}');
        } else {
          logger.w('No user details found in storage');
        }
      } catch (e) {
        // logger.e('Failed to load user full name or ID: $e');
        currentUserName.value = '';
        currentUserId.value = 0;
      }
    }
    Future<void> loadTransactions({bool forceRefresh = false}) async {
      try {
        isLoading.value = true;

        final data = await transactionService.fetchTransactions(
          forceRefresh: forceRefresh,
        );

        transactions.assignAll(data);
        transactions.refresh(); // IMPORTANT

      } catch (e) {
        logger.e("Failed to load transactions: $e");
      } finally {
        isLoading.value = false;
      }
    }

    void changePage(int index) {
      if (selectedPageIndex.value == index) return;
      selectedPageIndex.value = index;
      // Navigate to the corresponding route
      Get.offAllNamed(pageRoutes[index]);
    }

    Future<void> refreshUnreadProofsCount() async {
      try {
        final count = await DatabaseHelper().getUnreadProofsCountAdmin();
        if (unreadAdminProofs.value != count) {
          unreadAdminProofs.value = count;
        }
        // ✅ Refresh the badge service too
        await badgeService.refresh();
      } catch (e) {
        // logger.e('Failed to load unread proofs count: $e');
        unreadAdminProofs.value = 0;
      }
    }

    Future<void> markProofAsRead(Proof proof) async {
      proof.isRead.value = true;
      proof.isNewForAdmin.value = false;

      await DatabaseHelper().insertProofList(proof as List<Proof>);

      if (Get.isRegistered<ProofBadgeService>()) {
        Get.find<ProofBadgeService>().refresh();
      }
    }

    Future<void> logout() async {
      errorMessage.value = '';

      try {
        await apiRepository.logoutUser();
        await StorageService.clearAll();
        Get.offAllNamed('/login');
      } catch (e, st) {
        errorMessage.value = 'Logout failed. Please try again.';
      }
    }

    Future<void> reloadCurrentUser() async {
      try {
        final userDetails = await StorageService.getUserDetails();
        if (userDetails != null) {
          currentUserName.value = userDetails['fullname'] ?? userDetails['name'] ?? '';
          currentUserId.value = userDetails['id'] as int? ?? 0;
          profileImage.value = userDetails['profile_image'] ?? '';
        } else {
          currentUserName.value = '';
          currentUserId.value = 0;
          profileImage.value = '';
        }
        logger.i('Reloaded current user: ${currentUserName.value}');
      } catch (e) {
        logger.e('Failed to reload user: $e');
      }
    }


  }