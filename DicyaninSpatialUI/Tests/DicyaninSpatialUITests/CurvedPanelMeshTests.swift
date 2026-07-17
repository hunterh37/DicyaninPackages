import XCTest
import simd
@testable import DicyaninSpatialUI

final class CurvedPanelMeshTests: XCTestCase {

    func testVertexAndIndexCounts() {
        let segs = 24
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.35, curveRadius: 1, segments: segs)
        XCTAssertEqual(geo.positions.count, (segs + 1) * 2)
        XCTAssertEqual(geo.normals.count, geo.positions.count)
        XCTAssertEqual(geo.uvs.count, geo.positions.count)
        XCTAssertEqual(geo.indices.count, segs * 6)
    }

    func testIndicesInBounds() {
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.35, curveRadius: 1, segments: 8)
        let count = UInt32(geo.positions.count)
        XCTAssertTrue(geo.indices.allSatisfy { $0 < count })
    }

    func testMinimumSegmentsEnforced() {
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.35, curveRadius: 1, segments: 0)
        XCTAssertGreaterThanOrEqual(geo.positions.count, 6)
        XCTAssertGreaterThanOrEqual(geo.indices.count, 12)
    }

    func testPanelCenteredAtOrigin() {
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.4, curveRadius: 1, segments: 16)
        // Center column vertices sit at z = 0, x = 0.
        let midBottom = geo.positions[16] // segment 8 of 16, bottom vertex
        XCTAssertEqual(midBottom.x, 0, accuracy: 1e-5)
        XCTAssertEqual(midBottom.z, 0, accuracy: 1e-5)
        XCTAssertEqual(midBottom.y, -0.2, accuracy: 1e-5)
    }

    func testHeightSpansSymmetric() {
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.4, curveRadius: 1, segments: 8)
        let ys = geo.positions.map(\.y)
        XCTAssertEqual(ys.min()!, -0.2, accuracy: 1e-5)
        XCTAssertEqual(ys.max()!, 0.2, accuracy: 1e-5)
    }

    func testVerticesLieOnCylinder() {
        let radius: Float = 1.5
        let geo = CurvedPanelMesh.geometry(width: 0.8, height: 0.3, curveRadius: radius, segments: 12)
        for p in geo.positions {
            // Distance from curve axis (0, y, -radius) must equal radius.
            let d = simd_length(SIMD2<Float>(p.x, p.z + radius))
            XCTAssertEqual(d, radius, accuracy: 1e-4)
        }
    }

    func testArcLengthMatchesWidth() {
        let radius: Float = 1
        let width: Float = 0.6
        let segs = 64
        let geo = CurvedPanelMesh.geometry(width: width, height: 0.3, curveRadius: radius, segments: segs)
        // Sum chord lengths along the bottom edge.
        var length: Float = 0
        for i in 0..<segs {
            length += simd_distance(geo.positions[i * 2], geo.positions[(i + 1) * 2])
        }
        XCTAssertEqual(length, width, accuracy: 1e-3)
    }

    func testNormalsUnitLengthAndFaceViewer() {
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.35, curveRadius: 1, segments: 16)
        for n in geo.normals {
            XCTAssertEqual(simd_length(n), 1, accuracy: 1e-5)
            XCTAssertGreaterThan(n.z, 0)
        }
        // Center normal is exactly +Z.
        let mid = geo.normals[16]
        XCTAssertEqual(mid.z, 1, accuracy: 1e-5)
    }

    func testUVsCoverUnitSquare() {
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.35, curveRadius: 1, segments: 8)
        let us = geo.uvs.map(\.x)
        let vs = geo.uvs.map(\.y)
        XCTAssertEqual(us.min()!, 0)
        XCTAssertEqual(us.max()!, 1)
        XCTAssertEqual(vs.min()!, 0)
        XCTAssertEqual(vs.max()!, 1)
    }

    func testTriangleWindingCounterclockwise() {
        let geo = CurvedPanelMesh.geometry(width: 0.6, height: 0.35, curveRadius: 1, segments: 8)
        // Every triangle's geometric normal should point toward +Z (viewer side).
        for t in stride(from: 0, to: geo.indices.count, by: 3) {
            let a = geo.positions[Int(geo.indices[t])]
            let b = geo.positions[Int(geo.indices[t + 1])]
            let c = geo.positions[Int(geo.indices[t + 2])]
            let n = simd_cross(b - a, c - a)
            XCTAssertGreaterThan(n.z, 0, "triangle at \(t) winds backward")
        }
    }

    func testMeshResourceGeneration() async throws {
        let mesh = try await CurvedPanelMesh.mesh(width: 0.6, height: 0.35, curveRadius: 1, segments: 24)
        XCTAssertGreaterThan(mesh.bounds.extents.x, 0)
        XCTAssertGreaterThan(mesh.bounds.extents.y, 0)
    }
}
