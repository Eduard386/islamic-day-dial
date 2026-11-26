import Foundation

/// Last-third night marker.
/// Mirrors packages/core/src/night-markers.ts

/// Last third of the night starts at fajr − (nightDuration / 3).
func getLastThirdStart(lastMaghrib: Date, fajr: Date) -> Date {
    let nightDuration = fajr.timeIntervalSince(lastMaghrib)
    return Date(timeInterval: -nightDuration / 3, since: fajr)
}

/// Middle of the night: halfway from Maghrib to Fajr.
func getNightMidpoint(lastMaghrib: Date, fajr: Date) -> Date {
    Date(timeInterval: fajr.timeIntervalSince(lastMaghrib) / 2, since: lastMaghrib)
}
