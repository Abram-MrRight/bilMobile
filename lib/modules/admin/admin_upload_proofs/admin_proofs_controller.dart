import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Models/DatabaseHelper.dart';
import '../../../Models/upload_proof_model.dart';
import '../../../services/api/api_repository.dart';
import '../../client/upload_proofs/ProofBadgeService.dart';
import '../../client/upload_proofs/proofs_controller.dart';

class AdminProofsController extends GetxController {
  final ApiRepository apiRepository;

  AdminProofsController({required this.apiRepository});
  Timer? _autoRefreshTimer;
  final RxList<Proof> allProofs = <Proof>[].obs;
  final RxList<Proof> displayedProofs = <Proof>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Charge rules
  final RxList<Map<String, dynamic>> chargeRules = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingRules = false.obs;

  // Pagination
  final int _pageSize = 20; // Increased for better UX
  int _currentPage = 1;
  final RxBool _isLoadingMore = false.obs;

  dynamic activeProof;
  String? pendingStatus;
  String? defaultNote;

  @override
  void onInit() {
    super.onInit();
    // Start with local DB, then sync with API
    _initialLoad();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> _initialLoad() async {
    isLoading.value = true;
    try {
      // 1. Load from local DB first for immediate display
      await loadProofsFromDb();

      // 2. Sync with API in background
      fetchProofsFromApiAndSync(); // Don't await, let it run in background
    } catch (e) {
      errorMessage.value = 'Initial load failed: $e';
    } finally {
      isLoading.value = false;
    }
  }
  void _startAutoRefresh() {
    // Refresh every 30 seconds (adjust as needed)
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      // silently fetch proofs and update lists
      await fetchProofsFromApiAndSync();
    });
  }


  Future<void> fetchProofsFromApiAndSync() async {
    try {
      final apiProofs = await apiRepository.fetchAllProofs(forceRefresh: true);

      // Sort API proofs by date (newest first)
      apiProofs.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

      // Get current local proofs
      final localProofs = await DatabaseHelper().getAllProofs();
      final apiIds = apiProofs.map((p) => p.id).toSet();
      final localIds = localProofs.map((p) => p.id).toSet();

      // 1️⃣ Delete local proofs not in API
      final proofsToDelete = localProofs
          .where((local) => local.id != null && !apiIds.contains(local.id))
          .toList();

      for (var proof in proofsToDelete) {
        await DatabaseHelper().deleteProofById(proof.id!);
      }

      // 2️⃣ Insert or update API proofs
      final List<Proof> updatedProofs = [];
      for (var proof in apiProofs) {
        // Check if proof already exists locally
        final existing = localProofs.firstWhereOrNull((p) => p.id == proof.id);

        if (existing == null) {
          // New proof - mark as new for admin
          proof.isNewForAdmin.value = true;
          proof.isRead.value = false;
        } else {
          // Preserve existing read/new status
          proof.isNewForAdmin.value = existing.isNewForAdmin.value;
          proof.isRead.value = existing.isRead.value;
          proof.status.value = existing.status.value;
          proof.statusNote.value = existing.statusNote.value;
        }

        await DatabaseHelper().insertProof(proof);
        updatedProofs.add(proof);
      }

      // 3️⃣ Update UI state
      await _updateUIState(updatedProofs);

    } catch (e) {
      errorMessage.value = 'Failed to sync with server: $e';
      print('Sync error: $e');
    }
  }

  Future<void> _updateUIState(List<Proof> updatedProofs) async {
    // Sort by date (newest first)
    updatedProofs.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    // Update the main list
    allProofs.assignAll(updatedProofs);

    _isLoadingMore.value = false;
    // Reset displayed proofs for first page
    _currentPage = 1;
    final initialProofs = allProofs.take(_pageSize).toList();
    displayedProofs.value = initialProofs; // <-- Reassign a new list to trigger UI rebuild

// Load next page if needed
    await loadMoreProofs();

    // Update badge count
    _updateBadgeCount();
  }

  /// Load proofs from local DB
  Future<void> loadProofsFromDb() async {
    try {
      final localProofs = await DatabaseHelper().getAllProofs();

      // Sort by date (newest first)
      localProofs.sort((a, b) =>
          (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

      // Update the main list
      allProofs.assignAll(localProofs);

      // Reset pagination
      _currentPage = 1;
      displayedProofs.clear();
      await loadMoreProofs();

      // Update badge count
      _updateBadgeCount();

    } catch (e) {
      errorMessage.value = 'Failed to load proofs from DB: $e';
      print('DB load error: $e');
    }
  }


  /// Load more proofs for pagination
  Future<void> loadMoreProofs() async {
    if (_isLoadingMore.value || !hasMoreData) return;

    _isLoadingMore.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Small delay for smooth UX

      final startIndex = (_currentPage - 1) * _pageSize;
      final endIndex = startIndex + _pageSize;

      if (startIndex < allProofs.length) {
        final newProofs = allProofs.sublist(
          startIndex,
          endIndex.clamp(0, allProofs.length),
        );

        displayedProofs.value = [...displayedProofs, ...newProofs];
        _currentPage++;
      }
    } catch (e) {
      print('Error loading more proofs: $e');
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Add or update a single proof
  Future<void> addOrUpdateProof(Proof proof) async {
    try {
      final index = allProofs.indexWhere((p) => p.id == proof.id);

      if (index >= 0) {
        // Update existing
        allProofs[index] = proof;
      } else {
        // Insert at beginning (newest first)
        proof.isNewForAdmin.value = true;
        allProofs.insert(0, proof);
      }

      // Sort and update displayed proofs
      allProofs.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

      // Reset displayed proofs
      _currentPage = 1;
      displayedProofs.clear();
      await loadMoreProofs();

      // Update badge
      _updateBadgeCount();

    } catch (e) {
      print('Error adding/updating proof: $e');
    }
  }

  /// Mark proof as read
  Future<void> markProofAsRead(Proof proof) async {
    proof.isRead.value = true;
    proof.isNewForAdmin.value = false;

    await DatabaseHelper().insertProof(proof);

    // Update UI
    final index = allProofs.indexWhere((p) => p.id == proof.id);
    if (index >= 0) {
      allProofs[index] = proof;
      update();
    }

    // Update badge service
    if (Get.isRegistered<ProofBadgeService>()) {
      Get.find<ProofBadgeService>().refresh();
    }

    // Update displayed proofs if needed
    final displayIndex = displayedProofs.indexWhere((p) => p.id == proof.id);
    if (displayIndex >= 0) {
      displayedProofs[displayIndex] = proof;
    }

    // Update badge count
    _updateBadgeCount();
  }

  /// Update badge count
  void _updateBadgeCount() {
    if (Get.isRegistered<ProofBadgeService>()) {
      Get.find<ProofBadgeService>().refresh();
    }
  }

  /// Update proof status
  Future<String?> updateProofStatus({
    required int proofId,
    required String status,
    String? statusNote,
    int? chargeRuleId,
  }) async {
    isLoading.value = true;
    try {
      final updatedProof = await apiRepository.updateProofStatus(
        proofId: proofId,
        status: status,
        statusNote: statusNote,
        chargeRuleId: chargeRuleId,
      );


      if (updatedProof != null) {
        // Update in database
        await DatabaseHelper().insertProof(updatedProof);

        // Update in controller
        await addOrUpdateProof(updatedProof);

        // Also update in client controller if available
        if (Get.isRegistered<UploadProofController>()) {
          Get.find<UploadProofController>().addOrUpdateProof(updatedProof);
        }
      }
      return null;
    } catch (e) {
      return 'Failed to update proof status: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch charge rules
  Future<void> fetchChargeRules() async {
    isLoadingRules.value = true;
    try {
      final rulesFromApi = await apiRepository.fetchChargeRules();
      chargeRules.assignAll(rulesFromApi);
    } catch (e) {
      chargeRules.clear();
      Get.snackbar(
        'Error',
        'Failed to fetch charge rules: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingRules.value = false;
    }
  }

  bool get hasMoreData => displayedProofs.length < allProofs.length;

  int get unreadAdminBadgeCount =>
      allProofs.where((p) => p.isNewForAdmin.value).length;
}