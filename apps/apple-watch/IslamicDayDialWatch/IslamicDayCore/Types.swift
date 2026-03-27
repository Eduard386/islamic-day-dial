import Foundation

/// Swift port of @islamic-day-dial/core types.
/// Keep in sync with packages/core/src/types.ts

public struct Location: Codable, Equatable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Mecca default
    public static let mecca = Location(latitude: 21.4225, longitude: 39.8262)
}

public struct HijriDate: Codable, Equatable {
    public let day: Int
    public let monthNumber: Int
    public let monthNameEn: String
    public let year: Int
}

public struct PrayerTimesData: Codable, Equatable {
    public let fajr: Date
    public let sunrise: Date
    public let dhuhr: Date
    public let asr: Date
    public let maghrib: Date
    public let isha: Date
}

public struct ComputedTimeline: Codable, Equatable {
    public let lastMaghrib: Date
    public let isha: Date
    public let lastThirdStart: Date
    public let fajr: Date
    public let sunrise: Date
    public let duhaStart: Date
    public let duhaEnd: Date
    public let dhuhr: Date
    public let asr: Date
    public let nextMaghrib: Date
}

public enum IslamicPhaseId: String, CaseIterable, Codable {
    case maghrib_to_isha
    case isha_to_last_third
    case last_third_to_fajr
    case fajr_to_sunrise
    case sunrise_to_dhuhr
    case dhuhr_to_asr
    case asr_to_maghrib
}

public enum RingMarkerKind: String, Codable {
    case primary
    case secondary
}

public struct RingMarker: Codable, Equatable {
    public let id: String
    public let timestamp: Date
    public let angleDeg: Double
    public let kind: RingMarkerKind
}

public struct RingSegment: Codable, Equatable {
    public let id: IslamicPhaseId
    public let start: Date
    public let end: Date
    public let startAngleDeg: Double
    public let endAngleDeg: Double
}

public struct ComputedIslamicDay: Codable, Equatable {
    public let hijriDate: HijriDate
    public let prayerTimes: PrayerTimesData
    public let timeline: ComputedTimeline
    public let currentPhase: IslamicPhaseId
    public let nextTransitionId: String
    public let nextTransitionAt: Date
    public let countdownMs: Int64
    public let ringProgress: Double
    public let ringMarkers: [RingMarker]
    public let ringSegments: [RingSegment]
}
