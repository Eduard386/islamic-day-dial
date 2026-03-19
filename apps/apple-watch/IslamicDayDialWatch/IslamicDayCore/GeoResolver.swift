import Foundation

/// Resolve location: IP first (ipapi.co), then timezone fallback.
/// No permission required.

private let TIMEZONE_TO_LOCATION: [String: Location] = [
    "Europe/Istanbul": Location(latitude: 41.0082, longitude: 28.9784),
    "Europe/London": Location(latitude: 51.5074, longitude: -0.1278),
    "Europe/Paris": Location(latitude: 48.8566, longitude: 2.3522),
    "Europe/Berlin": Location(latitude: 52.52, longitude: 13.405),
    "Europe/Kyiv": Location(latitude: 50.4501, longitude: 30.5234),
    "Asia/Riyadh": Location(latitude: 21.4225, longitude: 39.8262),
    "Asia/Dubai": Location(latitude: 25.2048, longitude: 55.2708),
    "America/New_York": Location(latitude: 40.7128, longitude: -74.006),
    "America/Los_Angeles": Location(latitude: 34.0522, longitude: -118.2437),
    "Asia/Jakarta": Location(latitude: -6.2088, longitude: 106.8456),
    "Asia/Tokyo": Location(latitude: 35.6762, longitude: 139.6503),
    "Africa/Cairo": Location(latitude: 30.0444, longitude: 31.2357),
    "Australia/Sydney": Location(latitude: -33.8688, longitude: 151.2093),
    "America/Sao_Paulo": Location(latitude: -23.5505, longitude: -46.6333),
    "Asia/Kolkata": Location(latitude: 19.076, longitude: 72.8777),
    "Europe/Moscow": Location(latitude: 55.7558, longitude: 37.6173),
]

/// Fetch location from ipapi.co. Returns nil on error.
func fetchLocationFromIP() async -> Location? {
    guard let url = URL(string: "https://ipapi.co/json/") else { return nil }
    var request = URLRequest(url: url)
    request.timeoutInterval = 3
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let lat = json["latitude"] as? Double,
              let lng = json["longitude"] as? Double else { return nil }
        return Location(latitude: lat, longitude: lng)
    } catch {
        return nil
    }
}

func getTimezoneFallbackLocation() -> Location {
    let tz = TimeZone.current.identifier
    return TIMEZONE_TO_LOCATION[tz] ?? Location.mecca
}

/// IP first, then timezone fallback.
func resolveLocation() async -> Location {
    await fetchLocationFromIP() ?? getTimezoneFallbackLocation()
}
