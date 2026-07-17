import XCTest
import simd
@testable import DicyaninSpatialUI

final class SpatialUIMathTests: XCTestCase {

    // MARK: clamp / lerp / normalize

    func testClamp01() {
        XCTAssertEqual(SpatialUIMath.clamp01(-0.5), 0)
        XCTAssertEqual(SpatialUIMath.clamp01(0.5), 0.5)
        XCTAssertEqual(SpatialUIMath.clamp01(1.5), 1)
    }

    func testClamp() {
        XCTAssertEqual(SpatialUIMath.clamp(5, -1, 2), 2)
        XCTAssertEqual(SpatialUIMath.clamp(-5, -1, 2), -1)
        XCTAssertEqual(SpatialUIMath.clamp(0, -1, 2), 0)
    }

    func testLerp() {
        XCTAssertEqual(SpatialUIMath.lerp(0, 10, 0.5), 5)
        XCTAssertEqual(SpatialUIMath.lerp(2, 2, 0.7), 2)
        XCTAssertEqual(SpatialUIMath.lerp(0, 10, 0), 0)
        XCTAssertEqual(SpatialUIMath.lerp(0, 10, 1), 10)
    }

    func testNormalize() {
        XCTAssertEqual(SpatialUIMath.normalize(5, in: 0...10), 0.5)
        XCTAssertEqual(SpatialUIMath.normalize(-5, in: 0...10), 0)
        XCTAssertEqual(SpatialUIMath.normalize(15, in: 0...10), 1)
        XCTAssertEqual(SpatialUIMath.normalize(0, in: -10...10), 0.5)
    }

    func testNormalizeDegenerateRange() {
        XCTAssertEqual(SpatialUIMath.normalize(3, in: 3...3), 0)
    }

    // MARK: clampAndStep

    func testClampAndStepNoStep() {
        XCTAssertEqual(SpatialUIMath.clampAndStep(0.7, range: 0...1, step: nil), 0.7)
        XCTAssertEqual(SpatialUIMath.clampAndStep(2, range: 0...1, step: nil), 1)
        XCTAssertEqual(SpatialUIMath.clampAndStep(-1, range: 0...1, step: nil), 0)
    }

    func testClampAndStepSnapping() {
        XCTAssertEqual(SpatialUIMath.clampAndStep(0.24, range: 0...1, step: 0.25), 0.25)
        XCTAssertEqual(SpatialUIMath.clampAndStep(0.37, range: 0...1, step: 0.25), 0.25, accuracy: 1e-6)
        XCTAssertEqual(SpatialUIMath.clampAndStep(0.38, range: 0...1, step: 0.25), 0.5, accuracy: 1e-6)
    }

    func testClampAndStepAnchoredAtLowerBound() {
        XCTAssertEqual(SpatialUIMath.clampAndStep(3.4, range: 1...5, step: 1), 3)
        XCTAssertEqual(SpatialUIMath.clampAndStep(3.6, range: 1...5, step: 1), 4)
    }

    func testClampAndStepNeverExceedsRange() {
        let v = SpatialUIMath.clampAndStep(0.95, range: 0...1, step: 0.3)
        XCTAssertLessThanOrEqual(v, 1)
        XCTAssertGreaterThanOrEqual(v, 0)
    }

    // MARK: smoothing

    func testSmoothingFactorBounds() {
        let k = SpatialUIMath.smoothingFactor(rate: 18, deltaTime: 1 / 90)
        XCTAssertGreaterThan(k, 0)
        XCTAssertLessThan(k, 1)
    }

    func testSmoothingFactorZeroDt() {
        XCTAssertEqual(SpatialUIMath.smoothingFactor(rate: 18, deltaTime: 0), 0)
    }

    func testSmoothingFactorNegativeDtClamped() {
        XCTAssertEqual(SpatialUIMath.smoothingFactor(rate: 18, deltaTime: -1), 0)
    }

    // MARK: radial layout

    func testRadialAngleFirstItemAtStartAngle() {
        XCTAssertEqual(SpatialUIMath.radialAngle(index: 0, count: 4, startAngle: .pi / 2), .pi / 2)
    }

