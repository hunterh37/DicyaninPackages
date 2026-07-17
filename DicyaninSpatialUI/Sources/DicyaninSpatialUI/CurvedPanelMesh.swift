import RealityKit
import simd

/// Generates curved panel geometry: a vertically flat strip curved around a cylinder of `curveRadius`.
public enum CurvedPanelMesh {

    public struct GeometryData {
        public var positions: [SIMD3<Float>]
        public var normals: [SIMD3<Float>]
        public var uvs: [SIMD2<Float>]
        public var indices: [UInt32]
    }

    /// Pure geometry generation, testable without a RealityKit device context.
    /// The panel is centered at the origin, concave toward +Z (facing the user), curved about a
    /// vertical axis located at z = -curveRadius.
    public static func geometry(width: Float,
                                height: Float,
                                curveRadius: Float,
                                segments: Int) -> GeometryData {
        let radius = max(curveRadius, 0.001)
        let segs = max(segments, 2)
        let arc = width / radius
        let halfArc = arc / 2
        let halfHeight = height / 2

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        positions.reserveCapacity((segs + 1) * 2)
        normals.reserveCapacity((segs + 1) * 2)
        uvs.reserveCapacity((segs + 1) * 2)

        for i in 0...segs {
            let t = Float(i) / Float(segs)
            let angle = -halfArc + t * arc
            let x = radius * sin(angle)
            let z = radius * cos(angle) - radius
            // Normal points inward toward the viewer (+Z at center).
            let normal = SIMD3<Float>(-sin(angle), 0, cos(angle))
            for (v, y) in [(Float(0), -halfHeight), (Float(1), halfHeight)] {
                positions.append([x, y, z])
                normals.append(normal)
                uvs.append([t, v])
            }
        }

        var indices: [UInt32] = []
        indices.reserveCapacity(segs * 6)
        for i in 0..<segs {
            let a = UInt32(i * 2)       // bottom left
            let b = UInt32(i * 2 + 1)   // top left
            let c = UInt32(i * 2 + 2)   // bottom right
            let d = UInt32(i * 2 + 3)   // top right
            // Counterclockwise when viewed from +Z.
            indices.append(contentsOf: [a, c, b, b, c, d])
        }

        return GeometryData(positions: positions, normals: normals, uvs: uvs, indices: indices)
    }

    /// Builds a MeshResource for the curved panel.
    @MainActor
    public static func mesh(width: Float,
                            height: Float,
                            curveRadius: Float,
                            segments: Int = 24) throws -> MeshResource {
        let geo = geometry(width: width, height: height, curveRadius: curveRadius, segments: segments)
        var descriptor = MeshDescriptor(name: "DicyaninCurvedPanel")
        descriptor.positions = MeshBuffer(geo.positions)
        descriptor.normals = MeshBuffer(geo.normals)
        descriptor.textureCoordinates = MeshBuffer(geo.uvs)
        descriptor.primitives = .triangles(geo.indices)
        descriptor.materials = .allFaces(0)
        return try MeshResource.generate(from: [descriptor])
    }
}
