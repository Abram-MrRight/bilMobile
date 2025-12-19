import 'dart:async';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart' as dio;
import '../../../Models/Country.dart';
import '../../../Models/DatabaseHelper.dart';
import '../../../Models/upload_proof_model.dart';
import '../../../services/api/api_repository.dart';
import '../../../services/storage/storage_service.dart';
import 'ProofBadgeService.dart';

class UploadProofController extends GetxController {
  final ApiRepository apiRepository;

  UploadProofController({required this.apiRepository});

  final RxList<Proof> proofs = <Proof>[].obs; // full list
  final RxList<Proof> displayedProofs = <Proof>[].obs; // paginated list
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isFirstLoadComplete = false.obs;
  final Logger logger = Logger();
  final RxSet<String> unreadStatusProofIds = <String>{}.obs;
  var expandedProofIds = <String>{}.obs;

  final int _itemsPerPage = 4;
  int _currentPage = 1;

  var selectedCountry = Rx<Country?>(null);
  var countryList = <Country>[].obs;
  var selectedImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProofs();
    startPolling();
  }

  void startPolling() {
    Timer.periodic(Duration(seconds: 10), (_) => fetchProofs());
  }

  void _paginateProofs() {
    if (proofs.isEmpty) {
      displayedProofs.clear();
      unreadStatusProofIds.clear();
      return;
    }

    final end = _currentPage * _itemsPerPage;
    displayedProofs.assignAll(proofs.take(end.clamp(0, proofs.length)).toList());

    unreadStatusProofIds.clear();
    for (var proof in displayedProofs) {
      if (proof.statusNote.value.isNotEmpty && !proof.isRead.value) {
        unreadStatusProofIds.add(proof.id.toString());
      }
    }
  }

  void viewMore() {
    _currentPage++;
    _paginateProofs();
  }

  Future<void> fetchProofs() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final userDetails = await StorageService.getUserDetails();
      final currentUserId = userDetails?['id'];
      if (currentUserId == null) throw Exception("No user logged in.");

      // Load cached proofs (only mine)
      final cachedProofs = (await DatabaseHelper().getAllProofs())
          .where((p) => p.userId == currentUserId)
          .toList();

      cachedProofs.sort((a, b) =>
          _toDateTime(b.createdAt).compareTo(_toDateTime(a.createdAt)));

      proofs.assignAll(cachedProofs);

      _currentPage = 1;
      _paginateProofs();
      isFirstLoadComplete.value = true;

      // Fetch fresh proofs from API
      final apiProofs = await apiRepository.fetchAllProofs();
      final myApiProofs = apiProofs.where((p) => p.userId == currentUserId).toList();

      for (final proof in myApiProofs) {
        await DatabaseHelper().insertProof(proof);
        updateProofInMemory(proof);
      }

      // Reload updated proofs
      final updatedProofs = (await DatabaseHelper().getAllProofs())
          .where((p) => p.userId == currentUserId)
          .toList();

      updatedProofs.sort((a, b) =>
          _toDateTime(b.createdAt).compareTo(_toDateTime(a.createdAt)));

      proofs.assignAll(updatedProofs);

      _currentPage = 1;
      _paginateProofs();
    } catch (e) {
      logger.e('Failed to fetch fresh proofs: $e');
      errorMessage.value = 'Failed to fetch new proofs: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProof(Proof newProof) async {
    final userDetails = await StorageService.getUserDetails();
    final currentUserId = userDetails?['id'] ?? 0;

    // Ensure proper userId
    newProof.userId = currentUserId;
    newProof.isRead.value = true;         // Client has "read" their own submission
    newProof.isNewForAdmin.value = true;  // Admin should see as new

    proofs.insert(0, newProof);

    await DatabaseHelper().insertProof(newProof);

    // Notify admin controller if exists
    // if (Get.isRegistered<AdminProofsController>()) {
    //   final adminController = Get.find<AdminProofsController>();
    //   adminController.addOrUpdateProof(newProof);
    // }

    // Refresh client badge count
    final clientUnread = proofs
        .where((p) => p.userId == currentUserId && !p.isRead.value)
        .length;

    print('📌 Client added proof id=${newProof.id}, '
        'isRead=${newProof.isRead.value}, '
        'isNewForAdmin=${newProof.isNewForAdmin.value}');
    print('🔴 Unread proofs for client: $clientUnread');

    if (Get.isRegistered<ProofBadgeService>()) {
      Get.find<ProofBadgeService>().refresh();
    }

    _currentPage = 1;
    _paginateProofs();
  }

  // Add this method to your UploadProofController
  void filterProofs(String status) {
    if (status == 'all') {
      displayedProofs.value = List.from(proofs);
    } else {
      displayedProofs.value = proofs.where((proof) => proof.status.value == status).toList();
    }
  }
  Future<void> addOrUpdateProof(Proof proof) async {
    final index = proofs.indexWhere((p) => p.id == proof.id);

    if (index != -1) {
      // ✅ Update only reactive fields
      proofs[index].status.value = proof.status.value;
      proofs[index].statusNote.value = proof.statusNote.value;
      proofs[index].isRead.value = proof.isRead.value;
    } else if (proof.userId == (await StorageService.getUserDetails())?['id']) {
      proofs.insert(0, proof);
    }

    _paginateProofs();
    await DatabaseHelper().insertProof(proof);
  }

  void updateProofInMemory(Proof updatedProof) {
    final index = proofs.indexWhere((p) => p.id == updatedProof.id);
    if (index != -1) {
      proofs[index].status.value = updatedProof.status.value;
      proofs[index].statusNote.value = updatedProof.statusNote.value;
      proofs[index].isRead.value = updatedProof.isRead.value;

      if (updatedProof.statusNote.value.isNotEmpty && !updatedProof.isRead.value) {
        unreadStatusProofIds.add(updatedProof.id.toString());
      }
      _paginateProofs();
    }
  }

  Future<void> refreshProofs() async {
    await fetchProofs();
  }

  DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<Proof?> uploadProof({
    required String senderName,
    required String receiverName,
    required String receiverContact,
    required String senderEmail,
    required String amount,
    required String currency,
    required String notes,
    required String imagePath,
    required int countryId,
  }) async {
    isLoading.value = true;
    errorMessage.value = "";

    try {
      final formData = dio.FormData.fromMap({
        'sender_name': senderName,
        'receiver_name': receiverName,
        'receiver_contact': receiverContact,
        'receiver_email': senderEmail,
        'amount': amount,
        'currency': currency,
        'notes': notes,
        'image': await dio.MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
        'country_id': countryId,
      });

      final proof = await apiRepository.uploadProof(formData);

      if (proof != null) {
        await DatabaseHelper().insertProof(proof);
        addProof(proof);
        return proof;
      } else {
        errorMessage.value = "Upload failed. Try again.";
        return null;
      }
    } catch (e) {
      logger.e('Upload error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Country>> fetchCountries() async {
    try {
      return await apiRepository.fetchCountriesFromApi();
    } catch (e) {
      errorMessage.value = e.toString();
      return [];
    }
  }
}
