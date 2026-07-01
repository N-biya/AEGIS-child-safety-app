/// Free raster basemap tiles for AEGIS — no API key, no billing.
///
/// Uses CARTO's free basemaps (built on OpenStreetMap data): a light "voyager"
/// style for light theme and "dark_all" for dark theme, so the map matches the
/// app's Velvet Night / Warm Blossom themes. Attribution to OSM + CARTO is
/// required and shown on the map.
class MapTiles {
  static const String light =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  static const String dark =
      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  static String urlFor(bool isDark) => isDark ? dark : light;

  /// Sent as the tile request User-Agent (CARTO/OSM usage policy).
  static const String userAgent = 'com.aegis.aegis';

  static const String attribution = '© OpenStreetMap  ·  © CARTO';
}
