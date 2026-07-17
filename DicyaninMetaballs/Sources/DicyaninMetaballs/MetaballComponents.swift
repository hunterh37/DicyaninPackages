import RealityKit
import simd

/// Attach to any entity to make it contribute to an ancestor metaball field.
public struct MetaballComponent: Component {
    /// Influence radius in meters. Field contribution reaches zero at this distance.
    public var radius: Float
    /// Field strength multiplier. Negative values carve holes.
    public var strength: Float
    /// Set false to temporarily exclude this ball without removing the component.
    public var isEnabled: Bool

    public init(radius: Float = 0.15, strength: Float = 1.0, isEnabled: Bool = true) {
        self.radius = radius
        self.strength = strength
        self.isEnabled = isEnabled
    }
}

/// Configuration for a metaball field volume.
public struct MetaballFieldConfiguration: Sendable {
    /// Grid sample points per axis. Higher = smoother surface, cubic cost.
    public var resolution: SIMD3<UInt32>
    /// Local-space bounds of the scalar field volume.
    public var boundsMin: SIMD3<Float>
    public var boundsMax: SIMD3<Float>
    /// Surface threshold. With unit strength balls, 0.5 gives a surface near half radius.
    public var isoValue: Float
    /// Vertex budget for the generated mesh. Triangles beyond this are dropped.
    public var maxVertexCount: UInt32
    /// Maximum simultaneous balls uploaded to the GPU.
    public var maxBallCount: Int
    /// Skip regeneration when no ball transform or parameter changed.
    public var regeneratesOnlyOnChange: Bool

    public init(
        resolution: SIMD3<UInt32> = [64, 64, 64],
        boundsMin: SIMD3<Float> = [-0.5, -0.5, -0.5],
        boundsMax: SIMD3<Float> = [0.5, 0.5, 0.5],
        isoValue: Float = 0.5,
        maxVertexCount: UInt32 = 262_144,
        maxBallCount: Int = 256,
        regeneratesOnlyOnChange: Bool = true
    ) {
        self.resolution = resolution
        self.boundsMin = boundsMin
        self.boundsMax = boundsMax
        self.isoValue = isoValue
        self.maxVertexCount = maxVertexCount
        self.maxBallCount = maxBallCount
        self.regeneratesOnlyOnChange = regeneratesOnlyOnChange
    }

    /// Preset tuned for many small fast-moving balls.
    public static let performance = MetaballFieldConfiguration(
        resolution: [48, 48, 48], maxVertexCount: 131_072)

    /// Preset tuned for hero close-up surfaces.
    public static let quality = MetaballFieldConfiguration(
        resolution: [96, 96, 96], maxVertexCount: 524_288)
}

/// Attach to a parent entity. Descendant entities with `MetaballComponent`
/// are merged into one isosurface mesh rendered on this entity.
public struct MetaballFieldComponent: Component {
    public var configuration: MetaballFieldConfiguration
    public var isPaused: Bool

    public init(configuration: MetaballFieldConfiguration = .init(), isPaused: Bool = false) {
        self.configuration = configuration
        self.isPaused = isPaused
    }
}

/// Internal per-field GPU state, attached by the system.
struct MetaballFieldStateComponent: Component {
    let renderer: MetaballFieldRenderer
}
