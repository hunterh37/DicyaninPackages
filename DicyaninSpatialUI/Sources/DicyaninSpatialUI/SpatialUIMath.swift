import simd

/// Pure math helpers used by systems and factories. Kept dependency-free for testability.
public enum SpatialUIMath {

    public static func clamp01(_ x: Float) -> Float {
        min(max(x, 0), 1)
    }

    public static func clamp(_ x: Float, _ lo: Float, _ hi: Float) -> Float {
        min(max(x, lo), hi)
    }

    public static func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    /// Normalizes value into 0...1 within range. Degenerate ranges return 0.
    public static func normalize(_ value: Float, in range: ClosedRange<Float>) -> Float {
        let span = range.upperBound - range.lowerBound
        guard span > .ulpOfOne else { return 0 }
        return clamp01((value - range.lowerBound) / span)
    }

    /// Clamps to range and snaps to step (anchored at lowerBound) if provided.
    public static func clampAndStep(_ value: Float, range: ClosedRange<Float>, step: Float?) -> Float {
        var v = clamp(value, range.lowerBound, range.upperBound)
        if let step, step > .ulpOfOne {
            let n = ((v - range.lowerBound) / step).rounded()
            v = clamp(range.lowerBound + n * step, range.lowerBound, range.upperBound)
        }
        return v
    }

    /// Exponential smoothing factor for frame-rate independent lerping.
    public static func smoothingFactor(rate: Float, deltaTime: Float) -> Float {
        1 - exp(-rate * max(deltaTime, 0))
    }

    /// Angle in radians of item `index` of `count` items around a circle.
    public static func radialAngle(index: Int, count: Int, startAngle: Float) -> Float {
        guard count > 0 else { return startAngle }
        return startAngle + (Float(index) / Float(count)) * 2 * .pi
    }

    /// Local XY-plane position of item `index` on a radial menu.
    public static func radialPosition(index: Int, count: Int, radius: Float, startAngle: Float) -> SIMD3<Float> {
        let a = radialAngle(index: index, count: count, startAngle: startAngle)
        return [cos(a) * radius, sin(a) * radius, 0]
    }

    /// Index of the radial item nearest to a local-space point, nil if inside dead zone.
    public static func radialHitIndex(localPoint: SIMD3<Float>,
                                      count: Int,
                                      startAngle: Float,
                                      deadZoneRadius: Float) -> Int? {
        guard count > 0 else { return nil }
        let p = SIMD2<Float>(localPoint.x, localPoint.y)
        guard simd_length(p) > deadZoneRadius else { return nil }
        var angle = atan2(p.y, p.x) - startAngle
        let sector = 2 * .pi / Float(count)
        angle += sector / 2
        angle = angle.truncatingRemainder(dividingBy: 2 * .pi)
        if angle < 0 { angle += 2 * .pi }
        let idx = Int(angle / sector)
        return min(idx, count - 1)
    }

    /// Clamps an index into 0..<count. Returns 0 for empty collections.
    public static func clampIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(index, 0), count - 1)
    }

    /// Local X center of item `index` in a centered horizontal row.
    public static func rowOffsetX(index: Int, count: Int, itemWidth: Float, spacing: Float) -> Float {
        let pitch = itemWidth + spacing
        return (Float(index) - Float(count - 1) / 2) * pitch
    }

    /// Normalized 0...1 dial parameter from a local XY point. 0.5 points up, clockwise increases.
    public static func dialParameter(localPoint: SIMD3<Float>, sweep: Float) -> Float {
        guard sweep > .ulpOfOne else { return 0.5 }
        // Angle from straight up, clockwise positive.
        let angle = atan2(localPoint.x, localPoint.y)
        return clamp01(angle / sweep + 0.5)
    }

    /// Proximity 0...1 from a distance and activation radius (1 at distance 0).
    public static func proximity(distance: Float, activationRadius: Float) -> Float {
        guard activationRadius > .ulpOfOne else { return 0 }
        return clamp01(1 - distance / activationRadius)
    }

    /// Yaw-only rotation that faces `position` toward `target` (for billboards).
    public static func yawBillboard(from position: SIMD3<Float>, to target: SIMD3<Float>) -> simd_quatf {
        let d = target - position
        let yaw = atan2(d.x, d.z)
        return simd_quatf(angle: yaw, axis: [0, 1, 0])
    }
}
