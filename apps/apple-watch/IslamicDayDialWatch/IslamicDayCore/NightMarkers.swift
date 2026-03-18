import Foundation

/// Islamic midnight and last third of night.
/// Mirrors packages/core/src/night-markers.ts

/// Islamic midnight = midpoint between lastMaghrib and Fajr.
func getIslamicMidnight(lastMaghrib: Date, fajr: Date) -> Date {
    let mid = (lastMaghrib.timeIntervalSince1970 + fajr.timeIntervalSince1970) / 2
    return Date(timeIntervalSince1970: mid)
}

/// Last third of the night starts at fajr − (nightDuration / 3).
func getLastThirdStart(lastMaghrib: Date, fajr: Date) -> Date {
    let nightDuration = fajr.timeIntervalSince(lastMaghrib)
    return Date(timeInterval: -nightDuration / 3, since: fajr)
}
