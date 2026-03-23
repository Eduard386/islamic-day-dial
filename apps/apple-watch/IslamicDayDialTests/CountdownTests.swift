import XCTest

/// Countdown targets the start of the next sector.
/// Mirrors packages/core/src/__tests__/countdown.test.ts
final class CountdownTests: XCTestCase {

    private var originalTimeZone: TimeZone!

    override func setUp() {
        super.setUp()
        originalTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "UTC")!
    }

    override func tearDown() {
        NSTimeZone.default = originalTimeZone
        super.tearDown()
    }

    private func makeTimeline(
        lastMaghrib: TimeInterval,
        isha: TimeInterval,
        islamicMidnight: TimeInterval,
        lastThirdStart: TimeInterval,
        fajr: TimeInterval,
        sunrise: TimeInterval,
        dhuhr: TimeInterval,
        asr: TimeInterval,
        nextMaghrib: TimeInterval
    ) -> ComputedTimeline {
        let duhaStart = sunrise + 20 * 60
        let duhaEnd = dhuhr - 5 * 60
        return ComputedTimeline(
            lastMaghrib: Date(timeIntervalSince1970: lastMaghrib),
            isha: Date(timeIntervalSince1970: isha),
            islamicMidnight: Date(timeIntervalSince1970: islamicMidnight),
            lastThirdStart: Date(timeIntervalSince1970: lastThirdStart),
            fajr: Date(timeIntervalSince1970: fajr),
            sunrise: Date(timeIntervalSince1970: sunrise),
            duhaStart: Date(timeIntervalSince1970: duhaStart),
            duhaEnd: Date(timeIntervalSince1970: duhaEnd),
            dhuhr: Date(timeIntervalSince1970: dhuhr),
            asr: Date(timeIntervalSince1970: asr),
            nextMaghrib: Date(timeIntervalSince1970: nextMaghrib)
        )
    }

    func testFajrSector_TargetIsSunrise() {
        let sunrise: TimeInterval = 100000
        let dhuhr: TimeInterval = 200000
        let tl = makeTimeline(
            lastMaghrib: 0, isha: 10000, islamicMidnight: 20000, lastThirdStart: 30000,
            fajr: 80000, sunrise: sunrise, dhuhr: dhuhr,
            asr: 250000, nextMaghrib: 300000
        )
        let now = Date(timeIntervalSince1970: 90000)
        let target = getCountdownTarget(now: now, timeline: tl)
        XCTAssertEqual(target.timeIntervalSince1970, sunrise)
    }

    func testMaghribSector_TargetIsIsha() {
        let isha: TimeInterval = 50000
        let tl = makeTimeline(
            lastMaghrib: 0, isha: isha, islamicMidnight: 60000, lastThirdStart: 70000,
            fajr: 80000, sunrise: 100000, dhuhr: 150000, asr: 200000, nextMaghrib: 300000
        )
        let now = Date(timeIntervalSince1970: 25000)
        let target = getCountdownTarget(now: now, timeline: tl)
        XCTAssertEqual(target.timeIntervalSince1970, isha)
    }

    func testIshaSectors_TargetIsFajr() {
        let fajr: TimeInterval = 80000
        let tl = makeTimeline(
            lastMaghrib: 0, isha: 10000, islamicMidnight: 20000, lastThirdStart: 30000,
            fajr: fajr, sunrise: 100000, dhuhr: 150000, asr: 200000, nextMaghrib: 300000
        )
        let now = Date(timeIntervalSince1970: 25000)
        let target = getCountdownTarget(now: now, timeline: tl)
        XCTAssertEqual(target.timeIntervalSince1970, fajr)
    }

    func testSunriseToDhuhr_SubPeriodsTargetNextSectorStart() {
        let sunrise: TimeInterval = 100000
        let dhuhr: TimeInterval = 2000000
        let duhaStart = sunrise + 20 * 60
        let duhaEnd = dhuhr - 5 * 60
        let tl = makeTimeline(
            lastMaghrib: 0, isha: 10000, islamicMidnight: 20000, lastThirdStart: 30000,
            fajr: 80000, sunrise: sunrise, dhuhr: dhuhr,
            asr: 2500000, nextMaghrib: 3000000
        )
        // Before duhaStart (sunrise + 20 min = 101200), not 110000 which is already in Duha
        var target = getCountdownTarget(now: Date(timeIntervalSince1970: 100500), timeline: tl)
        XCTAssertEqual(target.timeIntervalSince1970, duhaStart)
        target = getCountdownTarget(now: Date(timeIntervalSince1970: duhaStart + 1), timeline: tl)
        XCTAssertEqual(target.timeIntervalSince1970, duhaEnd)
        target = getCountdownTarget(now: Date(timeIntervalSince1970: duhaEnd + 1), timeline: tl)
        XCTAssertEqual(target.timeIntervalSince1970, dhuhr)
    }
}
