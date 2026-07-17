import RealityKit
import simd

// MARK: - Input

/// How an element can be interacted with.
public struct SpatialInputOptions: OptionSet, Codable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let gazePinch = SpatialInputOptions(rawValue: 1 << 0)
    public static let directTouch = SpatialInputOptions(rawValue: 1 << 1)
    public static let all: SpatialInputOptions = [.gazePinch, .directTouch]
}

/// Marks an entity as a spatial UI input target. Systems only process entities with this component.
public struct SpatialInputTargetComponent: Component, Codable {
    public var options: SpatialInputOptions
    public var isEnabled: Bool

    public init(options: SpatialInputOptions = .all, isEnabled: Bool = true) {
        self.options = options
        self.isEnabled = isEnabled
    }
}

// MARK: - Hover

public enum HoverPhase: Int, Codable, Sendable {
    case none
    case hovering
    case pressed
}

/// Tracks hover/press state driven by hand proximity or gaze.
public struct HoverStateComponent: Component, Codable {
    public var phase: HoverPhase
    /// 0...1 proximity factor for direct touch (1 = touching).
    public var proximity: Float
    /// Time in current phase, seconds.
    public var timeInPhase: Float
    /// Scale applied to entity when hovering.
    public var hoverScale: Float
    /// Scale applied when pressed.
    public var pressScale: Float

    public init(phase: HoverPhase = .none,
                proximity: Float = 0,
                timeInPhase: Float = 0,
                hoverScale: Float = 1.08,
                pressScale: Float = 0.94) {
        self.phase = phase
        self.proximity = proximity
        self.timeInPhase = timeInPhase
        self.hoverScale = hoverScale
        self.pressScale = pressScale
    }

    public var targetScale: Float {
        switch phase {
        case .none: return 1
        case .hovering: return hoverScale
        case .pressed: return pressScale
        }
    }
}

// MARK: - Button

public struct SpatialButtonComponent: Component {
    public var identifier: String
    public var isToggle: Bool
    public var isOn: Bool
    /// Set true by input systems for one frame when activated.
    public var pressedThisFrame: Bool
    public var action: ((Entity) -> Void)?

    public init(identifier: String = "",
                isToggle: Bool = false,
                isOn: Bool = false,
                action: ((Entity) -> Void)? = nil) {
        self.identifier = identifier
        self.isToggle = isToggle
        self.isOn = isOn
        self.pressedThisFrame = false
        self.action = action
    }
}

// MARK: - Slider

public struct SpatialSliderComponent: Component {
    public var identifier: String
    public var value: Float
    public var range: ClosedRange<Float>
    public var step: Float?
    /// Track length in meters along local X.
    public var trackLength: Float
    public var isDragging: Bool
    public var onChanged: ((Float) -> Void)?

    public init(identifier: String = "",
                value: Float = 0,
                range: ClosedRange<Float> = 0...1,
                step: Float? = nil,
                trackLength: Float = 0.2,
                onChanged: ((Float) -> Void)? = nil) {
        self.identifier = identifier
        self.range = range
        self.step = step
        self.trackLength = trackLength
        self.isDragging = false
        self.onChanged = onChanged
        self.value = 0
        self.value = SpatialUIMath.clampAndStep(value, range: range, step: step)
    }

    /// Normalized 0...1 position of value within range.
    public var normalizedValue: Float {
        SpatialUIMath.normalize(value, in: range)
    }

    /// Local X offset of the thumb for the current value.
    public var thumbOffsetX: Float {
        (normalizedValue - 0.5) * trackLength
    }

    /// Sets value from a local X position on the track.
    public mutating func setValue(fromLocalX x: Float) {
        let t = SpatialUIMath.clamp01(x / trackLength + 0.5)
        value = SpatialUIMath.clampAndStep(
            SpatialUIMath.lerp(range.lowerBound, range.upperBound, t),
            range: range, step: step)
    }
}

// MARK: - Radial Menu

public struct RadialMenuItem: Codable, Sendable, Equatable {
    public var identifier: String
    public var title: String

    public init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }
}

public struct RadialMenuComponent: Component {
    public var items: [RadialMenuItem]
    public var radius: Float
    /// Start angle in radians (0 = +X axis, counterclockwise in local XY plane).
    public var startAngle: Float
    public var isOpen: Bool
    public var selectedIndex: Int?
    public var onSelect: ((RadialMenuItem) -> Void)?

    public init(items: [RadialMenuItem],
                radius: Float = 0.12,
                startAngle: Float = .pi / 2,
                isOpen: Bool = false,
                onSelect: ((RadialMenuItem) -> Void)? = nil) {
        self.items = items
        self.radius = radius
        self.startAngle = startAngle
        self.isOpen = isOpen
        self.selectedIndex = nil
        self.onSelect = onSelect
    }
}

// MARK: - Tooltip

public struct TooltipComponent: Component, Codable {
    public var text: String
    /// Delay before showing, seconds of continuous hover.
    public var delay: Float
    /// Local offset from the owning entity.
    public var offset: SIMD3<Float>
    public var isVisible: Bool
    /// Internal hover accumulator.
    public var hoverTime: Float

    public init(text: String,
                delay: Float = 0.6,
                offset: SIMD3<Float> = [0, 0.06, 0]) {
        self.text = text
        self.delay = delay
        self.offset = offset
        self.isVisible = false
        self.hoverTime = 0
    }
}

// MARK: - Curved Panel

public struct CurvedPanelComponent: Component, Codable {
    /// Arc width in meters (chord along the curve).
    public var width: Float
    public var height: Float
    /// Cylinder radius the panel is curved around.
    public var curveRadius: Float
    public var cornerSegments: Int

    public init(width: Float = 0.6,
                height: Float = 0.35,
                curveRadius: Float = 1.0,
                cornerSegments: Int = 24) {
        self.width = width
        self.height = height
        self.curveRadius = max(curveRadius, 0.01)
        self.cornerSegments = max(cornerSegments, 2)
    }

    /// Total arc angle subtended by the panel, radians.
    public var arcAngle: Float {
        width / max(curveRadius, 0.001)
    }
}

// MARK: - Billboard (tooltips face the user)

/// Unambiguous alias, RealityKit also declares a BillboardComponent on some platforms.
public typealias DicyaninBillboardComponent = BillboardComponent

public struct BillboardComponent: Component, Codable {

    public init() {}
}

// MARK: - Registration

public enum DicyaninSpatialUI {
    private static var registered = false

    /// Registers all components and systems. Call once at app launch.
    @MainActor
    public static func register() {
        guard !registered else { return }
        registered = true
        SpatialInputTargetComponent.registerComponent()
        HoverStateComponent.registerComponent()
        SpatialButtonComponent.registerComponent()
        SpatialSliderComponent.registerComponent()
        RadialMenuComponent.registerComponent()
        TooltipComponent.registerComponent()
        CurvedPanelComponent.registerComponent()
        BillboardComponent.registerComponent()
        HoverFeedbackSystem.registerSystem()
        ButtonSystem.registerSystem()
        RadialMenuSystem.registerSystem()
        TooltipSystem.registerSystem()
        BillboardSystem.registerSystem()
    }
}
