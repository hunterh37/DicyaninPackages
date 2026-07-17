import RealityKit
import simd

/// Entity factories for the control set: toggle, segmented control, progress bar, dial, stepper, dropdown.
@MainActor
public extension SpatialUIFactory {

    static let toggleKnobName = "dicyanin.toggle.knob"
    static let toggleTrackName = "dicyanin.toggle.track"
    static let segmentPrefix = "dicyanin.segment."
    static let progressFillName = "dicyanin.progress.fill"
    static let progressTrackName = "dicyanin.progress.track"
    static let dialKnobName = "dicyanin.dial.knob"
    static let dialIndicatorName = "dicyanin.dial.indicator"
    static let stepperMinusName = "dicyanin.stepper.minus"
    static let stepperPlusName = "dicyanin.stepper.plus"
    static let dropdownHeaderName = "dicyanin.dropdown.header"
    static let dropdownRowPrefix = "dicyanin.dropdown.row."

    private static func addInputTarget(_ entity: Entity, shape: ShapeResource, options: SpatialInputOptions) {
        entity.components.set(HoverStateComponent())
        entity.components.set(SpatialInputTargetComponent(options: options))
        entity.components.set(CollisionComponent(shapes: [shape]))
        #if os(visionOS)
        entity.components.set(InputTargetComponent())
        entity.components.set(HoverEffectComponent())
        #endif
    }

    // MARK: Toggle

