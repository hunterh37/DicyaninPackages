import RealityKit
import simd
#if canImport(UIKit)
import UIKit
public typealias SpatialUIColor = UIColor
#else
import AppKit
public typealias SpatialUIColor = NSColor
#endif

/// Entity factories for all spatial UI elements. Every entity is a plain RealityKit Entity
/// composed from components; behavior lives in the systems.
@MainActor
public enum SpatialUIFactory {

    public static let radialItemPrefix = "dicyanin.radial.item."
    public static let tooltipName = "dicyanin.tooltip"
    public static let sliderThumbName = "dicyanin.slider.thumb"
    public static let sliderTrackName = "dicyanin.slider.track"

    // MARK: Materials

    public static func panelMaterial(color: SpatialUIColor = SpatialUIColor(white: 0.12, alpha: 0.92)) -> SimpleMaterial {
        SimpleMaterial(color: color, roughness: 0.6, isMetallic: false)
    }

    public static func accentMaterial(color: SpatialUIColor = .systemBlue) -> SimpleMaterial {
        SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)
    }

    // MARK: Curved Panel

    public static func makeCurvedPanel(width: Float = 0.6,
                                       height: Float = 0.35,
                                       curveRadius: Float = 1.0,
                                       segments: Int = 24,
                                       material: RealityKit.Material? = nil) throws -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.curvedPanel"
        let mesh = try CurvedPanelMesh.mesh(width: width, height: height, curveRadius: curveRadius, segments: segments)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material ?? panelMaterial()]))
        entity.components.set(CurvedPanelComponent(width: width, height: height, curveRadius: curveRadius, cornerSegments: segments))
        return entity
    }

    // MARK: Button

    public static func makeButton(identifier: String,
                                  size: SIMD2<Float> = [0.08, 0.04],
                                  depth: Float = 0.01,
                                  isToggle: Bool = false,
                                  input: SpatialInputOptions = .all,
                                  tooltip: String? = nil,
                                  action: ((Entity) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.button.\(identifier)"
        let mesh = MeshResource.generateBox(width: size.x, height: size.y, depth: depth, cornerRadius: depth / 2)
        entity.components.set(ModelComponent(mesh: mesh, materials: [accentMaterial()]))
        entity.components.set(SpatialButtonComponent(identifier: identifier, isToggle: isToggle, action: action))
        entity.components.set(HoverStateComponent())
        entity.components.set(SpatialInputTargetComponent(options: input))
        entity.components.set(CollisionComponent(shapes: [.generateBox(width: size.x, height: size.y, depth: depth)]))
        #if os(visionOS)
        entity.components.set(InputTargetComponent())
        entity.components.set(HoverEffectComponent())
        #endif
        if let tooltip {
            attachTooltip(text: tooltip, to: entity, elementHeight: size.y)
        }
        return entity
    }

    // MARK: Slider

    public static func makeSlider(identifier: String,
                                  value: Float = 0.5,
                                  range: ClosedRange<Float> = 0...1,
                                  step: Float? = nil,
                                  trackLength: Float = 0.2,
                                  input: SpatialInputOptions = .all,
                                  onChanged: ((Float) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.slider.\(identifier)"
        let slider = SpatialSliderComponent(identifier: identifier, value: value, range: range,
                                            step: step, trackLength: trackLength, onChanged: onChanged)

        let track = Entity()
        track.name = sliderTrackName
        let trackMesh = MeshResource.generateBox(width: trackLength, height: 0.008, depth: 0.008, cornerRadius: 0.004)
        track.components.set(ModelComponent(mesh: trackMesh, materials: [panelMaterial()]))
        entity.addChild(track)

        let thumb = Entity()
        thumb.name = sliderThumbName
        let thumbMesh = MeshResource.generateSphere(radius: 0.015)
        thumb.components.set(ModelComponent(mesh: thumbMesh, materials: [accentMaterial()]))
        thumb.components.set(HoverStateComponent())
        thumb.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.02)]))
        #if os(visionOS)
        thumb.components.set(InputTargetComponent())
        thumb.components.set(HoverEffectComponent())
        #endif
        thumb.position = [slider.thumbOffsetX, 0, 0]
        entity.addChild(thumb)

        entity.components.set(slider)
        entity.components.set(SpatialInputTargetComponent(options: input))
        return entity
    }

    /// Applies a slider value change: updates the component, moves the thumb, fires the callback.
    public static func setSliderValue(_ entity: Entity, localX: Float) {
        guard var slider = entity.components[SpatialSliderComponent.self] else { return }
        let old = slider.value
        slider.setValue(fromLocalX: localX)
        entity.components.set(slider)
        entity.findEntity(named: sliderThumbName)?.position = [slider.thumbOffsetX, 0, 0]
        if slider.value != old {
            slider.onChanged?(slider.value)
        }
    }

    // MARK: Radial Menu

    public static func makeRadialMenu(items: [RadialMenuItem],
                                      radius: Float = 0.12,
                                      startAngle: Float = .pi / 2,
                                      input: SpatialInputOptions = .all,
                                      onSelect: ((RadialMenuItem) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.radialMenu"
        entity.components.set(RadialMenuComponent(items: items, radius: radius,
                                                  startAngle: startAngle, onSelect: onSelect))
        entity.components.set(SpatialInputTargetComponent(options: input))

        for (index, item) in items.enumerated() {
            let child = Entity()
            child.name = radialItemPrefix + item.identifier
            let mesh = MeshResource.generateSphere(radius: 0.02)
            child.components.set(ModelComponent(mesh: mesh, materials: [accentMaterial()]))
            child.components.set(HoverStateComponent())
            child.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.025)]))
            #if os(visionOS)
            child.components.set(InputTargetComponent())
            child.components.set(HoverEffectComponent())
            #endif
            child.position = SpatialUIMath.radialPosition(index: index, count: items.count,
                                                          radius: radius, startAngle: startAngle)
            child.isEnabled = false
            entity.addChild(child)
        }
        return entity
    }

    /// Selects the radial item nearest to a point in the menu's local space and fires onSelect.
    public static func selectRadialItem(_ entity: Entity, localPoint: SIMD3<Float>, deadZoneRadius: Float = 0.03) {
        guard var menu = entity.components[RadialMenuComponent.self] else { return }
        let hit = SpatialUIMath.radialHitIndex(localPoint: localPoint, count: menu.items.count,
                                               startAngle: menu.startAngle, deadZoneRadius: deadZoneRadius)
        menu.selectedIndex = hit
        entity.components.set(menu)
        if let hit {
            menu.onSelect?(menu.items[hit])
        }
    }

    // MARK: Tooltip

    public static func attachTooltip(text: String, to entity: Entity, elementHeight: Float = 0.04) {
        entity.components.set(TooltipComponent(text: text, offset: [0, elementHeight / 2 + 0.04, 0]))
        if entity.components[HoverStateComponent.self] == nil {
            entity.components.set(HoverStateComponent())
        }
        let tip = Entity()
        tip.name = tooltipName
        let mesh = MeshResource.generateText(text,
                                             extrusionDepth: 0.001,
                                             font: .systemFont(ofSize: 0.014),
                                             containerFrame: .zero,
                                             alignment: .center,
                                             lineBreakMode: .byWordWrapping)
        tip.components.set(ModelComponent(mesh: mesh, materials: [SimpleMaterial(color: .white, isMetallic: false)]))
        let bounds = mesh.bounds
        tip.position = [0, elementHeight / 2 + 0.04, 0] - [bounds.center.x, 0, 0]
        tip.components.set(BillboardComponent())
        tip.isEnabled = false
        entity.addChild(tip)
    }
}