    func testRadialAngleEvenSpacing() {
        let a0 = SpatialUIMath.radialAngle(index: 0, count: 6, startAngle: 0)
        let a1 = SpatialUIMath.radialAngle(index: 1, count: 6, startAngle: 0)
        XCTAssertEqual(a1 - a0, 2 * .pi / 6, accuracy: 1e-6)
    }

    func testRadialPositionOnCircle() {
        for i in 0..<5 {
            let p = SpatialUIMath.radialPosition(index: i, count: 5, radius: 0.12, startAngle: .pi / 2)
            XCTAssertEqual(simd_length(SIMD2<Float>(p.x, p.y)), 0.12, accuracy: 1e-5)
            XCTAssertEqual(p.z, 0)
        }
    }

    func testRadialPositionFirstItemTop() {
        let p = SpatialUIMath.radialPosition(index: 0, count: 4, radius: 1, startAngle: .pi / 2)
        XCTAssertEqual(p.x, 0, accuracy: 1e-6)
        XCTAssertEqual(p.y, 1, accuracy: 1e-6)
    }

    // MARK: radial hit testing

    func testRadialHitIndexDeadZone() {
        XCTAssertNil(SpatialUIMath.radialHitIndex(localPoint: [0.01, 0.01, 0], count: 4,
                                                  startAngle: .pi / 2, deadZoneRadius: 0.03))
    }

    func testRadialHitIndexTopItem() {
        let hit = SpatialUIMath.radialHitIndex(localPoint: [0, 0.1, 0], count: 4,
                                               startAngle: .pi / 2, deadZoneRadius: 0.03)
        XCTAssertEqual(hit, 0)
    }

    func testRadialHitIndexAllSectors() {
        let count = 6
        for i in 0..<count {
            let p = SpatialUIMath.radialPosition(index: i, count: count, radius: 0.1, startAngle: .pi / 2)
            let hit = SpatialUIMath.radialHitIndex(localPoint: p, count: count,
                                                   startAngle: .pi / 2, deadZoneRadius: 0.03)
            XCTAssertEqual(hit, i, "sector \(i)")
        }
    }

    func testRadialHitIndexSectorBoundaryStaysInRange() {
        for angleDeg in stride(from: 0, to: 360, by: 5) {
            let a = Float(angleDeg) * .pi / 180
            let hit = SpatialUIMath.radialHitIndex(localPoint: [cos(a) * 0.1, sin(a) * 0.1, 0],
                                                   count: 5, startAngle: 0, deadZoneRadius: 0.01)
            XCTAssertNotNil(hit)
            XCTAssertGreaterThanOrEqual(hit!, 0)
            XCTAssertLessThan(hit!, 5)
        }
    }

    func testRadialHitIndexZeroCount() {
        XCTAssertNil(SpatialUIMath.radialHitIndex(localPoint: [0.1, 0, 0], count: 0,
                                                  startAngle: 0, deadZoneRadius: 0.01))
    }

    // MARK: proximity

    func testProximityAtContact() {
        XCTAssertEqual(SpatialUIMath.proximity(distance: 0, activationRadius: 0.1), 1)
    }

    func testProximityAtEdge() {
        XCTAssertEqual(SpatialUIMath.proximity(distance: 0.1, activationRadius: 0.1), 0)
    }

    func testProximityBeyondEdge() {
        XCTAssertEqual(SpatialUIMath.proximity(distance: 0.5, activationRadius: 0.1), 0)
    }

    func testProximityZeroRadius() {
        XCTAssertEqual(SpatialUIMath.proximity(distance: 0.1, activationRadius: 0), 0)
    }

    // MARK: billboard

    func testYawBillboardFacesTarget() {
        let q = SpatialUIMath.yawBillboard(from: [0, 0, 0], to: [0, 0, 1])
        let forward = q.act(SIMD3<Float>(0, 0, 1))
        XCTAssertEqual(forward.x, 0, accuracy: 1e-5)
        XCTAssertEqual(forward.z, 1, accuracy: 1e-5)
    }

    func testYawBillboardIgnoresPitch() {
        let q = SpatialUIMath.yawBillboard(from: [0, 0, 0], to: [0, 5, 1])
        let up = q.act(SIMD3<Float>(0, 1, 0))
        XCTAssertEqual(up.y, 1, accuracy: 1e-5)
    }
}
