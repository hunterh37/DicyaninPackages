import RealityKit
import simd

/// Built-in animated metaball arrangements. Attach via
/// `Entity.metaballPreset(_:)` for a ready-made, continuously
/// animated field.
public enum MetaballPreset: String, CaseIterable, Sendable {
    /// Blobs slowly rising and sinking with heat wobble, merging mid-column.
    case lavaLamp
    /// Swarm spiraling around a vertical axis, tightening toward the core.
    case vortex
    /// Two counter-rotating strands with connecting rungs.
    case dnaHelix
    /// Droplets falling into a pooled blob, absorbed on contact.
    case rainMerge
    /// Breathing core orbited by satellites and a negative carver
    /// that gouges a moving crater across the surface.
    case pulseCore

    public var ballCount: Int {
        switch self {
        case .lavaLamp: return 7
        case .vortex: return 12
        case .dnaHelix: return 18
        case .rainMerge: return 9
        case .pulseCore: return 8
        }
    }

    public var configuration: MetaballFieldConfiguration {
        switch self {
        case .dnaHelix:
            return MetaballFieldConfiguration(
                resolution: [64, 96, 64],
                boundsMin: [-0.35, -0.55, -0.35],
                boundsMax: [0.35, 0.55, 0.35],
                isoValue: 0.3)
        case .lavaLamp, .rainMerge:
            return MetaballFieldConfiguration(
                resolution: [64, 96, 64],
                boundsMin: [-0.45, -0.8, -0.45],
                boundsMax: [0.45, 0.6, 0.45],
                isoValue: 0.4)
        case .vortex, .pulseCore:
            return MetaballFieldConfiguration(
                resolution: [80, 80, 80], isoValue: 0.35)
        }
    }

    /// Ball states at an absolute time, in field-local space.
    public func balls(at time: Float) -> [DicyaninMetaballs.Ball] {
        switch self {
        case .lavaLamp: return Self.lavaLamp(time)
        case .vortex: return Self.vortex(time)
        case .dnaHelix: return Self.dnaHelix(time)
        case .rainMerge: return Self.rainMerge(time)
        case .pulseCore: return Self.pulseCore(time)
        }
    }

    private static func hash01(_ i: Int, _ salt: Float) -> Float {
        let v = sin(Float(i) * 127.1 + salt * 311.7) * 43758.5453
        return v - floor(v)
    }

    private static func lavaLamp(_ t: Float) -> [DicyaninMetaballs.Ball] {
        var balls: [DicyaninMetaballs.Ball] = [
            // Heated base pool.
            .init(position: [0, -0.42, 0], radius: 0.34, strength: 1.2)
        ]
        for i in 0..<6 {
            let phase = hash01(i, 1) * 2 * .pi
            let speed = 0.25 + 0.12 * hash01(i, 2)
            let cycle = t * speed + phase
            // Asymmetric rise and fall: slow up, faster down.
            let s = sin(cycle)
            let y = -0.35 + 0.68 * (0.5 + 0.5 * (s + 0.3 * sin(2 * cycle)))
            let wob = 0.06 * sin(t * 1.3 + phase * 3)
            let x = (hash01(i, 3) - 0.5) * 0.36 + wob
            let z = (hash01(i, 4) - 0.5) * 0.36 + 0.05 * cos(t * 1.1 + phase)
            let r = 0.12 + 0.05 * hash01(i, 5) + 0.02 * sin(t * 2 + phase)
            balls.append(.init(position: [x, min(y, 0.45), z], radius: r))
        }
        return balls
    }

    private static func vortex(_ t: Float) -> [DicyaninMetaballs.Ball] {
        var balls: [DicyaninMetaballs.Ball] = [
            .init(position: [0, 0, 0], radius: 0.16, strength: 1.4)
        ]
        for i in 0..<11 {
            let f = Float(i) / 11
            // Each ball orbits at its own radius and height; inner rings spin faster.
            let orbit = 0.1 + 0.28 * f
            let speed = 2.2 - 1.4 * f
            let a = t * speed + f * 2 * .pi * 3
            let y = -0.3 + 0.6 * f + 0.04 * sin(t * 3 + f * 20)
            balls.append(.init(
                position: [orbit * cos(a), y, orbit * sin(a)],
                radius: 0.13 + 0.07 * (1 - f)))
        }
        return balls
    }

    private static func dnaHelix(_ t: Float) -> [DicyaninMetaballs.Ball] {
        var balls: [DicyaninMetaballs.Ball] = []
        let turns: Float = 1.6
        for i in 0..<7 {
            let f = Float(i) / 6
            let y = -0.45 + 0.9 * f
            let a = t * 0.8 + f * turns * 2 * .pi
            let r: Float = 0.15
            balls.append(.init(position: [r * cos(a), y, r * sin(a)], radius: 0.16))
            balls.append(.init(position: [-r * cos(a), y, -r * sin(a)], radius: 0.16))
        }
        // Rungs bridging the strands at alternating heights.
        for i in 0..<4 {
            let f = (Float(i) + 0.5) / 4
            let y = -0.45 + 0.9 * f
            let a = t * 0.8 + f * turns * 2 * .pi
            let bridge = 0.16 * sin(t * 1.5 + Float(i)) * 0.5
            balls.append(.init(
                position: [bridge * cos(a), y, bridge * sin(a)],
                radius: 0.13, strength: 0.9))
        }
        return balls
    }

