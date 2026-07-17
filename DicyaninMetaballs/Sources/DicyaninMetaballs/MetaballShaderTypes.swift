import simd

// GPU-shared layouts. Must match Shaders/Metaballs.metal exactly.

struct MetaballGPU {
    var positionRadius: SIMD4<Float>   // xyz position (field local), w radius
    var params: SIMD4<Float>           // x strength, yzw reserved
}

struct FieldUniforms {
    var boundsMin: SIMD3<Float>
    var ballCount: UInt32
    var cellSize: SIMD3<Float>
    var isoValue: Float
    var gridSize: SIMD3<UInt32>
    var maxVertices: UInt32
    var color: SIMD4<Float>
}

struct PackedFloat3 {
    var x: Float
    var y: Float
    var z: Float
}

struct MetaballVertex {
    var position: PackedFloat3
    var normal: PackedFloat3
}
