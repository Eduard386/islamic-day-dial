import Foundation

/// Tracks app opens to Supabase visits table.
/// Configure SupabaseURL and SupabaseAnonKey in target Info (or INFOPLIST_KEY_* build settings).
/// No-ops when not configured.
func trackVisit(geo: GeoResolveResult) async {
    guard let url = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
          !url.isEmpty, !url.contains("your-project"),
          let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
          !key.isEmpty, !key.contains("your-anon") else { return }
    let base = url.hasSuffix("/") ? String(url.dropLast()) : url
    guard let apiURL = URL(string: "\(base)/rest/v1/visits") else { return }

    let visitorId = UserDefaults.standard.string(forKey: "__visitor_id__") ?? UUID().uuidString
    if UserDefaults.standard.string(forKey: "__visitor_id__") == nil {
        UserDefaults.standard.set(visitorId, forKey: "__visitor_id__")
    }

    let payload: [String: Any?] = [
        "visitor_id": visitorId,
        "platform": "ios",
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

    _ = try? await URLSession.shared.data(for: request)
}
