import XCTest

final class PhoneHomePresentationTests: XCTestCase {
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

    func testPhoneHomePresentation_HidesSunriseAndMiddayFromRingLegend() {
        let timeline = makeTimeline(
            sunrise: "2026-03-23T06:00:00Z",
            duhaStart: "2026-03-23T06:20:00Z",
            dhuhr: "2026-03-23T12:15:00Z",
            asr: "2026-03-23T15:30:00Z",
            nextMaghrib: "2026-03-23T18:10:00Z"
        )
        let now = isoDate("2026-03-23T06:10:00Z")
        let snapshot = makeSnapshot(
            timeline: timeline,
            hijriDate: HijriDate(day: 4, monthNumber: 10, monthNameEn: "Shawwal", year: 1447),
            currentPhase: .sunrise_to_dhuhr,
            now: now
        )

        let presentation = makePhoneHomePresentation(snapshot: snapshot, now: now)
        let titles = presentation.ringLegendItems.map(\.title)

        XCTAssertEqual(presentation.rawSectorTitle, "Sunrise")
        XCTAssertEqual(presentation.displayTitle, "Sunrise")
        XCTAssertEqual(presentation.currentCueText, PHONE_CUE_SUNRISE)
        XCTAssertFalse(titles.contains("Sunrise"))
        XCTAssertFalse(titles.contains("Midday"))
        XCTAssertNil(presentation.highlightedRingTitle)
    }

    func testPhoneHomePresentation_UsesMiddayBackgroundAndCue() {
        let timeline = makeTimeline(
            sunrise: "2026-03-23T06:00:00Z",
            duhaStart: "2026-03-23T06:20:00Z",
            dhuhr: "2026-03-23T12:15:00Z",
            asr: "2026-03-23T15:30:00Z",
            nextMaghrib: "2026-03-23T18:10:00Z"
        )
        let now = isoDate("2026-03-23T12:12:00Z")
        let snapshot = makeSnapshot(
            timeline: timeline,
            hijriDate: HijriDate(day: 4, monthNumber: 10, monthNameEn: "Shawwal", year: 1447),
            currentPhase: .sunrise_to_dhuhr,
            now: now
        )

        let presentation = makePhoneHomePresentation(snapshot: snapshot, now: now)

        XCTAssertEqual(presentation.backgroundKey, .midday)
        XCTAssertEqual(presentation.rawSectorTitle, "Midday")
        XCTAssertEqual(presentation.displayTitle, "Midday")
        XCTAssertEqual(presentation.currentCueText, PHONE_CUE_MIDDAY)
        XCTAssertNil(presentation.highlightedRingTitle)
    }

    func testPhoneHomePresentation_UsesJumuahCueAndLegendOnFriday() {
        let timeline = makeTimeline(
            sunrise: "2026-03-27T06:00:00Z",
            duhaStart: "2026-03-27T06:20:00Z",
            dhuhr: "2026-03-27T12:15:00Z",
            asr: "2026-03-27T15:30:00Z",
            nextMaghrib: "2026-03-27T18:10:00Z"
        )
        let now = isoDate("2026-03-27T09:00:00Z")
        let snapshot = makeSnapshot(
            timeline: timeline,
            hijriDate: HijriDate(day: 8, monthNumber: 10, monthNameEn: "Shawwal", year: 1447),
            currentPhase: .sunrise_to_dhuhr,
            now: now
        )

        let presentation = makePhoneHomePresentation(snapshot: snapshot, now: now)
        let titles = presentation.ringLegendItems.map(\.title)

        XCTAssertEqual(presentation.backgroundKey, .jumuah)
        XCTAssertEqual(presentation.rawSectorTitle, "Jumu'ah")
        XCTAssertEqual(presentation.displayTitle, "Jumu'ah")
        XCTAssertEqual(presentation.currentCueText, PHONE_CUE_JUMUAH)
        XCTAssertTrue(titles.contains("Jumu'ah"))
        XCTAssertFalse(titles.contains("Dhuhr"))
        XCTAssertEqual(presentation.highlightedRingTitle, "Jumu'ah")
        XCTAssertTrue(presentation.ringLegendItems.contains { $0.title == "Jumu'ah" && $0.isActive })
    }

    func testPhoneHomePresentation_UsesEidTitleDuringNoonWindow() {
        let timeline = makeTimeline(
            sunrise: "2026-03-20T06:00:00Z",
            duhaStart: "2026-03-20T06:20:00Z",
            dhuhr: "2026-03-20T12:15:00Z",
            asr: "2026-03-20T15:30:00Z",
            nextMaghrib: "2026-03-20T18:10:00Z"
        )
        let now = isoDate("2026-03-20T09:00:00Z")
        let snapshot = makeSnapshot(
            timeline: timeline,
            hijriDate: HijriDate(day: 1, monthNumber: 10, monthNameEn: "Shawwal", year: 1447),
            currentPhase: .sunrise_to_dhuhr,
            now: now
        )

        let presentation = makePhoneHomePresentation(snapshot: snapshot, now: now)

        XCTAssertEqual(presentation.backgroundKey, .eidAlFitr)
        XCTAssertEqual(presentation.rawSectorTitle, "Jumu'ah")
        XCTAssertEqual(presentation.displayTitle, "EID AL-FITR")
        XCTAssertEqual(presentation.currentCueText, PHONE_CUE_EID_AL_FITR)
        XCTAssertNil(presentation.highlightedRingTitle)
        XCTAssertTrue(presentation.isEidDay)
    }

