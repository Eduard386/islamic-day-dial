import Foundation
import OSLog

private let visitLogger = Logger(subsystem: "com.islamicdaydial.analytics", category: "visits")

/// Tracks app opens to Supabase visits table.
/// Configure SupabaseURL and SupabaseAnonKey in target Info (or INFOPLIST_KEY_* build settings).
/// Supply values via `IslamicDayDial/Config.xcconfig` (must be listed under target **configFiles** in `project.yml`).
/// No-ops when not configured.
func trackVisit(geo: GeoResolveResult, platform: String = "ios", surface: String = "ios_app") async {
    guard let url = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
          !url.isEmpty, !url.contains("your-project"),
          let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
          !key.isEmpty, !key.contains("your-anon")
    else {
        #if DEBUG
        visitLogger.debug("Skipping visit: SupabaseURL/SupabaseAnonKey missing or placeholder in Info.plist (add IslamicDayDial/Config.xcconfig to target configFiles and rebuild).")
        #endif
        return
    }
    // Unsubstituted build settings end up in the plist; xcconfig URLs without quotes truncate at `//`.
    if url.contains("$(") || key.contains("$(") {
        #if DEBUG
        visitLogger.debug("Skipping visit: Supabase keys look unexpanded (check Config.xcconfig is attached to this target).")
        #endif
        return
    }
    if url == "https:" || (url.hasPrefix("https:") && !url.contains(".")) {
        #if DEBUG
        visitLogger.debug("Skipping visit: SupabaseURL looks truncated — in .xcconfig wrap the URL in quotes (// starts a comment).")
        #endif
        return
    }
    let base = url.hasSuffix("/") ? String(url.dropLast()) : url
    guard let apiURL = URL(string: "\(base)/rest/v1/visits"), apiURL.host != nil else {
        #if DEBUG
        visitLogger.debug("Skipping visit: invalid SupabaseURL after normalization.")
        #endif
        return
    }

    let visitorId = UserDefaults.standard.string(forKey: "__visitor_id__") ?? UUID().uuidString
    if UserDefaults.standard.string(forKey: "__visitor_id__") == nil {
        UserDefaults.standard.set(visitorId, forKey: "__visitor_id__")
    }

    let payload: [String: Any?] = [
        "visitor_id": visitorId,
        "platform": platform,
        "surface": surface,
        "path": "/",
        "country": geo.country,
        "city": geo.city,
        "region": geo.region,
        "timezone": TimeZone.current.identifier,
        "geo_source": geo.source.apiValue,
    ]

    guard let body = try? JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 }) else { return }

    var request = URLRequest(url: apiURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(key, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    request.httpBody = body
    request.timeoutInterval = 10

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        #if DEBUG
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            visitLogger.debug("Visit POST HTTP \(http.statusCode): \(body, privacy: .public)")
        }
        #endif
    } catch {
        #if DEBUG
        visitLogger.debug("Visit POST failed: \(error.localizedDescription, privacy: .public)")
        #endif
    }
}
