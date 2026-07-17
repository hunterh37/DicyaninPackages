import RealityKit
import simd

// MARK: - Toggle System

/// Consumes toggle presses, flips state, fires callbacks, and animates the knob.
public struct ToggleSystem: System {
    static let query = EntityQuery(where: .has(SpatialToggleComponent.self))
    private static let smoothingRate: Float = 20

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        let k = SpatialUIMath.smoothingFactor(rate: Self.smoothingRate, deltaTime: dt)
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var toggle = entity.components[SpatialToggleComponent.self] else { continue }
            if toggle.pressedThisFrame {
                toggle.pressedThisFrame = false
                toggle.isOn.toggle()
                entity.components.set(toggle)
                toggle.onChanged?(toggle.isOn)
            }
            guard let knob = entity.findEntity(named: SpatialUIFactory.toggleKnobName) else { continue }
            knob.position.x = SpatialUIMath.lerp(knob.position.x, toggle.knobTargetX, k)
        }
    }
}

// MARK: - Segmented Control System

/// Consumes pressed segment indices and applies the selection.
public struct SegmentedControlSystem: System {
    static let query = EntityQuery(where: .has(SpatialSegmentedControlComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var control = entity.components[SpatialSegmentedControlComponent.self],
                  let index = control.pressedIndex else { continue }
            control.pressedIndex = nil
            entity.components.set(control)
            SpatialUIFactory.selectSegment(entity, index: index)
        }
    }
}

// MARK: - Progress Bar System

/// Animates the fill toward the target progress.
public struct ProgressBarSystem: System {
    static let query = EntityQuery(where: .has(SpatialProgressBarComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var bar = entity.components[SpatialProgressBarComponent.self] else { continue }
            let k = SpatialUIMath.smoothingFactor(rate: bar.smoothingRate, deltaTime: dt)
            let next = SpatialUIMath.lerp(bar.displayedProgress, bar.progress, k)
            guard abs(next - bar.displayedProgress) > .ulpOfOne else { continue }
            bar.displayedProgress = next
            entity.components.set(bar)
            guard let fill = entity.findEntity(named: SpatialUIFactory.progressFillName) else { continue }
            fill.scale = [max(next, 0.001), 1, 1]
            fill.position = [(next - 1) * bar.length / 2, 0, 0.002]
        }
    }
}

// MARK: - Dial System

/// Keeps the knob rotation in sync with the dial value.
public struct DialSystem: System {
    static let query = EntityQuery(where: .has(SpatialDialComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let dial = entity.components[SpatialDialComponent.self] else { continue }
            Self.applyKnobRotation(entity, dial: dial)
        }
    }

    /// Rotates the knob child to match the dial angle. Knob base orientation lays the cylinder flat.
    @MainActor
    static func applyKnobRotation(_ entity: Entity, dial: SpatialDialComponent) {
        guard let knob = entity.findEntity(named: SpatialUIFactory.dialKnobName) else { return }
        let roll = simd_quatf(angle: -dial.knobAngle, axis: [0, 0, 1])
        let base = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        knob.orientation = roll * base
    }
}

// MARK: - Stepper System

/// Consumes pressed directions and applies value changes.
public struct StepperSystem: System {
    static let query = EntityQuery(where: .has(SpatialStepperComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var stepper = entity.components[SpatialStepperComponent.self],
                  let direction = stepper.pressedDirection else { continue }
            stepper.pressedDirection = nil
            entity.components.set(stepper)
            SpatialUIFactory.stepValue(entity, direction: direction)
        }
    }
}

// MARK: - Dropdown System

/// Shows/hides row entities based on open state and consumes row presses.
public struct DropdownSystem: System {
    static let query = EntityQuery(where: .has(SpatialDropdownComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var dropdown = entity.components[SpatialDropdownComponent.self] else { continue }
            if let index = dropdown.pressedIndex {
                dropdown.pressedIndex = nil
                entity.components.set(dropdown)
                SpatialUIFactory.selectDropdownItem(entity, index: index)
                dropdown = entity.components[SpatialDropdownComponent.self] ?? dropdown
            }
            for child in entity.children where child.name.hasPrefix(SpatialUIFactory.dropdownRowPrefix) {
                child.isEnabled = dropdown.isOpen
            }
        }
    }
}
