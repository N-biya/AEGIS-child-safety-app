import 'package:url_launcher/url_launcher.dart';

/// Opens a coordinate in the real Google Maps app (or the browser) using a
/// plain Google Maps URL — the same trick that needs NO API key and NO billing.
///
/// This is how you get "real Google Maps" for free: instead of embedding the
/// (billed) Google Maps SDK, we hand a `https://maps.google.com/?q=lat,lng`
/// link to whatever maps app the phone has.
class MapsLauncher {
  /// Show [lat],[lng] as a pin in Google Maps.
  static Future<bool> openLocation(double lat, double lng) {
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    return _launch(uri);
  }

  /// Open turn-by-turn directions TO [lat],[lng] in Google Maps.
  static Future<bool> openDirections(double lat, double lng) {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    return _launch(uri);
  }

  /// Opens the Google Maps app (or browser) ready to search for a place.
  static Future<bool> openSearch() {
    return _launch(Uri.parse('https://www.google.com/maps/search/'));
  }

  /// A ready-to-share Google Maps link for a coordinate (used in SMS/alerts).
  static String linkFor(double lat, double lng) =>
      'https://maps.google.com/?q=$lat,$lng';

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