    private static func rainMerge(_ t: Float) -> [DicyaninMetaballs.Ball] {
        var balls: [DicyaninMetaballs.Ball] = [
            // Pool that visibly swells as drops land.
            .init(position: [0, -0.42, 0],
                  radius: 0.3 + 0.03 * sin(t * 2.7),
                  strength: 1.3)
        ]
        for i in 0..<8 {
            let phase = hash01(i, 7)
            let period = 1.6 + 1.2 * hash01(i, 8)
            let cycle = (t / period + phase).truncatingRemainder(dividingBy: 1)
            // Quadratic fall from top; shrink into the pool near the bottom.
            let y = 0.5 - 1.0 * cycle * cycle
            let fade = min(1, max(0, (y + 0.32) / 0.12))
            let x = (hash01(i, 9) - 0.5) * 0.5
            let z = (hash01(i, 10) - 0.5) * 0.5
            balls.append(.init(
                position: [x, max(y, -0.38), z],
                radius: 0.1 * fade + 0.02))
        }
        return balls
    }

    private static func pulseCore(_ t: Float) -> [DicyaninMetaballs.Ball] {
        let breathe = 0.26 + 0.05 * sin(t * 1.6)
        var balls: [DicyaninMetaballs.Ball] = [
            .init(position: [0, 0, 0], radius: breathe, strength: 1.3)
        ]
        for i in 0..<6 {
            let f = Float(i) / 6 * 2 * .pi
            let tilt = 0.6 * sin(t * 0.7 + f)
            let a = t * (1.1 + 0.2 * Float(i % 3)) + f
            let orbit = 0.3 + 0.05 * sin(t + f * 2)
            balls.append(.init(
                position: [orbit * cos(a), orbit * sin(a) * tilt, orbit * sin(a)],
                radius: 0.1 + 0.03 * sin(t * 2.3 + f)))
        }
        // Negative carver sweeping across the core surface.
        let ca = t * 1.7
        balls.append(.init(
            position: [0.24 * cos(ca), 0.12 * sin(t * 0.9), 0.24 * sin(ca)],
            radius: 0.16, strength: -0.9))
        return balls
    }
}

/// Attach to a field entity to drive its child balls through a preset
/// animation. `Entity.metaballPreset(_:)` sets everything up.
public struct MetaballPresetComponent: Component {
    public var preset: MetaballPreset
    /// Playback rate multiplier.
    public var speed: Float
    /// Accumulated animation time, advanced by the system.
    public var time: Float

    public init(preset: MetaballPreset, speed: Float = 1.0, time: Float = 0) {
        self.preset = preset
        self.speed = speed
        self.time = time
    }
}

/// Advances preset animations by repositioning the field's child metaballs.
public struct MetaballPresetSystem: System {
    private static let query = EntityQuery(where: .has(MetaballPresetComponent.self))

    public init(scene: RealityKit.Scene) {}

    public func update(context: SceneUpdateContext) {
        MainActor.assumeIsolated {
            let dt = Float(context.deltaTime)
            for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
                guard var presetComp = entity.components[MetaballPresetComponent.self] else { continue }
                presetComp.time += dt * presetComp.speed
                entity.components.set(presetComp)
                Self.apply(preset: presetComp.preset, time: presetComp.time, to: entity)
            }
        }
    }

    @MainActor
    static func apply(preset: MetaballPreset, time: Float, to field: Entity) {
        let balls = preset.balls(at: time)
        var children = field.children.filter { $0.components.has(MetaballComponent.self) }
        while children.count < balls.count {
            let ball = Entity.metaball()
            field.addChild(ball)
            children.append(ball)
        }
        for (i, child) in children.enumerated() {
            guard i < balls.count else {
                child.components[MetaballComponent.self]?.isEnabled = false
                continue
            }
            let spec = balls[i]
            child.position = spec.position
            child.components.set(MetaballComponent(
                radius: spec.radius, strength: spec.strength))
        }
    }
}

public extension Entity {
    /// Creates a fully animated preset metaball field. Requires
    /// `DicyaninMetaballs.register()`.
    @MainActor
    static func metaballPreset(
        _ preset: MetaballPreset,
        speed: Float = 1.0,
        materials: [any RealityKit.Material] = []
    ) -> Entity {
        let entity = Entity.metaballField(
            configuration: preset.configuration, materials: materials)
        entity.name = "MetaballPreset.\(preset.rawValue)"
        entity.components.set(MetaballPresetComponent(preset: preset, speed: speed))
        MetaballPresetSystem.apply(preset: preset, time: 0, to: entity)
        return entity
    }
}
