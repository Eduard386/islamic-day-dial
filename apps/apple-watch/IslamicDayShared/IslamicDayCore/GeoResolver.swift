import Foundation
import CoreLocation

/// Resolve location: GPS first, IP (ipapi) fallback, timezone fallback, Mecca default.

public enum GeoSource {
    case gps
    case ip
    case timezone
    case `default`
}

public struct GeoResolveResult {
    public let location: Location
    public let source: GeoSource
    public let offline: Bool
    public let country: String?
    public let city: String?
    public let region: String?

    public init(location: Location, source: GeoSource, offline: Bool, country: String? = nil, city: String? = nil, region: String? = nil) {
        self.location = location
        self.source = source
        self.offline = offline
        self.country = country
        self.city = city
        self.region = region
    }
}

extension GeoSource {
    public var apiValue: String {
        switch self {
        case .gps: return "gps"
        case .ip: return "ip"
        case .timezone: return "timezone"
        case .default: return "default"
        }
    }
}

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

private final class LocationCoordinator: NSObject, CLLocationManagerDelegate {
    private var continuation: CheckedContinuation<Location?, Never>?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() async -> Location? {
        await withCheckedContinuation { cont in
            continuation = cont
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if let c = continuation {
                    continuation = nil
                    c.resume(returning: nil)
                }
            }
            let status: CLAuthorizationStatus
            if #available(iOS 14.0, *) {
                status = manager.authorizationStatus
            } else {
                status = CLLocationManager.authorizationStatus()
            }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                continuation = nil
                cont.resume(returning: nil)
            @unknown default:
                continuation = nil
                cont.resume(returning: nil)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        continuation?.resume(returning: Location(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude))
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            continuation?.resume(returning: nil)
            continuation = nil
        default:
            break
        }
    }
}

@MainActor
private func getDeviceLocation() async -> Location? {
    let coordinator = LocationCoordinator()
    return await coordinator.requestLocation()
}

private struct IpApiGeo {
    let location: Location
    let country: String?
    let city: String?
    let region: String?
}

/// Fetch location and geo from ipapi.co. Returns nil on error.
private func fetchIpApiGeo() async -> IpApiGeo? {
    guard let url = URL(string: "https://ipapi.co/json/") else { return nil }
    var request = URLRequest(url: url)
    request.timeoutInterval = 3
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let lat = json["latitude"] as? Double,
              let lng = json["longitude"] as? Double else { return nil }
        let country = (json["country_name"] as? String) ?? (json["country"] as? String)
        let city = json["city"] as? String
        let region = json["region"] as? String
        return IpApiGeo(
            location: Location(latitude: lat, longitude: lng),
            country: country,
            city: city,
            region: region
        )
    } catch {
        return nil
    }
}

/// Fetch location from ipapi.co. Returns nil on error.
func fetchLocationFromIP() async -> Location? {
    await fetchIpApiGeo().map(\.location)
}

private func getTimezoneFallback(offline: Bool) -> GeoResolveResult {
    let loc = getTimezoneFallbackLocation()
    let source: GeoSource = TIMEZONE_TO_LOCATION[TimeZone.current.identifier] != nil ? .timezone : .default
    return GeoResolveResult(location: loc, source: source, offline: offline)
}

/// For testing: timezone → location fallback, Mecca when unknown.
func getTimezoneFallbackLocation() -> Location {
    let tz = TimeZone.current.identifier
    return TIMEZONE_TO_LOCATION[tz] ?? Location.mecca
}

/// GPS first, then IP, then timezone, Mecca default.
public func resolveGeoResult() async -> GeoResolveResult {
    if let loc = await getDeviceLocation() {
        return GeoResolveResult(location: loc, source: .gps, offline: false)
    }
    if let ip = await fetchIpApiGeo() {
        return GeoResolveResult(location: ip.location, source: .ip, offline: false, country: ip.country, city: ip.city, region: ip.region)
    }
    return getTimezoneFallback(offline: true)
}

/// GPS first, then IP, then timezone. Backward compatible.
public func resolveLocation() async -> Location {
    await resolveGeoResult().location
}
