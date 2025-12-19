import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';

import '../../../Models/DatabaseHelper.dart';


class ProofBadgeService extends GetxService {
  final RxInt unreadProofCount = 0.obs;

  Future<void> refresh() async {
    final count = await DatabaseHelper().getUnreadProofsCountAdmin();
    unreadProofCount.value = count;
    final allProofs = await DatabaseHelper().getAllProofs();
    for (var p in allProofs) {
      print("id: ${p.id}, isNewForAdmin: ${p.isNewForAdmin.value}, isRead: ${p.isRead.value}");
    }
    for (var p in allProofs) {
      print("id: ${p.id}, isRead: ${p.isRead}, statusNote: ${p.statusNote}");
    }
  }

  void increment() {
    unreadProofCount .value++;
  }
}
