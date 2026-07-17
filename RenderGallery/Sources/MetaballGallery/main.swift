import Foundation
import AppKit
import RealityKit
import Metal
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import simd
import DicyaninMetaballs

@MainActor
final class OffscreenRenderer {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let size: Int

    init(size: Int) throws {
        guard let dev = MTLCreateSystemDefaultDevice() else {
            throw NSError(domain: "render", code: 1, userInfo: [NSLocalizedDescriptionKey: "no metal device"])
        }
        self.device = dev
        self.queue = dev.makeCommandQueue()!
        self.size = size
    }

    func makeTexture() -> MTLTexture {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm, width: size, height: size, mipmapped: false)
        desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        desc.storageMode = .shared
        return device.makeTexture(descriptor: desc)!
    }

    func render(entity: Entity, cameraDistance: Float, target: SIMD3<Float>) throws -> CGImage {
        let renderer = try RealityRenderer()

        let content = Entity()
        content.addChild(entity)
        renderer.entities.append(content)

        let sun = DirectionalLight()
        sun.light.intensity = 6000
        sun.look(at: target, from: target + [2, 4, 3], relativeTo: nil)
        renderer.entities.append(sun)

        let fill = DirectionalLight()
        fill.light.intensity = 2500
        fill.look(at: target, from: target + [-3, 2, 2], relativeTo: nil)
        renderer.entities.append(fill)

        if let ibl = try? EnvironmentResource(equirectangular: Self.gradientImage()) {
            var iblc = ImageBasedLightComponent(source: .single(ibl), intensityExponent: 1.0)
            iblc.inheritsRotation = true
            let iblEntity = Entity()
            iblEntity.components.set(iblc)
            renderer.entities.append(iblEntity)
        }

        let cam = PerspectiveCamera()
        cam.camera.fieldOfViewInDegrees = 40
        let camPos = target + SIMD3<Float>(0.35, 0.25, cameraDistance)
        cam.position = camPos
        cam.look(at: target, from: camPos, relativeTo: nil)
        renderer.activeCamera = cam
        renderer.entities.append(cam)

        let colorTex = makeTexture()

        let cmd = queue.makeCommandBuffer()!
        let output = try RealityRenderer.CameraOutput(
            .singleProjection(colorTexture: colorTex))
        try renderer.updateAndRender(
            deltaTime: 0.1, cameraOutput: output,
            whenScheduled: { _ in }, onComplete: { _ in },
            actionsBeforeRender: [], actionsAfterRender: [])
        cmd.commit()
        cmd.waitUntilCompleted()

        return try Self.cgImage(from: colorTex)
    }

    static func gradientImage() throws -> CGImage {
        let w = 512, h = 256
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [CGColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 1),
                      CGColor(red: 0.42, green: 0.48, blue: 0.62, alpha: 1)] as CFArray
        let grad = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1])!
        ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: h), options: [])
        return ctx.makeImage()!
    }

    static func cgImage(from tex: MTLTexture) throws -> CGImage {
        let w = tex.width, h = tex.height
        let rowBytes = w * 4
        var raw = [UInt8](repeating: 0, count: rowBytes * h)
        raw.withUnsafeMutableBytes { ptr in
            tex.getBytes(ptr.baseAddress!, bytesPerRow: rowBytes,
                         from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        }
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: &raw, width: w, height: h, bitsPerComponent: 8,
                            bytesPerRow: rowBytes, space: cs,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return ctx.makeImage()!
    }
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "png", code: 1)
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { throw NSError(domain: "png", code: 2) }
}

struct Scene {
    let name: String
    let config: MetaballFieldConfiguration
    let balls: [DicyaninMetaballs.Ball]
    let material: any RealityKit.Material
}

func material(_ r: Double, _ g: Double, _ b: Double, roughness: Float, metallic: Bool) -> any RealityKit.Material {
    SimpleMaterial(color: NSColor(red: r, green: g, blue: b, alpha: 1),
                   roughness: .init(floatLiteral: roughness), isMetallic: metallic)
}

