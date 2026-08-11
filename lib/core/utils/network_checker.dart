import 'package:connectivity_plus/connectivity_plus.dart';

/// Quick internet connectivity check before making any API call.
/// Returns false if device reports no active network connection.
class NetworkChecker {
  NetworkChecker._();

  static Future<bool> hasConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      // ConnectivityResult.none means definitely no connection
      if (results.contains(ConnectivityResult.none) && results.length == 1) {
        return false;
      }
      return true;
    } catch (_) {
      // If connectivity check itself fails, assume connected and let
      // the API call fail with a proper error message.
      return true;
    }
  }
}
