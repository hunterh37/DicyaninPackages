import Foundation
import Metal
import RealityKit
import simd

enum MetaballRendererError: Error {
    case metalUnavailable
    case pipelineCreationFailed(String)
}

/// Owns the Metal pipelines, GPU buffers, and LowLevelMesh for one field.
/// Field evaluation and marching cubes both run on the GPU; the CPU only
/// uploads ball data and reads back a single vertex count.
// State mutation is confined to the main actor; the GPU completion handler
// only reads an immutable buffer reference before hopping back to main.
final class MetaballFieldRenderer: @unchecked Sendable {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let fieldPipeline: MTLComputePipelineState
    private let marchingCubesPipeline: MTLComputePipelineState

    private let configuration: MetaballFieldConfiguration
    private let fieldBuffer: MTLBuffer
    private let ballBuffer: MTLBuffer
    private let counterBuffer: MTLBuffer
    private var uniforms: FieldUniforms

    let lowLevelMesh: LowLevelMesh
    private(set) var meshResource: MeshResource?

    private var lastBallHash: Int = 0
    private var inFlight = false

    var isInFlight: Bool { inFlight }

    @MainActor
    init(configuration: MetaballFieldConfiguration) throws {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            throw MetaballRendererError.metalUnavailable
        }
        self.device = device
        self.commandQueue = queue
        self.configuration = configuration

        let library = try Self.makeLibrary(device: device)
        func pipeline(_ name: String) throws -> MTLComputePipelineState {
            guard let fn = library.makeFunction(name: name) else {
                throw MetaballRendererError.pipelineCreationFailed(name)
            }
            return try device.makeComputePipelineState(function: fn)
        }
        fieldPipeline = try pipeline("metaballField")
        marchingCubesPipeline = try pipeline("metaballMarchingCubes")

        let grid = configuration.resolution
        let sampleCount = Int(grid.x) * Int(grid.y) * Int(grid.z)
        guard let field = device.makeBuffer(
                length: sampleCount * MemoryLayout<Float>.stride,
                options: .storageModePrivate),
              let balls = device.makeBuffer(
                length: max(1, configuration.maxBallCount) * MemoryLayout<MetaballGPU>.stride,
                options: .storageModeShared),
              let counter = device.makeBuffer(
                length: MemoryLayout<UInt32>.stride,
                options: .storageModeShared) else {
            throw MetaballRendererError.pipelineCreationFailed("buffers")
        }
        fieldBuffer = field
        ballBuffer = balls
        counterBuffer = counter

        let extent = configuration.boundsMax - configuration.boundsMin
        uniforms = FieldUniforms(
            boundsMin: configuration.boundsMin,
            ballCount: 0,
            cellSize: extent / SIMD3<Float>(
                Float(grid.x - 1), Float(grid.y - 1), Float(grid.z - 1)),
            isoValue: configuration.isoValue,
            gridSize: grid,
            maxVertices: configuration.maxVertexCount,
            color: [1, 1, 1, 1])

