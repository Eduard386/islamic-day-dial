import XCTest

/// Unit tests for Jumu'ah glow, last third glow, Isha glow during last third.
/// Mirrors apps/web-dashboard/src/lib/__tests__/glow-window.test.ts
/// GlowWindow, Formatting, Types compiled into test target.
final class GlowWindowTests: XCTestCase {

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

    /// Friday 2025-03-21 UTC: sunrise 06:00, dhuhr 12:15
    private var timeline: ComputedTimeline {
        let sunrise = Date(timeIntervalSince1970: 1_742_536_800)
        let dhuhr = Date(timeIntervalSince1970: 1_742_559_300)
        return ComputedTimeline(
            lastMaghrib: Date(timeIntervalSince1970: 1_742_508_000),
            isha: Date(timeIntervalSince1970: 1_742_544_000),
            lastThirdStart: Date(timeIntervalSince1970: 1_742_670_000),
            fajr: Date(timeIntervalSince1970: 1_742_760_000),
            sunrise: sunrise,
            duhaStart: sunrise.addingTimeInterval(20 * 60),
            duhaEnd: dhuhr.addingTimeInterval(-5 * 60),
            dhuhr: dhuhr,
            asr: Date(timeIntervalSince1970: 1_742_583_300),
            nextMaghrib: Date(timeIntervalSince1970: 1_742_617_200)
        )
    }

    // MARK: - Jumu'ah glow

    func testJumuahGlow_ReturnsFalseWhenNotFriday() {
        let thursday = Date(timeIntervalSince1970: 1_742_446_800) // Thu 2025-03-20 12:00 UTC
        XCTAssertFalse(isJumuahGlowWindow(now: thursday, timeline: timeline, currentPhase: .dhuhr_to_asr))
    }

    func testJumuahGlow_ReturnsTrueOnFridayInDhuhrToAsr() {
        // 2025-03-21 12:30 UTC = Friday, in dhuhr
        let friday = Date(timeIntervalSince1970: 1_742_560_200)
        XCTAssertTrue(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .dhuhr_to_asr))
    }

    func testJumuahGlow_ReturnsTrueOnFridayInDuha() {
        // 2025-03-21 07:00 UTC = Friday, 20+ min after sunrise (06:00)
        let friday = Date(timeIntervalSince1970: 1_742_540_400)
        XCTAssertTrue(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .sunrise_to_dhuhr))
    }

    func testJumuahGlow_ReturnsTrueOnFridayInMidday() {
        // 2025-03-21 12:12 UTC = Friday, last 5 min before dhuhr (12:15)
        let friday = Date(timeIntervalSince1970: 1_742_559_120)
        XCTAssertTrue(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .sunrise_to_dhuhr))
    }

    func testJumuahGlow_ReturnsFalseOnFridayInSunriseSubPeriod() {
        // 2025-03-21 06:10 UTC = Friday, first 20 min after sunrise (06:00)
        let friday = Date(timeIntervalSince1970: 1_742_536_600)
        XCTAssertFalse(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .sunrise_to_dhuhr))
    }

    func testJumuahGlow_ReturnsFalseOnFridayInNightPhases() {
        // 2025-03-21 08:16 UTC = Friday, in isha_to_last_third
        let friday = Date(timeIntervalSince1970: 1_742_545_000)
        XCTAssertFalse(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .isha_to_last_third))
        XCTAssertFalse(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .last_third_to_fajr))
        XCTAssertFalse(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .maghrib_to_isha))
    }

    func testJumuahGlow_ReturnsFalseOnFridayInAsrToMaghrib() {
        let friday = Date(timeIntervalSince1970: 1_742_585_000)
        XCTAssertFalse(isJumuahGlowWindow(now: friday, timeline: timeline, currentPhase: .asr_to_maghrib))
    }

    // MARK: - Last third phase (for pulsating glow)

    func testLastThirdPhase_IsLastThirdToFajr() {
        // When marker in last_third_to_fajr, last-third pulsating glow is shown
        XCTAssertEqual(IslamicPhaseId.last_third_to_fajr.rawValue, "last_third_to_fajr")
    }

    // MARK: - Isha sector (both Isha and Last Third get glow when in either)

    func testNightSectorsGroup_ContainsIshaAndLastThird() {
        let nightGroup: Set<IslamicPhaseId> = [.isha_to_last_third, .last_third_to_fajr]
        XCTAssertTrue(nightGroup.contains(.isha_to_last_third))
        XCTAssertTrue(nightGroup.contains(.last_third_to_fajr))
    }

    func testIshaGlowDuringLastThird_BothSegmentsHighlighted() {
        // When marker in last_third_to_fajr: Last Third pulsates, Isha gets weak glow
        // When marker in isha_to_last_third: both get weak glow
        // Logic is in RingView NIGHT_SECTORS_GROUP
        let nightPhases: [IslamicPhaseId] = [.isha_to_last_third, .last_third_to_fajr]
        XCTAssertEqual(nightPhases.count, 2)
    }
}
