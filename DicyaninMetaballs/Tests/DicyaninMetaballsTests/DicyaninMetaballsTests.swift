import Testing
import simd
@testable import DicyaninMetaballs

@Suite struct ConfigurationTests {
    @Test func defaultsAreValid() {
        let config = MetaballFieldConfiguration()
        #expect(config.resolution == SIMD3<UInt32>(64, 64, 64))
        #expect(config.isoValue == 0.5)
        #expect(config.boundsMin.x < config.boundsMax.x)
        #expect(config.maxVertexCount > 0)
        #expect(config.maxBallCount > 0)
    }

    @Test func presetsScaleAsDocumented() {
        #expect(MetaballFieldConfiguration.performance.resolution.x
                < MetaballFieldConfiguration.quality.resolution.x)
        #expect(MetaballFieldConfiguration.performance.maxVertexCount
                < MetaballFieldConfiguration.quality.maxVertexCount)
    }

    @Test func componentDefaults() {
        let ball = MetaballComponent()
        #expect(ball.radius > 0)
        #expect(ball.strength == 1.0)
        #expect(ball.isEnabled)
    }

    @Test func gpuLayoutSizes() {
        #expect(MemoryLayout<MetaballGPU>.stride == 32)
        #expect(MemoryLayout<MetaballVertex>.stride == 24)
        #expect(MemoryLayout<PackedFloat3>.stride == 12)
    }
}
