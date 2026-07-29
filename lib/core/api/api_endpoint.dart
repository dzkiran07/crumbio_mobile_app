import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();


  static const bool isPhysicalDevice = true;
  static const String _ipAddress = '192.168.137.1';
  static const int _port = 5000;

  // Base URLs
  static String get _host {
    if (isPhysicalDevice) return _ipAddress;
    if (kIsWeb || Platform.isIOS) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get serverUrl => 'http://$_host:$_port';
  static String get baseUrl => '$serverUrl/api';

  static Future<void> initialize({bool force = false}) async {}
  static Future<void> refreshResolution() async {}

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String uploadProfileImage = '/auth/me/image';
  static const String changePassword = '/auth/change-password';

  // Product endpoints
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static String productImage(String id) => '/products/$id/image';

  // Order endpoints
  static const String orders = '/orders';
  static const String myOrders = '/orders/mine';
  static const String bakerOrders = '/orders/baker';
  static const String allOrdersAdmin = '/orders/admin/all';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';

  // Payment endpoints — Khalti only (eSewa intentionally not supported)
  static const String khaltiInitiate = '/payments/khalti/initiate';
  static const String khaltiVerify = '/payments/khalti/verify';
  static const String khaltiReturnUrl = 'https://crumbio.local/payment/return';

  static String resolveMediaUrl(String path) {
    var trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;
    trimmed = trimmed.replaceAll('\\', '/');
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final uploadsIndex = trimmed.indexOf('/uploads/');
    if (uploadsIndex != -1) {
      trimmed = trimmed.substring(uploadsIndex);
    } else if (trimmed.startsWith('uploads/')) {
      trimmed = '/$trimmed';
    }

    if (trimmed.startsWith('/')) {
      return '$serverUrl$trimmed';
    }
    return '$serverUrl/$trimmed';
  }
}
