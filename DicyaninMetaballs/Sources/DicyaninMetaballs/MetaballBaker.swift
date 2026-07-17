import RealityKit
import simd

public extension DicyaninMetaballs {
    /// A single ball specification for offscreen baking.
    struct Ball: Sendable {
        public var position: SIMD3<Float>
        public var radius: Float
        public var strength: Float
        public init(position: SIMD3<Float>, radius: Float = 0.2, strength: Float = 1.0) {
            self.position = position
            self.radius = radius
            self.strength = strength
        }
    }

    /// Synchronously generates a fully meshed metaball field entity for
    /// offscreen rendering. Uploads the balls, awaits GPU marching cubes
    /// completion, then attaches the resolved mesh. Bypasses the ECS system.
    @MainActor
    static func bakedField(
        configuration: MetaballFieldConfiguration,
        balls: [Ball],
        materials: [any RealityKit.Material]
    ) async throws -> Entity {
        var config = configuration
        config.regeneratesOnlyOnChange = false
        let renderer = try MetaballFieldRenderer(configuration: config)

        let gpuBalls = balls.map {
            MetaballGPU(
                positionRadius: SIMD4<Float>($0.position, $0.radius),
                params: SIMD4<Float>($0.strength, 0, 0, 0))
        }
        _ = renderer.update(balls: gpuBalls)
        while renderer.isInFlight {
            try await Task.sleep(nanoseconds: 2_000_000)
        }

        let mesh = try await renderer.makeMeshResource()
        let entity = Entity()
        entity.name = "BakedMetaballField"
        entity.components.set(ModelComponent(mesh: mesh, materials: materials))
        return entity
    }
}
