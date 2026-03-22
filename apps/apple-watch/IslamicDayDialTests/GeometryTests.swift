import XCTest
// polarToXY from Geometry.swift — compiled into test target

/// Unit tests for Geometry. Mirrors apps/web-dashboard/src/lib/__tests__/geometry.test.ts
final class GeometryTests: XCTestCase {

    func testPolarToXY_0deg_IsAtTop() {
        let result = polarToXY(cx: 100, cy: 100, r: 50, angleDeg: 0)
        XCTAssertEqual(result.x, 100, accuracy: 0.01)
        XCTAssertEqual(result.y, 50, accuracy: 0.01)
    }

    func testPolarToXY_90deg_IsAtRight() {
        let result = polarToXY(cx: 100, cy: 100, r: 50, angleDeg: 90)
        XCTAssertEqual(result.x, 150, accuracy: 0.01)
        XCTAssertEqual(result.y, 100, accuracy: 0.01)
    }

    func testPolarToXY_180deg_IsAtBottom() {
        let result = polarToXY(cx: 100, cy: 100, r: 50, angleDeg: 180)
        XCTAssertEqual(result.x, 100, accuracy: 0.01)
        XCTAssertEqual(result.y, 150, accuracy: 0.01)
    }

    func testPolarToXY_270deg_IsAtLeft() {
        let result = polarToXY(cx: 100, cy: 100, r: 50, angleDeg: 270)
        XCTAssertEqual(result.x, 50, accuracy: 0.01)
        XCTAssertEqual(result.y, 100, accuracy: 0.01)
    }

    func testPolarToXY_360deg_WrapsToTop() {
        let result = polarToXY(cx: 100, cy: 100, r: 50, angleDeg: 360)
        XCTAssertEqual(result.x, 100, accuracy: 0.01)
        XCTAssertEqual(result.y, 50, accuracy: 0.01)
    }
}
