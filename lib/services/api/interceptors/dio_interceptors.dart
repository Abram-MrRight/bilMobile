import 'package:dio/dio.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';

class DioInterceptors extends InterceptorsWrapper {
  @override
  @override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // final showLoader = options.extra['showLoader'] == true;

    // if (showLoader) {
    //   EasyLoading.show(status: 'Loading...');
    // }

    return handler.next(options);
  }


  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // EasyLoading.dismiss();
    return handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // EasyLoading.dismiss();
    if (err.response?.statusCode == 400 && err.response?.data != null) {
      final error = err.response?.data['error'] ?? 'Something went wrong.';
      // EasyLoading.showToast(error.toString());
    } else if (err.response?.statusCode == 401) {
      // EasyLoading.showToast('Unauthorized. Please login again.');
      // You can add logout or navigation to login here if needed
    }
    return handler.next(err);
  }
}
