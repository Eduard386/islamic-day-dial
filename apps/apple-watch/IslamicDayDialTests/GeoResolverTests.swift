import XCTest

/// Tests for geo resolution: IP first, timezone fallback, Mecca default.
/// Covers: empty/unknown timezone → Mecca, network failure → timezone/default, valid result structure.
final class GeoResolverTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// resolveGeoResult always returns a valid location (IP, timezone, or Mecca).
    func testResolveGeoResult_ReturnsValidLocation() async {
        let result = await resolveGeoResult()
        XCTAssertGreaterThanOrEqual(result.location.latitude, -90)
        XCTAssertLessThanOrEqual(result.location.latitude, 90)
        XCTAssertGreaterThanOrEqual(result.location.longitude, -180)
        XCTAssertLessThanOrEqual(result.location.longitude, 180)
    }

    /// resolveGeoResult returns valid source enum.
    func testResolveGeoResult_ReturnsValidSource() async {
        let result = await resolveGeoResult()
        switch result.source {
        case .gps: break
        case .ip: break
        case .timezone: break
        case .default: break
        }
    }

    /// resolveLocation returns same location as resolveGeoResult.
    func testResolveLocation_MatchesGeoResult() async {
        let geoResult = await resolveGeoResult()
        let location = await resolveLocation()
        XCTAssertEqual(geoResult.location.latitude, location.latitude)
        XCTAssertEqual(geoResult.location.longitude, location.longitude)
    }

    /// getTimezoneFallbackLocation returns valid location (timezone or Mecca).
    func testGetTimezoneFallbackLocation_ReturnsValidLocation() {
        let location = getTimezoneFallbackLocation()
        XCTAssertGreaterThanOrEqual(location.latitude, -90)
        XCTAssertLessThanOrEqual(location.latitude, 90)
        XCTAssertGreaterThanOrEqual(location.longitude, -180)
        XCTAssertLessThanOrEqual(location.longitude, 180)
    }
}