@MainActor
func run() async throws {
    let outDir = URL(fileURLWithPath: "output/metaballs", isDirectory: true)
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    let renderer = try OffscreenRenderer(size: 900)

    // Warm-up: the first RealityRenderer frame comes back empty.
    let warm = ModelEntity(mesh: .generateSphere(radius: 0.1), materials: [SimpleMaterial()])
    _ = try renderer.render(entity: warm, cameraDistance: 1.0, target: [0, 0, 0])

    let scenes: [Scene] = [
        Scene(
            name: "two-ball-merge",
            config: .init(resolution: [64, 64, 64], isoValue: 0.5),
            balls: [.init(position: [-0.14, 0, 0], radius: 0.26),
                    .init(position: [0.14, 0, 0], radius: 0.26)],
            material: material(0.20, 0.75, 0.95, roughness: 0.1, metallic: true)),
        Scene(
            name: "cluster",
            config: .init(resolution: [80, 80, 80], isoValue: 0.5),
            balls: [.init(position: [0, 0.12, 0], radius: 0.22),
                    .init(position: [-0.16, -0.08, 0.05], radius: 0.2),
                    .init(position: [0.16, -0.08, -0.05], radius: 0.2),
                    .init(position: [0, -0.02, 0.16], radius: 0.18)],
            material: material(0.95, 0.35, 0.55, roughness: 0.25, metallic: false)),
        Scene(
            name: "carved-hole",
            config: .init(resolution: [80, 80, 80], isoValue: 0.5),
            balls: [.init(position: [0, 0, 0], radius: 0.4, strength: 1.0),
                    .init(position: [0.05, 0.05, 0.18], radius: 0.24, strength: -1.0)],
            material: material(0.85, 0.7, 0.2, roughness: 0.15, metallic: true)),
        Scene(
            name: "low-iso-blobby",
            config: .init(resolution: [80, 80, 80], isoValue: 0.2),
            balls: [.init(position: [-0.14, 0, 0], radius: 0.26),
                    .init(position: [0.14, 0, 0], radius: 0.26)],
            material: material(0.55, 0.45, 0.95, roughness: 0.3, metallic: false)),
        Scene(
            name: "high-iso-tight",
            config: .init(resolution: [80, 80, 80], isoValue: 0.85),
            balls: [.init(position: [-0.14, 0, 0], radius: 0.3),
                    .init(position: [0.14, 0, 0], radius: 0.3)],
            material: material(0.3, 0.9, 0.6, roughness: 0.2, metallic: false)),
        Scene(
            name: "quality-grid",
            config: .quality,
            balls: (0..<6).map { i in
                let a = Float(i) / 6 * 2 * .pi
                return DicyaninMetaballs.Ball(
                    position: [0.22 * cos(a), 0.22 * sin(a), 0.05 * Float(i % 2)],
                    radius: 0.2)
            },
            material: material(0.9, 0.55, 0.25, roughness: 0.1, metallic: true))
    ]

    let presetScenes: [(MetaballPreset, Float, any RealityKit.Material)] = [
        (.lavaLamp, 3.2, material(0.95, 0.4, 0.15, roughness: 0.2, metallic: false)),
        (.vortex, 1.4, material(0.25, 0.85, 0.9, roughness: 0.1, metallic: true)),
        (.dnaHelix, 0.8, material(0.5, 0.95, 0.4, roughness: 0.25, metallic: false)),
        (.rainMerge, 2.1, material(0.35, 0.55, 0.95, roughness: 0.05, metallic: true)),
        (.pulseCore, 1.9, material(0.9, 0.25, 0.75, roughness: 0.15, metallic: true))
    ]

    for scene in scenes {
        let entity = try await DicyaninMetaballs.bakedField(
            configuration: scene.config, balls: scene.balls, materials: [scene.material])
        let img = try renderer.render(entity: entity, cameraDistance: 1.7, target: [0, 0, 0])
        let url = outDir.appendingPathComponent("metaball-\(scene.name).png")
        try writePNG(img, to: url)
        print("wrote \(url.lastPathComponent)")
    }

    for (preset, sampleTime, mat) in presetScenes {
        let entity = try await DicyaninMetaballs.bakedField(
            configuration: preset.configuration,
            balls: preset.balls(at: sampleTime),
            materials: [mat])
        let img = try renderer.render(entity: entity, cameraDistance: 1.9, target: [0, 0, 0])
        let url = outDir.appendingPathComponent("metaball-preset-\(preset.rawValue).png")
        try writePNG(img, to: url)
        print("wrote \(url.lastPathComponent)")
    }
}

try await run()
