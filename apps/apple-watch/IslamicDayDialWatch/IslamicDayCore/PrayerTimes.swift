import Foundation
import Adhan

/// Prayer times computation using Adhan-Swift.
/// Mirrors packages/core/src/prayer-times.ts

func addDays(date: Date, days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
}

func getPrayerTimesForDate(date: Date, location: Location) -> PrayerTimesData? {
    let cal = Calendar.current
    cal.timeZone = TimeZone.current
    let components = cal.dateComponents([.year, .month, .day], from: date)
    guard let year = components.year, let month = components.month, let day = components.day else {
        return nil
    }
    
    let dateComponents = DateComponents(year: year, month: month, day: day)
    let coordinates = Coordinates(latitude: location.latitude, longitude: location.longitude)
    var params = CalculationMethod.ummAlQura.params
    // Isha by twilight disappearance (per hadith), not fixed interval
    params.ishaInterval = 0
    params.ishaAngle = 15
    params.shafaq = .ahmer
    
    guard let prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: dateComponents,
        calculationParameters: params
    ) else {
        return nil
    }
    
    return PrayerTimesData(
        fajr: prayerTimes.fajr,
        sunrise: prayerTimes.sunrise,
        dhuhr: prayerTimes.dhuhr,
        asr: prayerTimes.asr,
        maghrib: prayerTimes.maghrib,
        isha: prayerTimes.isha
    )
}
