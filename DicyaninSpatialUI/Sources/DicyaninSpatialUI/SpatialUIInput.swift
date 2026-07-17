import RealityKit
import simd

/// Translates raw interaction events (from SwiftUI gestures or hand tracking) into component state.
/// Supports gaze+pinch (indirect) and direct-touch (fingertip proximity) dual input.
@MainActor
public enum SpatialUIInput {

    public enum Source: Sendable {
        case gazePinch
        case directTouch
    }

    /// Returns true if the entity accepts input from the given source.
    public static func accepts(_ entity: Entity, source: Source) -> Bool {
        guard let target = entity.components[SpatialInputTargetComponent.self], target.isEnabled else { return false }
        switch source {
        case .gazePinch: return target.options.contains(.gazePinch)
        case .directTouch: return target.options.contains(.directTouch)
        }
    }

    /// Finds the nearest ancestor (or self) carrying a SpatialInputTargetComponent.
    public static func resolveTarget(_ entity: Entity) -> Entity? {
        var current: Entity? = entity
        while let e = current {
            if e.components[SpatialInputTargetComponent.self] != nil { return e }
            current = e.parent
        }
        return nil
    }

    // MARK: Hover

    /// Begin or continue hover on an element.
    public static func hoverBegan(_ entity: Entity, source: Source) {
        guard accepts(entity, source: source) else { return }
        setPhase(entity, .hovering)
    }

    public static func hoverEnded(_ entity: Entity) {
        setPhase(entity, .none)
    }

    /// Direct-touch proximity update. Drives phase from fingertip distance.
    /// - Parameters:
    ///   - distance: fingertip-to-element distance, meters.
    ///   - hoverRadius: distance at which hovering begins.
    ///   - touchDistance: distance at which press triggers.
    public static func updateProximity(_ entity: Entity,
                                       distance: Float,
                                       hoverRadius: Float = 0.08,
                                       touchDistance: Float = 0.01) {
        guard accepts(entity, source: .directTouch),
              var hover = entity.components[HoverStateComponent.self] else { return }
        hover.proximity = SpatialUIMath.proximity(distance: distance, activationRadius: hoverRadius)

        let newPhase: HoverPhase
        if distance <= touchDistance {
            newPhase = .pressed
        } else if distance <= hoverRadius {
            newPhase = .hovering
        } else {
            newPhase = .none
        }
        let wasPressed = hover.phase == .pressed
        if hover.phase != newPhase {
            hover.phase = newPhase
            hover.timeInPhase = 0
        }
        entity.components.set(hover)

        // Fire press on touch-down transition.
        if newPhase == .pressed && !wasPressed {
            press(entity, source: .directTouch)
        }
    }

    // MARK: Press / Pinch

    /// Activates an element: gaze+pinch tap or direct-touch contact.
    public static func press(_ entity: Entity, source: Source) {
        guard let target = resolveTarget(entity), accepts(target, source: source) else { return }

        if var button = target.components[SpatialButtonComponent.self] {
            button.pressedThisFrame = true
            target.components.set(button)
            setPhase(target, .pressed)
            return
        }
        if var menu = target.components[RadialMenuComponent.self] {
            menu.isOpen.toggle()
            if !menu.isOpen { menu.selectedIndex = nil }
            target.components.set(menu)
        }
    }

    /// Release after a press (returns element to hover state).
    public static func release(_ entity: Entity) {
        guard let target = resolveTarget(entity) else { return }
        setPhase(target, .hovering)
    }

    // MARK: Drag (sliders)

    /// Drag update in the slider's local space (e.g. from a SwiftUI DragGesture converted to scene coords).
    public static func drag(_ entity: Entity, localPosition: SIMD3<Float>, source: Source) {
        guard let target = resolveTarget(entity), accepts(target, source: source) else { return }
        if var slider = target.components[SpatialSliderComponent.self] {
            if !slider.isDragging {
                slider.isDragging = true
                target.components.set(slider)
            }
            SpatialUIFactory.setSliderValue(target, localX: localPosition.x)
        } else if target.components[RadialMenuComponent.self] != nil {
            SpatialUIFactory.selectRadialItem(target, localPoint: localPosition)
        }
    }

    public static func dragEnded(_ entity: Entity) {
        guard let target = resolveTarget(entity) else { return }
        if var slider = target.components[SpatialSliderComponent.self] {
            slider.isDragging = false
            target.components.set(slider)
        }
    }

    // MARK: Helpers

    private static func setPhase(_ entity: Entity, _ phase: HoverPhase) {
        guard var hover = entity.components[HoverStateComponent.self] else { return }
        if hover.phase != phase {
            hover.phase = phase
            hover.timeInPhase = 0
            entity.components.set(hover)
        }
    }
}
