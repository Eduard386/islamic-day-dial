import Foundation

/// Build timeline for the current Islamic day.
/// Mirrors packages/core/src/day-bounds.ts

private let DUHA_START_ALTITUDE_DEG = 4.0
private let DUHA_START_FALLBACK_SECONDS = 20.0 * 60.0
private let SOLAR_SEARCH_STEPS = 24

private func getDuhaStart(sunrise: Date, dhuhr: Date, location: Location, duhaEnd: Date) -> Date {
    let fallback = Date(timeIntervalSince1970: min(sunrise.timeIntervalSince1970 + DUHA_START_FALLBACK_SECONDS, duhaEnd.timeIntervalSince1970))
    if getSolarAltitude(at: sunrise, location: location) >= DUHA_START_ALTITUDE_DEG {
        return sunrise
    }
    if getSolarAltitude(at: dhuhr, location: location) < DUHA_START_ALTITUDE_DEG {
        return fallback
    }

    var low = sunrise.timeIntervalSince1970
    var high = dhuhr.timeIntervalSince1970
    for _ in 0..<SOLAR_SEARCH_STEPS {
        let mid = (low + high) / 2
        let altitude = getSolarAltitude(at: Date(timeIntervalSince1970: mid), location: location)
        if altitude < DUHA_START_ALTITUDE_DEG {
            low = mid
        } else {
            high = mid
        }
    }

    return Date(timeIntervalSince1970: min(high, duhaEnd.timeIntervalSince1970))
}

private func getSolarAltitude(at date: Date, location: Location) -> Double {
    let jd = date.timeIntervalSince1970 / 86400 + 2440587.5
    let t = (jd - 2451545.0) / 36525.0

    let meanLongitude = normalizeDegrees(280.46646 + t * (36000.76983 + t * 0.0003032))
    let meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t)
    let eccentricity = 0.016708634 - t * (0.000042037 + t * 0.0000001267)

    let equationOfCenter =
        sin(toRadians(meanAnomaly)) * (1.914602 - t * (0.004817 + t * 0.000014)) +
        sin(toRadians(2 * meanAnomaly)) * (0.019993 - 0.000101 * t) +
        sin(toRadians(3 * meanAnomaly)) * 0.000289

    let trueLongitude = meanLongitude + equationOfCenter
    let omega = 125.04 - 1934.136 * t
    let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * sin(toRadians(omega))

    let epsilon0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
    let epsilon = epsilon0 + 0.00256 * cos(toRadians(omega))
    let declination = toDegrees(asin(sin(toRadians(epsilon)) * sin(toRadians(apparentLongitude))))

    let y = pow(tan(toRadians(epsilon / 2)), 2)
    let equationOfTime = 4 * toDegrees(
        y * sin(toRadians(2 * meanLongitude)) -
        2 * eccentricity * sin(toRadians(meanAnomaly)) +
        4 * eccentricity * y * sin(toRadians(meanAnomaly)) * cos(toRadians(2 * meanLongitude)) -
        0.5 * y * y * sin(toRadians(4 * meanLongitude)) -
        1.25 * eccentricity * eccentricity * sin(toRadians(2 * meanAnomaly))
    )

    var utcCalendar = Calendar(identifier: .gregorian)
    utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let components: Set<Calendar.Component> = [.hour, .minute, .second, .nanosecond]
    let comps = utcCalendar.dateComponents(components, from: date)
    let hours = Double(comps.hour ?? 0)
    let minutes = Double(comps.minute ?? 0)
    let seconds = Double(comps.second ?? 0)
    let nanoseconds = Double(comps.nanosecond ?? 0)
    let utcMinutes = hours * 60 + minutes + seconds / 60 + nanoseconds / 60_000_000_000
    let trueSolarTime = positiveMod(utcMinutes + equationOfTime + 4 * location.longitude, 1440)
    let hourAngle = trueSolarTime / 4 - 180

    let zenith = toDegrees(acos(
        sin(toRadians(location.latitude)) * sin(toRadians(declination)) +
        cos(toRadians(location.latitude)) * cos(toRadians(declination)) * cos(toRadians(hourAngle))
    ))

    return 90 - zenith
}

private func toRadians(_ degrees: Double) -> Double {
    degrees * .pi / 180
}

private func toDegrees(_ radians: Double) -> Double {
    radians * 180 / .pi
}

private func normalizeDegrees(_ degrees: Double) -> Double {
    positiveMod(degrees, 360)
}

private func positiveMod(_ value: Double, _ modulus: Double) -> Double {
    let result = value.truncatingRemainder(dividingBy: modulus)
    return result >= 0 ? result : result + modulus
}

func buildTimeline(
    now: Date,
    todayPT: PrayerTimesData,
    yesterdayPT: PrayerTimesData,
    tomorrowPT: PrayerTimesData,
    location: Location
) -> ComputedTimeline {
    let afterMaghrib = now >= todayPT.maghrib
    let nightPT = afterMaghrib ? todayPT : yesterdayPT
    let dayPT = afterMaghrib ? tomorrowPT : todayPT
    
    let duhaEnd = Date(timeIntervalSince1970: dayPT.dhuhr.timeIntervalSince1970 - 5 * 60)
    let duhaStart = getDuhaStart(sunrise: dayPT.sunrise, dhuhr: dayPT.dhuhr, location: location, duhaEnd: duhaEnd)
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
