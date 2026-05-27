import 'package:dio/dio.dart';

import '../Models/DatabaseHelper.dart';
import '../Models/transaction_model.dart';
import 'api/api_constants.dart';
import 'api/api_repository.dart';
import 'api/interceptors/dio_client.dart';

class TransactionService {
  final ApiRepository apiRepository;

  TransactionService(this.apiRepository);

  Future<List<TransactionModel>> fetchTransactions({
    int page = 1,
    int pageSize = 10,
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh) {
        final response = await DioClient.client.get(
          ApiConstants.getTransactions,
          queryParameters: {
            'page': page,
            'page_size': pageSize,
          },
        );

        final List list = response.data['data'];

        final transactions = list
            .map((json) => TransactionModel.fromJson(json))
            .toList();

        await DatabaseHelper().clearTransactions();
        await DatabaseHelper().insertTransactionList(transactions);

        return transactions;
      }

      final local = await DatabaseHelper().getAllTransactions();
      if (local.isNotEmpty) return local;

      return fetchTransactions(forceRefresh: true);
    } catch (e) {
      return await DatabaseHelper().getAllTransactions();
    }
  }
}