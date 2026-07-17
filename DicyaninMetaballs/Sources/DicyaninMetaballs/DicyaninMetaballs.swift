import RealityKit

/// Entry point. Call once before adding metaball entities to a RealityView scene.
public enum DicyaninMetaballs {
    /// Registers metaball components and the update system with RealityKit.
    @MainActor
    public static func register() {
        MetaballComponent.registerComponent()
        MetaballFieldComponent.registerComponent()
        MetaballFieldStateComponent.registerComponent()
        MetaballPresetComponent.registerComponent()
        MetaballSystem.registerSystem()
        MetaballPresetSystem.registerSystem()
    }
}

public extension Entity {
    /// Creates a metaball field entity. Add child entities with
    /// `MetaballComponent` to grow the surface. Pass materials to control
    /// shading; a default material is applied when none are provided.
    @MainActor
    static func metaballField(
        configuration: MetaballFieldConfiguration = .init(),
        materials: [any RealityKit.Material] = []
    ) -> Entity {
        let entity = Entity()
        entity.name = "MetaballField"
        entity.components.set(MetaballFieldComponent(configuration: configuration))
        if !materials.isEmpty {
            entity.components.set(ModelComponent(
                mesh: .generateBox(size: 0.0001), materials: materials))
        }
        return entity
    }

    /// Creates a single metaball entity positioned in field-local space.
    @MainActor
    static func metaball(
        position: SIMD3<Float> = .zero,
        radius: Float = 0.15,
        strength: Float = 1.0
    ) -> Entity {
        let entity = Entity()
        entity.name = "Metaball"
        entity.position = position
        entity.components.set(MetaballComponent(radius: radius, strength: strength))
        return entity
    }
}
