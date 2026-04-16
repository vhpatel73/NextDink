// ignore: deprecated_member_use
import 'dart:js' as js;

class JsService {
  static void fetchNearbyCourts(Function(List<String>) onResult) {
    try {
      js.context['navigator']['geolocation'].callMethod('getCurrentPosition', [
        js.allowInterop((position) {
          final lat = (position['coords']['latitude'] as num).toDouble();
          final lng = (position['coords']['longitude'] as num).toDouble();
          js.context.callMethod('_nearbyPickleballCourts', [
            lat,
            lng,
            js.allowInterop((js.JsArray results) {
              onResult(results.map((r) => r.toString()).toList());
            }),
          ]);
        }),
        js.allowInterop((_) {
          onResult([]);
        }),
      ]);
    } catch (_) {
      onResult([]);
    }
  }

  static void searchPlaces(String value, Function(List<String>) onResult) {
    try {
      js.context.callMethod('_placesSearch', [
        value,
        js.allowInterop((js.JsArray results) {
          onResult(results.map((r) => r.toString()).toList());
        }),
      ]);
    } catch (_) {
      onResult([]);
    }
  }
}
