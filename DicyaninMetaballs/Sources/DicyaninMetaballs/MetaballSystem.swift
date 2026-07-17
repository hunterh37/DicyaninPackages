import RealityKit
import simd

/// ECS system that gathers `MetaballComponent` entities under each
/// `MetaballFieldComponent` entity and regenerates the field's isosurface.
public struct MetaballSystem: System {
    private static let fieldQuery = EntityQuery(where: .has(MetaballFieldComponent.self))

    public init(scene: RealityKit.Scene) {}

    public func update(context: SceneUpdateContext) {
        MainActor.assumeIsolated {
            for fieldEntity in context.entities(matching: Self.fieldQuery, updatingSystemWhen: .rendering) {
                guard let field = fieldEntity.components[MetaballFieldComponent.self],
                      !field.isPaused else { continue }

                guard let state = fieldEntity.components[MetaballFieldStateComponent.self] else {
                    Self.attachState(to: fieldEntity, configuration: field.configuration)
                    continue
                }

                var balls: [MetaballGPU] = []
                balls.reserveCapacity(field.configuration.maxBallCount)
                Self.collectBalls(from: fieldEntity, relativeTo: fieldEntity, into: &balls)
                _ = state.renderer.update(balls: balls)
            }
        }
    }

    @MainActor
    private static func collectBalls(
        from entity: Entity, relativeTo field: Entity, into balls: inout [MetaballGPU]
    ) {
        if let ball = entity.components[MetaballComponent.self], ball.isEnabled {
            let position = entity.position(relativeTo: field)
            balls.append(MetaballGPU(
                positionRadius: SIMD4<Float>(position, ball.radius),
                params: SIMD4<Float>(ball.strength, 0, 0, 0)))
        }
        for child in entity.children {
            collectBalls(from: child, relativeTo: field, into: &balls)
        }
    }

    @MainActor
    private static func attachState(to fieldEntity: Entity, configuration: MetaballFieldConfiguration) {
        guard let renderer = try? MetaballFieldRenderer(configuration: configuration) else { return }
        fieldEntity.components.set(MetaballFieldStateComponent(renderer: renderer))
        Task { @MainActor in
            guard let mesh = try? await renderer.makeMeshResource() else { return }
            if var model = fieldEntity.components[ModelComponent.self] {
                model.mesh = mesh
                fieldEntity.components.set(model)
            } else {
                fieldEntity.components.set(ModelComponent(
                    mesh: mesh,
                    materials: [SimpleMaterial(color: .white, roughness: 0.2, isMetallic: false)]))
            }
        }
    }
}
