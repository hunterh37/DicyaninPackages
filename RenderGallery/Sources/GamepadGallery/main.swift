import Foundation
import RealityKit
import Metal
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import simd
#if canImport(AppKit)
import AppKit
#endif
import DicyaninVirtualJoystick

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

    func render(entity: Entity, cameraDistance: Float, cameraHeight: Float,
                target: SIMD3<Float>, orbit: Float) throws -> CGImage {
        let renderer = try RealityRenderer()

        let content = Entity()
        content.addChild(entity)
        renderer.entities.append(content)

        let sun = DirectionalLight()
        sun.light.intensity = 6000
        sun.look(at: [0, 0, 0], from: [2, 4, 3], relativeTo: nil)
        renderer.entities.append(sun)

        let fill = DirectionalLight()
        fill.light.intensity = 2500
        fill.look(at: [0, 0, 0], from: [-3, 2, 2], relativeTo: nil)
        renderer.entities.append(fill)

        if let ibl = try? EnvironmentResource(equirectangular: OffscreenRenderer.gradientImage()) {
            var iblc = ImageBasedLightComponent(source: .single(ibl), intensityExponent: 1.0)
            iblc.inheritsRotation = true
            let iblEntity = Entity()
            iblEntity.components.set(iblc)
            renderer.entities.append(iblEntity)
        }

        let cam = PerspectiveCamera()
        cam.camera.fieldOfViewInDegrees = 40
        let camPos = target + SIMD3<Float>(sin(orbit) * cameraDistance, cameraHeight, cos(orbit) * cameraDistance)
        cam.position = camPos
        cam.look(at: target, from: camPos, relativeTo: nil)
        renderer.activeCamera = cam
        renderer.entities.append(cam)

        let colorTex = makeTexture()
        let cmd = queue.makeCommandBuffer()!
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: colorTex))
        try renderer.updateAndRender(
            deltaTime: 0.1, cameraOutput: output,
            whenScheduled: { _ in }, onComplete: { _ in },
            actionsBeforeRender: [], actionsAfterRender: [])
        cmd.commit()
        cmd.waitUntilCompleted()
        return try OffscreenRenderer.cgImage(from: colorTex)
    }

    static func gradientImage() throws -> CGImage {
        let w = 512, h = 256
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [CGColor(red: 0.10, green: 0.11, blue: 0.16, alpha: 1),
                      CGColor(red: 0.55, green: 0.60, blue: 0.72, alpha: 1)] as CFArray
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

@MainActor
func run() throws {
    let outDir = URL(fileURLWithPath: "output/virtualjoystick", isDirectory: true)
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    let renderer = try OffscreenRenderer(size: 900)

    // Warm-up: the first RealityRenderer frame comes back empty, so render a
    // throwaway before capturing the real shots.
    let warm = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial()])
    _ = try renderer.render(entity: warm, cameraDistance: 0.3, cameraHeight: 0.1, target: [0, 0, 0], orbit: 0)

    let gamepad = Gamepad3DEntity.make(at: [0, 0, 0])
    let g1 = try renderer.render(entity: gamepad, cameraDistance: 0.62, cameraHeight: 0.5,
                                 target: [0, 0, 0.02], orbit: 0.25)
    try writePNG(g1, to: outDir.appendingPathComponent("gamepad3d.png"))
    print("wrote gamepad3d.png")

    let gamepad2 = Gamepad3DEntity.make(at: [0, 0, 0])
    let g2 = try renderer.render(entity: gamepad2, cameraDistance: 0.66, cameraHeight: 0.32,
                                 target: [0, 0.02, 0.02], orbit: 0.7)
    try writePNG(g2, to: outDir.appendingPathComponent("gamepad3d-angle.png"))
    print("wrote gamepad3d-angle.png")

    let pillar = GamepadPillarEntity.make(at: [0, 0.9, 0])
    let p1 = try renderer.render(entity: pillar, cameraDistance: 2.1, cameraHeight: 1.1,
                                 target: [0, 0.5, 0], orbit: 0.4)
    try writePNG(p1, to: outDir.appendingPathComponent("gamepad-pillar.png"))
    print("wrote gamepad-pillar.png")

    let holo = PillarHologramEntity.make()
    holo.isEnabled = true
    let h1 = try renderer.render(entity: holo, cameraDistance: 0.34, cameraHeight: 0.16,
                                 target: [0, 0, 0], orbit: 0.3)
    try writePNG(h1, to: outDir.appendingPathComponent("pillar-hologram.png"))
    print("wrote pillar-hologram.png")
}

try run()
