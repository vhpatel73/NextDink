import 'package:flutter/foundation.dart';

/// A stub class that does nothing on non-web platforms.
class JsService {
  static void fetchNearbyCourts(Function(List<String>) onResult) {
    debugPrint('Native: fetchNearbyCourts not applicable on mobile.');
    onResult([]);
  }

  static void searchPlaces(String value, Function(List<String>) onResult) {
    debugPrint('Native: searchPlaces not applicable on mobile.');
    onResult([]);
  }
}
