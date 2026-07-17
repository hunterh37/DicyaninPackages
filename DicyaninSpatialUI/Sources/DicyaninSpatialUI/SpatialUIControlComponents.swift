import RealityKit
import simd

// MARK: - Toggle (3D checkbox / switch)

public struct SpatialToggleComponent: Component {
    public var identifier: String
    public var isOn: Bool
    /// Set true by input systems for one frame when activated.
    public var pressedThisFrame: Bool
    /// Knob travel distance in meters along local X.
    public var travel: Float
    public var onChanged: ((Bool) -> Void)?

    public init(identifier: String = "",
                isOn: Bool = false,
                travel: Float = 0.03,
                onChanged: ((Bool) -> Void)? = nil) {
        self.identifier = identifier
        self.isOn = isOn
        self.pressedThisFrame = false
        self.travel = travel
        self.onChanged = onChanged
    }

    /// Target local X of the knob for the current state.
    public var knobTargetX: Float {
        (isOn ? 0.5 : -0.5) * travel
    }
}

// MARK: - Segmented Control

public struct SpatialSegmentedControlComponent: Component {
    public var identifier: String
    public var segments: [String]
    public var selectedIndex: Int
    /// Size of one segment in meters.
    public var segmentSize: SIMD2<Float>
    public var spacing: Float
    /// Index pressed this frame, set by input systems.
    public var pressedIndex: Int?
    public var onChanged: ((Int) -> Void)?

    public init(identifier: String = "",
                segments: [String],
                selectedIndex: Int = 0,
                segmentSize: SIMD2<Float> = [0.06, 0.035],
                spacing: Float = 0.006,
                onChanged: ((Int) -> Void)? = nil) {
        self.identifier = identifier
        self.segments = segments
        self.selectedIndex = SpatialUIMath.clampIndex(selectedIndex, count: segments.count)
        self.segmentSize = segmentSize
        self.spacing = spacing
        self.pressedIndex = nil
        self.onChanged = onChanged
    }

    /// Local X center of segment `index`.
    public func segmentOffsetX(_ index: Int) -> Float {
        SpatialUIMath.rowOffsetX(index: index, count: segments.count,
                                 itemWidth: segmentSize.x, spacing: spacing)
    }
}

// MARK: - Progress Bar

public struct SpatialProgressBarComponent: Component, Codable {
    public var identifier: String
    /// Target progress 0...1.
    public var progress: Float
    /// Smoothed progress currently displayed.
    public var displayedProgress: Float
    /// Bar length in meters along local X.
    public var length: Float
    /// Smoothing rate for fill animation, higher is snappier.
    public var smoothingRate: Float

    public init(identifier: String = "",
                progress: Float = 0,
                length: Float = 0.2,
                smoothingRate: Float = 10) {
        self.identifier = identifier
        self.progress = SpatialUIMath.clamp01(progress)
        self.displayedProgress = SpatialUIMath.clamp01(progress)
        self.length = length
        self.smoothingRate = smoothingRate
    }
}

// MARK: - Dial (rotary knob)

public struct SpatialDialComponent: Component {
    public var identifier: String
    public var value: Float
    public var range: ClosedRange<Float>
    public var step: Float?
    /// Total sweep angle in radians (centered on straight up).
    public var sweep: Float
    public var isDragging: Bool
    public var onChanged: ((Float) -> Void)?

    public init(identifier: String = "",
                value: Float = 0,
                range: ClosedRange<Float> = 0...1,
                step: Float? = nil,
                sweep: Float = .pi * 1.5,
                onChanged: ((Float) -> Void)? = nil) {
        self.identifier = identifier
        self.range = range
        self.step = step
        self.sweep = sweep
        self.isDragging = false
        self.onChanged = onChanged
        self.value = SpatialUIMath.clampAndStep(value, range: range, step: step)
    }

    public var normalizedValue: Float {
        SpatialUIMath.normalize(value, in: range)
    }

    /// Knob roll angle (radians about local Z) for the current value. 0 points up, positive sweep is clockwise.
    public var knobAngle: Float {
        (normalizedValue - 0.5) * sweep
    }

    /// Sets value from a local XY point relative to the dial center.
    public mutating func setValue(fromLocalPoint p: SIMD3<Float>) {
        let t = SpatialUIMath.dialParameter(localPoint: p, sweep: sweep)
        value = SpatialUIMath.clampAndStep(
            SpatialUIMath.lerp(range.lowerBound, range.upperBound, t),
            range: range, step: step)
    }
}

// MARK: - Stepper

public struct SpatialStepperComponent: Component {
    public var identifier: String
    public var value: Float
    public var range: ClosedRange<Float>
    public var step: Float
    /// -1 or +1 set by input systems for one frame.
    public var pressedDirection: Int?
    public var onChanged: ((Float) -> Void)?

    public init(identifier: String = "",
                value: Float = 0,
                range: ClosedRange<Float> = 0...10,
                step: Float = 1,
                onChanged: ((Float) -> Void)? = nil) {
        self.identifier = identifier
        self.range = range
        self.step = max(step, .ulpOfOne)
        self.pressedDirection = nil
        self.onChanged = onChanged
        self.value = SpatialUIMath.clamp(value, range.lowerBound, range.upperBound)
    }

    public mutating func apply(direction: Int) -> Bool {
        let old = value
        value = SpatialUIMath.clamp(value + Float(direction) * step,
                                    range.lowerBound, range.upperBound)
        return value != old
    }
}

// MARK: - Dropdown

public struct SpatialDropdownComponent: Component {
    public var identifier: String
    public var items: [String]
    public var selectedIndex: Int
    public var isOpen: Bool
    /// Size of one row in meters.
    public var rowSize: SIMD2<Float>
    public var rowSpacing: Float
    /// Index pressed this frame, set by input systems.
    public var pressedIndex: Int?
    public var onSelect: ((Int) -> Void)?

    public init(identifier: String = "",
                items: [String],
                selectedIndex: Int = 0,
                rowSize: SIMD2<Float> = [0.12, 0.03],
                rowSpacing: Float = 0.004,
                onSelect: ((Int) -> Void)? = nil) {
        self.identifier = identifier
        self.items = items
        self.selectedIndex = SpatialUIMath.clampIndex(selectedIndex, count: items.count)
        self.isOpen = false
        self.rowSize = rowSize
        self.rowSpacing = rowSpacing
        self.pressedIndex = nil
        self.onSelect = onSelect
    }

    /// Local Y center of row `index` (rows drop below the header).
    public func rowOffsetY(_ index: Int) -> Float {
        -(rowSize.y + rowSpacing) * Float(index + 1)
    }
}
