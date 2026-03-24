import XCTest

final class WidgetPresentationTests: XCTestCase {

    private func makeTimeline(
        lastMaghrib: TimeInterval,
        isha: TimeInterval,
        islamicMidnight: TimeInterval,
        lastThirdStart: TimeInterval,
        fajr: TimeInterval,
        sunrise: TimeInterval,
        duhaStart: TimeInterval,
        dhuhr: TimeInterval,
        asr: TimeInterval,
        nextMaghrib: TimeInterval
    ) -> ComputedTimeline {
        ComputedTimeline(
            lastMaghrib: Date(timeIntervalSince1970: lastMaghrib),
            isha: Date(timeIntervalSince1970: isha),
            islamicMidnight: Date(timeIntervalSince1970: islamicMidnight),
            lastThirdStart: Date(timeIntervalSince1970: lastThirdStart),
            fajr: Date(timeIntervalSince1970: fajr),
            sunrise: Date(timeIntervalSince1970: sunrise),
            duhaStart: Date(timeIntervalSince1970: duhaStart),
            duhaEnd: Date(timeIntervalSince1970: dhuhr - 5 * 60),
            dhuhr: Date(timeIntervalSince1970: dhuhr),
            asr: Date(timeIntervalSince1970: asr),
            nextMaghrib: Date(timeIntervalSince1970: nextMaghrib)
        )
    }

    private func makeSnapshot(timeline: ComputedTimeline, hijriDate: HijriDate = HijriDate(day: 12, monthNumber: 3, monthNameEn: "Rabi al-Awwal", year: 1447)) -> ComputedIslamicDay {
        ComputedIslamicDay(
            hijriDate: hijriDate,
            prayerTimes: PrayerTimesData(
                fajr: timeline.fajr,
                sunrise: timeline.sunrise,
                dhuhr: timeline.dhuhr,
                asr: timeline.asr,
                maghrib: timeline.lastMaghrib,
                isha: timeline.isha
            ),
            timeline: timeline,
            currentPhase: .sunrise_to_dhuhr,
            nextTransitionId: "dhuhr",
            nextTransitionAt: timeline.dhuhr,
            countdownMs: 0,
            ringProgress: 0,
            ringMarkers: getMarkers(timeline: timeline),
            ringSegments: getRingSegments(timeline: timeline)
        )
    }

    func testNextWidgetRefreshDate_UsesSoonerTransition() {
        let now = Date(timeIntervalSince1970: 1_000)
        let timeline = makeTimeline(
            lastMaghrib: 0,
            isha: 100,
            islamicMidnight: 200,
            lastThirdStart: 300,
            fajr: 400,
            sunrise: 500,
            duhaStart: 900,
            dhuhr: 1_010,
            asr: 1_400,
            nextMaghrib: 2_000
        )
        let snapshot = makeSnapshot(timeline: timeline)

        let refreshDate = nextWidgetRefreshDate(from: now, snapshot: snapshot)

        XCTAssertEqual(refreshDate.timeIntervalSince1970, 1_010.25, accuracy: 0.001)
    }

    func testNextWidgetRefreshDate_UsesNextMinuteWhenSoonerThanTransition() {
        let now = Date(timeIntervalSince1970: 1_001)
        let timeline = makeTimeline(
            lastMaghrib: 0,
            isha: 100,
            islamicMidnight: 200,
            lastThirdStart: 300,
            fajr: 400,
            sunrise: 500,
            duhaStart: 900,
            dhuhr: 1_300,
            asr: 1_700,
            nextMaghrib: 2_400
        )
        let snapshot = makeSnapshot(timeline: timeline)

        let refreshDate = nextWidgetRefreshDate(from: now, snapshot: snapshot)

        XCTAssertEqual(refreshDate.timeIntervalSince1970, 1_020, accuracy: 0.001)
    }

    func testCompactHijriLabel_UsesEidTitle() {
        let label = compactHijriLabel(
            hijriDate: HijriDate(day: 1, monthNumber: 10, monthNameEn: "Shawwal", year: 1447)
        )

        XCTAssertEqual(label.primary, "EID AL-FITR")
        XCTAssertEqual(label.secondary, "1447")
        XCTAssertTrue(label.isEid)
    }

    func testWatchInlineLabel_UsesComputedSectorName() {
        let timeline = makeTimeline(
            lastMaghrib: 0,
            isha: 100,
            islamicMidnight: 200,
            lastThirdStart: 300,
            fajr: 400,
            sunrise: 500,
            duhaStart: 700,
            dhuhr: 1_200,
            asr: 1_700,
            nextMaghrib: 2_400
        )
        let snapshot = makeSnapshot(timeline: timeline)

        let label = watchInlineLabel(snapshot: snapshot, now: Date(timeIntervalSince1970: 550))

        XCTAssertEqual(label, "SUNRISE")
    }
}
