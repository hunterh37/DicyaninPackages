import Foundation
import RealityKit
import Metal
import MetalKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import simd
import DicyaninSpatialUI

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
            pixelFormat: .rgba8Unorm,
            width: size,
            height: size,
            mipmapped: false
        )
        desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        desc.storageMode = .shared
        return device.makeTexture(descriptor: desc)!
    }

    func render(entity: Entity, cameraDistance: Float, cameraHeight: Float, target: SIMD3<Float>) throws -> CGImage {
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

        let ibl = try? EnvironmentResource(equirectangular: OffscreenRenderer.gradientImage())
        if let ibl {
            var iblc = ImageBasedLightComponent(source: .single(ibl), intensityExponent: 1.0)
            iblc.inheritsRotation = true
            let iblEntity = Entity()
            iblEntity.components.set(iblc)
            renderer.entities.append(iblEntity)
        }

        let cam = PerspectiveCamera()
        cam.camera.fieldOfViewInDegrees = 40
        let camPos = target + SIMD3<Float>(0, cameraHeight, cameraDistance)
        cam.position = camPos
        cam.look(at: target, from: camPos, relativeTo: nil)
        renderer.activeCamera = cam
        renderer.entities.append(cam)

        let colorTex = makeTexture()

        let cmd = queue.makeCommandBuffer()!
        let output = try RealityRenderer.CameraOutput(
            .singleProjection(colorTexture: colorTex)
        )
        try renderer.updateAndRender(
            deltaTime: 0.1,
            cameraOutput: output,
            whenScheduled: { _ in },
            onComplete: { _ in },
            actionsBeforeRender: [],
            actionsAfterRender: []
        )
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
func makeComponents() throws -> [(String, Entity, Float, Float)] {
    var out: [(String, Entity, Float, Float)] = []

    let panel = try SpatialUIFactory.makeCurvedPanel(material: SimpleMaterial(color: .gray, roughness: 0.5, isMetallic: false))
    out.append(("curved-panel", panel, 1.2, 0.15))

    let button = SpatialUIFactory.makeButton(identifier: "demo")
    out.append(("button", button, 0.5, 0.06))

    let toggle = SpatialUIFactory.makeButton(identifier: "toggle", isToggle: true)
    var comp = toggle.components[SpatialButtonComponent.self]!
    comp.isOn = true
    toggle.components.set(comp)
    toggle.findEntity(named: SpatialUIFactory.tooltipName)?.isEnabled = true
    out.append(("toggle-button", toggle, 0.5, 0.06))

    let slider = SpatialUIFactory.makeSlider(identifier: "volume", value: 0.65)
    out.append(("slider", slider, 0.4, 0.08))

    let items = ["copy", "paste", "cut", "undo", "redo"].map { RadialMenuItem(identifier: $0, title: $0) }
    let radial = SpatialUIFactory.makeRadialMenu(items: items)
    for child in radial.children { child.isEnabled = true }
    out.append(("radial-menu", radial, 0.45, 0.08))

    let tooltipHost = SpatialUIFactory.makeButton(identifier: "info")
    SpatialUIFactory.attachTooltip(text: "Tooltip", to: tooltipHost)
    if let tip = tooltipHost.findEntity(named: SpatialUIFactory.tooltipName) {
        tip.isEnabled = true
        if var model = tip.components[ModelComponent.self] {
            model.materials = [SimpleMaterial(color: .black, isMetallic: false)]
            tip.components.set(model)
        }
    }
    out.append(("tooltip", tooltipHost, 0.5, 0.08))

    return out
}

@MainActor
func run() throws {
    let outDir = URL(fileURLWithPath: "output", isDirectory: true)
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    let renderer = try OffscreenRenderer(size: 900)
    _ = try? renderer.render(entity: Entity(), cameraDistance: 1, cameraHeight: 0, target: .zero)

    for (name, entity, distance, height) in try makeComponents() {
        let img = try renderer.render(entity: entity, cameraDistance: distance, cameraHeight: height,
                                      target: [0, 0, 0])
        let url = outDir.appendingPathComponent("spatialui-\(name).png")
        try writePNG(img, to: url)
        print("wrote \(url.lastPathComponent)")
    }
}

try run()