        lowLevelMesh = try Self.makeMesh(vertexCapacity: Int(configuration.maxVertexCount))
    }

    private static func makeLibrary(device: MTLDevice) throws -> MTLLibrary {
        if let lib = try? device.makeDefaultLibrary(bundle: .module) { return lib }
        let bundle = Bundle.module
        guard let metalURL = bundle.url(forResource: "Metaballs", withExtension: "metal"),
              let headerURL = bundle.url(forResource: "MarchingCubesTables", withExtension: "h") else {
            throw MetaballRendererError.pipelineCreationFailed("shader source missing")
        }
        var source = try String(contentsOf: metalURL, encoding: .utf8)
        let header = try String(contentsOf: headerURL, encoding: .utf8)
        source = source.replacingOccurrences(
            of: "#include \"MarchingCubesTables.h\"", with: header)
        return try device.makeLibrary(source: source, options: nil)
    }

    @MainActor
    func makeMeshResource() async throws -> MeshResource {
        if let meshResource { return meshResource }
        let resource = try await MeshResource(from: lowLevelMesh)
        meshResource = resource
        return resource
    }

    @MainActor
    private static func makeMesh(vertexCapacity: Int) throws -> LowLevelMesh {
        let stride = MemoryLayout<MetaballVertex>.stride
        var descriptor = LowLevelMesh.Descriptor()
        descriptor.vertexCapacity = vertexCapacity
        descriptor.indexCapacity = vertexCapacity
        descriptor.vertexAttributes = [
            .init(semantic: .position, format: .float3, offset: 0),
            .init(semantic: .normal, format: .float3,
                  offset: MemoryLayout<PackedFloat3>.stride)
        ]
        descriptor.vertexLayouts = [.init(bufferIndex: 0, bufferStride: stride)]
        descriptor.indexType = .uint32
        let mesh = try LowLevelMesh(descriptor: descriptor)
        // Non-indexed generation: fill the index buffer once with the identity map.
        mesh.withUnsafeMutableIndices { raw in
            let indices = raw.bindMemory(to: UInt32.self)
            for i in 0..<vertexCapacity { indices[i] = UInt32(i) }
        }
        return mesh
    }

    /// Uploads ball data and regenerates the isosurface on the GPU.
    /// Returns false when the update was skipped (unchanged, paused, or busy).
    @MainActor
    func update(balls: [MetaballGPU]) -> Bool {
        guard !inFlight else { return false }

        if configuration.regeneratesOnlyOnChange {
            var hasher = Hasher()
            for b in balls {
                for v in [b.positionRadius, b.params] {
                    hasher.combine(v.x); hasher.combine(v.y)
                    hasher.combine(v.z); hasher.combine(v.w)
                }
            }
            let hash = hasher.finalize()
            if hash == lastBallHash { return false }
            lastBallHash = hash
        }

        let count = min(balls.count, configuration.maxBallCount)
        if count > 0 {
            ballBuffer.contents().withMemoryRebound(
                to: MetaballGPU.self, capacity: count) { ptr in
                for i in 0..<count { ptr[i] = balls[i] }
            }
        }
        uniforms.ballCount = UInt32(count)
        counterBuffer.contents().storeBytes(of: UInt32(0), toByteOffset: 0, as: UInt32.self)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return false }
        inFlight = true

        let vertexBuffer = lowLevelMesh.replace(bufferIndex: 0, using: commandBuffer)
        var u = uniforms
        let grid = MTLSize(
            width: Int(u.gridSize.x), height: Int(u.gridSize.y), depth: Int(u.gridSize.z))
        let tg = MTLSize(width: 8, height: 8, depth: 4)

        encoder.setComputePipelineState(fieldPipeline)
        encoder.setBuffer(fieldBuffer, offset: 0, index: 0)
        encoder.setBuffer(ballBuffer, offset: 0, index: 1)
        encoder.setBytes(&u, length: MemoryLayout<FieldUniforms>.stride, index: 2)
        encoder.dispatchThreads(grid, threadsPerThreadgroup: tg)

        encoder.setComputePipelineState(marchingCubesPipeline)
        encoder.setBuffer(vertexBuffer, offset: 0, index: 3)
        encoder.setBuffer(counterBuffer, offset: 0, index: 4)
        encoder.dispatchThreads(grid, threadsPerThreadgroup: tg)
        encoder.endEncoding()

        commandBuffer.addCompletedHandler { [weak self] _ in
            guard let self else { return }
            let vertexCount = self.counterBuffer.contents().load(as: UInt32.self)
            Task { @MainActor in
                self.applyParts(vertexCount: Int(vertexCount))
                self.inFlight = false
            }
        }
        commandBuffer.commit()
        return true
    }

    @MainActor
    private func applyParts(vertexCount: Int) {
        let bounds = BoundingBox(min: configuration.boundsMin, max: configuration.boundsMax)
        lowLevelMesh.parts.replaceAll([
            LowLevelMesh.Part(
                indexOffset: 0,
                indexCount: vertexCount,
                topology: .triangle,
                materialIndex: 0,
                bounds: bounds)
        ])
    }
}
