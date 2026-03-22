import Foundation

/// Build timeline for the current Islamic day.
/// Mirrors packages/core/src/day-bounds.ts

func buildTimeline(
    now: Date,
    todayPT: PrayerTimesData,
    yesterdayPT: PrayerTimesData,
    tomorrowPT: PrayerTimesData
) -> ComputedTimeline {
    let afterMaghrib = now >= todayPT.maghrib
    let nightPT = afterMaghrib ? todayPT : yesterdayPT
    let dayPT = afterMaghrib ? tomorrowPT : todayPT
    
    let duhaStart = Date(timeIntervalSince1970: dayPT.sunrise.timeIntervalSince1970 + 20 * 60)
    let duhaEnd = Date(timeIntervalSince1970: dayPT.dhuhr.timeIntervalSince1970 - 5 * 60)
    return ComputedTimeline(
        lastMaghrib: nightPT.maghrib,
        isha: nightPT.isha,
        islamicMidnight: getIslamicMidnight(lastMaghrib: nightPT.maghrib, fajr: dayPT.fajr),
        lastThirdStart: getLastThirdStart(lastMaghrib: nightPT.maghrib, fajr: dayPT.fajr),
        fajr: dayPT.fajr,
        sunrise: dayPT.sunrise,
        duhaStart: duhaStart,
        duhaEnd: duhaEnd,
        dhuhr: dayPT.dhuhr,
        asr: dayPT.asr,
        nextMaghrib: dayPT.maghrib
    )
}