    static func makeToggle(identifier: String,
                           isOn: Bool = false,
                           travel: Float = 0.03,
                           input: SpatialInputOptions = .all,
                           onChanged: ((Bool) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.toggle.\(identifier)"
        let toggle = SpatialToggleComponent(identifier: identifier, isOn: isOn,
                                            travel: travel, onChanged: onChanged)

        let track = Entity()
        track.name = toggleTrackName
        let trackMesh = MeshResource.generateBox(width: travel * 2, height: 0.02, depth: 0.01, cornerRadius: 0.005)
        track.components.set(ModelComponent(mesh: trackMesh, materials: [panelMaterial()]))
        entity.addChild(track)

        let knob = Entity()
        knob.name = toggleKnobName
        let knobMesh = MeshResource.generateSphere(radius: 0.012)
        knob.components.set(ModelComponent(mesh: knobMesh, materials: [accentMaterial()]))
        knob.position = [toggle.knobTargetX, 0, 0.006]
        entity.addChild(knob)

        entity.components.set(toggle)
        addInputTarget(entity,
                       shape: .generateBox(width: travel * 2 + 0.02, height: 0.03, depth: 0.02),
                       options: input)
        return entity
    }

    // MARK: Segmented Control

    static func makeSegmentedControl(identifier: String,
                                     segments: [String],
                                     selectedIndex: Int = 0,
                                     segmentSize: SIMD2<Float> = [0.06, 0.035],
                                     spacing: Float = 0.006,
                                     input: SpatialInputOptions = .all,
                                     onChanged: ((Int) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.segmentedControl.\(identifier)"
        let control = SpatialSegmentedControlComponent(identifier: identifier, segments: segments,
                                                       selectedIndex: selectedIndex,
                                                       segmentSize: segmentSize, spacing: spacing,
                                                       onChanged: onChanged)
        entity.components.set(control)
        entity.components.set(SpatialInputTargetComponent(options: input))

        for (index, _) in segments.enumerated() {
            let segment = Entity()
            segment.name = segmentPrefix + String(index)
            let mesh = MeshResource.generateBox(width: segmentSize.x, height: segmentSize.y,
                                                depth: 0.008, cornerRadius: 0.004)
            let material = index == control.selectedIndex ? accentMaterial() : panelMaterial()
            segment.components.set(ModelComponent(mesh: mesh, materials: [material]))
            segment.position = [control.segmentOffsetX(index), 0, 0]
            addInputTarget(segment,
                           shape: .generateBox(width: segmentSize.x, height: segmentSize.y, depth: 0.01),
                           options: input)
            entity.addChild(segment)
        }
        return entity
    }

    /// Applies a segment selection: updates the component, restyles segments, fires the callback.
    static func selectSegment(_ entity: Entity, index: Int) {
        guard var control = entity.components[SpatialSegmentedControlComponent.self] else { return }
        let clamped = SpatialUIMath.clampIndex(index, count: control.segments.count)
        guard clamped != control.selectedIndex else { return }
        control.selectedIndex = clamped
        entity.components.set(control)
        for child in entity.children where child.name.hasPrefix(segmentPrefix) {
            guard let i = Int(child.name.dropFirst(segmentPrefix.count)),
                  var model = child.components[ModelComponent.self] else { continue }
            model.materials = [i == clamped ? accentMaterial() : panelMaterial()]
            child.components.set(model)
        }
        control.onChanged?(clamped)
    }

    // MARK: Progress Bar

    static func makeProgressBar(identifier: String,
                                progress: Float = 0,
                                length: Float = 0.2) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.progressBar.\(identifier)"
        let bar = SpatialProgressBarComponent(identifier: identifier, progress: progress, length: length)

        let track = Entity()
        track.name = progressTrackName
        let trackMesh = MeshResource.generateBox(width: length, height: 0.012, depth: 0.008, cornerRadius: 0.004)
        track.components.set(ModelComponent(mesh: trackMesh, materials: [panelMaterial()]))
        entity.addChild(track)

        let fill = Entity()
        fill.name = progressFillName
        let fillMesh = MeshResource.generateBox(width: length, height: 0.012, depth: 0.008, cornerRadius: 0.004)
        fill.components.set(ModelComponent(mesh: fillMesh, materials: [accentMaterial()]))
        fill.scale = [max(bar.displayedProgress, 0.001), 1, 1]
        fill.position = [(bar.displayedProgress - 1) * length / 2, 0, 0.002]
        entity.addChild(fill)

        entity.components.set(bar)
        return entity
    }

    /// Sets the target progress; ProgressBarSystem animates the fill toward it.
    static func setProgress(_ entity: Entity, _ progress: Float) {
        guard var bar = entity.components[SpatialProgressBarComponent.self] else { return }
        bar.progress = SpatialUIMath.clamp01(progress)
        entity.components.set(bar)
    }

    // MARK: Dial

    static func makeDial(identifier: String,
                         value: Float = 0,
                         range: ClosedRange<Float> = 0...1,
                         step: Float? = nil,
                         radius: Float = 0.035,
                         sweep: Float = .pi * 1.5,
                         input: SpatialInputOptions = .all,
                         onChanged: ((Float) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.dial.\(identifier)"
        let dial = SpatialDialComponent(identifier: identifier, value: value, range: range,
                                        step: step, sweep: sweep, onChanged: onChanged)

        let knob = Entity()
        knob.name = dialKnobName
        let knobMesh = MeshResource.generateCylinder(height: 0.015, radius: radius)
        knob.components.set(ModelComponent(mesh: knobMesh, materials: [panelMaterial()]))
        knob.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

        let indicator = Entity()
        indicator.name = dialIndicatorName
        let indicatorMesh = MeshResource.generateBox(width: 0.006, height: 0.005, depth: radius * 0.7)
        indicator.components.set(ModelComponent(mesh: indicatorMesh, materials: [accentMaterial()]))
        indicator.position = [0, 0.008, -radius * 0.55]
        knob.addChild(indicator)

        entity.addChild(knob)
        entity.components.set(dial)
        addInputTarget(entity,
                       shape: .generateBox(width: radius * 2, height: radius * 2, depth: 0.02),
                       options: input)
        DialSystem.applyKnobRotation(entity, dial: dial)
        return entity
    }

    /// Applies a dial value change from a local-space point: updates the component, rotates the knob, fires the callback.
    static func setDialValue(_ entity: Entity, localPoint: SIMD3<Float>) {
        guard var dial = entity.components[SpatialDialComponent.self] else { return }
        let old = dial.value
        dial.setValue(fromLocalPoint: localPoint)
        entity.components.set(dial)
        DialSystem.applyKnobRotation(entity, dial: dial)
        if dial.value != old {
            dial.onChanged?(dial.value)
        }
    }

    // MARK: Stepper

    static func makeStepper(identifier: String,
                            value: Float = 0,
                            range: ClosedRange<Float> = 0...10,
                            step: Float = 1,
                            buttonSize: Float = 0.03,
                            gap: Float = 0.05,
                            input: SpatialInputOptions = .all,
                            onChanged: ((Float) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.stepper.\(identifier)"
        entity.components.set(SpatialStepperComponent(identifier: identifier, value: value,
                                                      range: range, step: step, onChanged: onChanged))
        entity.components.set(SpatialInputTargetComponent(options: input))

        for (name, x) in [(stepperMinusName, -gap), (stepperPlusName, gap)] {
            let button = Entity()
            button.name = name
            let mesh = MeshResource.generateBox(width: buttonSize, height: buttonSize,
                                                depth: 0.01, cornerRadius: 0.005)
            button.components.set(ModelComponent(mesh: mesh, materials: [accentMaterial()]))
            button.position = [x, 0, 0]
            addInputTarget(button,
                           shape: .generateBox(width: buttonSize, height: buttonSize, depth: 0.015),
                           options: input)
            entity.addChild(button)
        }
        return entity
    }

    /// Applies a stepper press: updates the value and fires the callback. Direction is -1 or +1.
    static func stepValue(_ entity: Entity, direction: Int) {
        guard var stepper = entity.components[SpatialStepperComponent.self] else { return }
        let changed = stepper.apply(direction: direction)
        entity.components.set(stepper)
        if changed {
            stepper.onChanged?(stepper.value)
        }
    }

    // MARK: Dropdown

    static func makeDropdown(identifier: String,
                             items: [String],
                             selectedIndex: Int = 0,
                             rowSize: SIMD2<Float> = [0.12, 0.03],
                             input: SpatialInputOptions = .all,
                             onSelect: ((Int) -> Void)? = nil) -> Entity {
        let entity = Entity()
        entity.name = "dicyanin.dropdown.\(identifier)"
        let dropdown = SpatialDropdownComponent(identifier: identifier, items: items,
                                                selectedIndex: selectedIndex,
                                                rowSize: rowSize, onSelect: onSelect)
        entity.components.set(dropdown)
        entity.components.set(SpatialInputTargetComponent(options: input))

        let header = Entity()
        header.name = dropdownHeaderName
        let headerMesh = MeshResource.generateBox(width: rowSize.x, height: rowSize.y,
                                                  depth: 0.008, cornerRadius: 0.004)
        header.components.set(ModelComponent(mesh: headerMesh, materials: [accentMaterial()]))
        addInputTarget(header,
                       shape: .generateBox(width: rowSize.x, height: rowSize.y, depth: 0.01),
                       options: input)
        entity.addChild(header)

        for (index, _) in items.enumerated() {
            let row = Entity()
            row.name = dropdownRowPrefix + String(index)
            let mesh = MeshResource.generateBox(width: rowSize.x, height: rowSize.y,
                                                depth: 0.006, cornerRadius: 0.003)
            row.components.set(ModelComponent(mesh: mesh, materials: [panelMaterial()]))
            row.position = [0, dropdown.rowOffsetY(index), 0.002]
            addInputTarget(row,
                           shape: .generateBox(width: rowSize.x, height: rowSize.y, depth: 0.01),
                           options: input)
            row.isEnabled = false
            entity.addChild(row)
        }
        return entity
    }

    /// Applies a dropdown row selection: updates the component, closes the menu, fires the callback.
    static func selectDropdownItem(_ entity: Entity, index: Int) {
        guard var dropdown = entity.components[SpatialDropdownComponent.self] else { return }
        dropdown.selectedIndex = SpatialUIMath.clampIndex(index, count: dropdown.items.count)
        dropdown.isOpen = false
        entity.components.set(dropdown)
        dropdown.onSelect?(dropdown.selectedIndex)
    }
}
