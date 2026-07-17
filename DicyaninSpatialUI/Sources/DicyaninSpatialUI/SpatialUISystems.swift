import RealityKit
import simd
import Foundation

// MARK: - Hover Feedback System

/// Animates scale toward the hover/press target and advances phase timers.
public struct HoverFeedbackSystem: System {
    static let query = EntityQuery(where: .has(HoverStateComponent.self))
    private static let smoothingRate: Float = 18

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        let k = SpatialUIMath.smoothingFactor(rate: Self.smoothingRate, deltaTime: dt)
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var hover = entity.components[HoverStateComponent.self] else { continue }
            hover.timeInPhase += dt
            entity.components.set(hover)

            let target = hover.targetScale
            let current = entity.scale.x
            let next = SpatialUIMath.lerp(current, target, k)
            entity.scale = SIMD3<Float>(repeating: next)
        }
    }
}

// MARK: - Button System

/// Consumes press events, fires actions, and handles toggle state.
public struct ButtonSystem: System {
    static let query = EntityQuery(where: .has(SpatialButtonComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var button = entity.components[SpatialButtonComponent.self],
                  button.pressedThisFrame else { continue }
            button.pressedThisFrame = false
            if button.isToggle {
                button.isOn.toggle()
            }
            entity.components.set(button)
            button.action?(entity)
        }
    }
}

// MARK: - Radial Menu System

/// Opens/closes item entities and applies selection highlight scale.
public struct RadialMenuSystem: System {
    static let query = EntityQuery(where: .has(RadialMenuComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let menu = entity.components[RadialMenuComponent.self] else { continue }
            for (index, child) in entity.children.enumerated() where child.name.hasPrefix(SpatialUIFactory.radialItemPrefix) {
                child.isEnabled = menu.isOpen
                var hover = child.components[HoverStateComponent.self] ?? HoverStateComponent()
                let selected = menu.selectedIndex == index
                let desired: HoverPhase = selected ? .hovering : .none
                if hover.phase != desired {
                    hover.phase = desired
                    hover.timeInPhase = 0
                    child.components.set(hover)
                }
            }
        }
    }
}

// MARK: - Tooltip System

/// Shows tooltip children after continuous hover exceeds the delay.
public struct TooltipSystem: System {
    static let query = EntityQuery(where: .has(TooltipComponent.self) && .has(HoverStateComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var tooltip = entity.components[TooltipComponent.self],
                  let hover = entity.components[HoverStateComponent.self] else { continue }

            if hover.phase == .hovering {
                tooltip.hoverTime += dt
            } else {
                tooltip.hoverTime = 0
            }
            let shouldShow = tooltip.hoverTime >= tooltip.delay
            if shouldShow != tooltip.isVisible {
                tooltip.isVisible = shouldShow
                entity.findEntity(named: SpatialUIFactory.tooltipName)?.isEnabled = shouldShow
            }
            entity.components.set(tooltip)
        }
    }
}

// MARK: - Billboard System

/// Rotates billboarded entities (tooltips) to face the camera, yaw only.
public struct BillboardSystem: System {
    static let query = EntityQuery(where: .has(BillboardComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        #if os(visionOS)
        guard let cameraTransform = SpatialUICameraTracker.shared.latestTransform else { return }
        let cameraPosition = cameraTransform.translation
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            let p = entity.position(relativeTo: nil)
            entity.setOrientation(SpatialUIMath.yawBillboard(from: p, to: cameraPosition), relativeTo: nil)
        }
        #endif
    }
}

/// Lightweight camera pose cache. Feed it from your ARKit WorldTrackingProvider or head anchor.
public final class SpatialUICameraTracker: @unchecked Sendable {
    public static let shared = SpatialUICameraTracker()
    private let lock = NSLock()
    private var _latestTransform: Transform?

    private init() {}

    public var latestTransform: Transform? {
        lock.lock(); defer { lock.unlock() }
        return _latestTransform
    }

    public func update(transform: Transform) {
        lock.lock(); defer { lock.unlock() }
        _latestTransform = transform
    }
}