    func testPhoneHomePresentation_RevertsToSectorCueOutsideEidNoonWindow() {
        let timeline = makeTimeline(
            sunrise: "2026-05-27T06:00:00Z",
            duhaStart: "2026-05-27T06:20:00Z",
            dhuhr: "2026-05-27T12:15:00Z",
            asr: "2026-05-27T15:30:00Z",
            nextMaghrib: "2026-05-27T18:10:00Z"
        )
        let now = isoDate("2026-05-27T16:00:00Z")
        let snapshot = makeSnapshot(
            timeline: timeline,
            hijriDate: HijriDate(day: 10, monthNumber: 12, monthNameEn: "Dhul Hijjah", year: 1447),
            currentPhase: .asr_to_maghrib,
            now: now
        )

        let presentation = makePhoneHomePresentation(snapshot: snapshot, now: now)

        XCTAssertEqual(presentation.backgroundKey, .eidAlAdha)
        XCTAssertEqual(presentation.rawSectorTitle, "Asr")
        XCTAssertEqual(presentation.displayTitle, "Asr")
        XCTAssertEqual(presentation.currentCueText, PHONE_CUE_ASR)
        XCTAssertEqual(presentation.highlightedRingTitle, "Asr")
    }

    func testPhoneHomePresentation_HighlightsLastThirdDuringLastThirdPhase() {
        let timeline = makeTimeline(
            sunrise: "2026-03-23T06:00:00Z",
            duhaStart: "2026-03-23T06:20:00Z",
            dhuhr: "2026-03-23T12:15:00Z",
            asr: "2026-03-23T15:30:00Z",
            nextMaghrib: "2026-03-23T18:10:00Z"
        )
        let now = isoDate("2026-03-23T03:00:00Z")
        let snapshot = makeSnapshot(
            timeline: timeline,
            hijriDate: HijriDate(day: 4, monthNumber: 10, monthNameEn: "Shawwal", year: 1447),
            currentPhase: .last_third_to_fajr,
            now: now
        )

        let presentation = makePhoneHomePresentation(snapshot: snapshot, now: now)

        XCTAssertEqual(presentation.backgroundKey, .lastThird)
        XCTAssertEqual(presentation.rawSectorTitle, "Last 3rd")
        XCTAssertEqual(presentation.displayTitle, "Last 3rd")
        XCTAssertEqual(presentation.currentCueText, PHONE_CUE_LAST_THIRD)
        XCTAssertEqual(presentation.highlightedRingTitle, "Last 3rd")
        XCTAssertTrue(presentation.ringLegendItems.contains { $0.title == "Last 3rd" && $0.isActive })
    }

    func testPhoneReadingTitle_PrefersDisplayTitleWhenSupported() {
        let presentation = PhoneHomePresentation(
            backgroundKey: .dhuhr,
            rawSectorTitle: "Dhuhr",
            displayTitle: "Jumu'ah",
            currentCueText: PHONE_CUE_JUMUAH,
            ringLegendItems: [],
            highlightedRingTitle: "Jumu'ah",
            isEidDay: false
        )

        XCTAssertEqual(phoneReadingTitle(for: presentation), "Jumu'ah")
    }

    func testPhoneReadingTitle_FallsBackToRawTitleWhenDisplayTitleIsEid() {
        let presentation = PhoneHomePresentation(
            backgroundKey: .eidAlFitr,
            rawSectorTitle: "Duha",
            displayTitle: "EID AL-FITR",
            currentCueText: PHONE_CUE_EID_AL_FITR,
            ringLegendItems: [],
            highlightedRingTitle: nil,
            isEidDay: true
        )

        XCTAssertEqual(phoneReadingTitle(for: presentation), "Duha")
    }

    private func makeTimeline(
        sunrise: String,
        duhaStart: String,
        dhuhr: String,
        asr: String,
        nextMaghrib: String
    ) -> ComputedTimeline {
        let sunriseDate = isoDate(sunrise)
        let dhuhrDate = isoDate(dhuhr)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: sunriseDate)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        return ComputedTimeline(
            lastMaghrib: date(atHour: 18, minute: 10, on: previousDay),
            isha: date(atHour: 19, minute: 30, on: previousDay),
            lastThirdStart: date(atHour: 2, minute: 0, on: startOfDay),
            fajr: date(atHour: 4, minute: 30, on: startOfDay),
            sunrise: sunriseDate,
            duhaStart: isoDate(duhaStart),
            duhaEnd: dhuhrDate.addingTimeInterval(-5 * 60),
            dhuhr: dhuhrDate,
            asr: isoDate(asr),
            nextMaghrib: isoDate(nextMaghrib)
        )
    }

    private func makeSnapshot(
        timeline: ComputedTimeline,
        hijriDate: HijriDate,
        currentPhase: IslamicPhaseId,
        now: Date
    ) -> ComputedIslamicDay {
        ComputedIslamicDay(
            hijriDate: hijriDate,
            prayerTimes: PrayerTimesData(
                fajr: timeline.fajr,
                sunrise: timeline.sunrise,
                dhuhr: timeline.dhuhr,
                asr: timeline.asr,
                maghrib: timeline.nextMaghrib,
                isha: timeline.isha
            ),
            timeline: timeline,
            currentPhase: currentPhase,
            nextTransitionId: getNextTransition(now: now, timeline: timeline).id,
            nextTransitionAt: getNextTransition(now: now, timeline: timeline).at,
            countdownMs: 0,
            ringProgress: 0,
            ringMarkers: getMarkers(timeline: timeline),
            ringSegments: getRingSegments(timeline: timeline)
        )
    }

    private func isoDate(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso) ?? Date()
    }

    private func date(atHour hour: Int, minute: Int, on base: Date) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: base
        ) ?? base
    }
}
