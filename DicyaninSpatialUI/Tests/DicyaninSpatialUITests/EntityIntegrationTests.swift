import XCTest
import RealityKit
import simd
@testable import DicyaninSpatialUI

@MainActor
final class EntityIntegrationTests: XCTestCase {

    override func setUp() async throws {
        DicyaninSpatialUI.register()
    }

    // MARK: Factory: Button

    func testMakeButtonComposition() {
        let button = SpatialUIFactory.makeButton(identifier: "play")
        XCTAssertEqual(button.name, "dicyanin.button.play")
        XCTAssertNotNil(button.components[SpatialButtonComponent.self])
        XCTAssertNotNil(button.components[HoverStateComponent.self])
        XCTAssertNotNil(button.components[SpatialInputTargetComponent.self])
        XCTAssertNotNil(button.components[CollisionComponent.self])
        #if os(visionOS)
        XCTAssertNotNil(button.components[InputTargetComponent.self])
        #endif
        XCTAssertNotNil(button.components[ModelComponent.self])
    }

    func testMakeButtonWithTooltipAddsChild() {
        let button = SpatialUIFactory.makeButton(identifier: "x", tooltip: "Close")
        XCTAssertNotNil(button.components[TooltipComponent.self])
        let tip = button.findEntity(named: SpatialUIFactory.tooltipName)
        XCTAssertNotNil(tip)
        XCTAssertFalse(tip!.isEnabled)
        XCTAssertNotNil(tip!.components[DicyaninBillboardComponent.self])
    }

    func testButtonPressFiresActionViaInput() {
        var fired = false
        let button = SpatialUIFactory.makeButton(identifier: "go") { _ in fired = true }
        SpatialUIInput.press(button, source: .gazePinch)
        // System normally consumes the flag; simulate one system pass.
        var comp = button.components[SpatialButtonComponent.self]!
        XCTAssertTrue(comp.pressedThisFrame)
        comp.pressedThisFrame = false
        button.components.set(comp)
        comp.action?(button)
        XCTAssertTrue(fired)
    }

    func testButtonRespectsInputOptions() {
        let button = SpatialUIFactory.makeButton(identifier: "d", input: .directTouch)
        SpatialUIInput.press(button, source: .gazePinch)
        XCTAssertFalse(button.components[SpatialButtonComponent.self]!.pressedThisFrame)
        SpatialUIInput.press(button, source: .directTouch)
        XCTAssertTrue(button.components[SpatialButtonComponent.self]!.pressedThisFrame)
    }

    func testDisabledTargetRejectsInput() {
        let button = SpatialUIFactory.makeButton(identifier: "off")
        var target = button.components[SpatialInputTargetComponent.self]!
        target.isEnabled = false
        button.components.set(target)
        SpatialUIInput.press(button, source: .gazePinch)
        XCTAssertFalse(button.components[SpatialButtonComponent.self]!.pressedThisFrame)
    }

    func testResolveTargetWalksUpHierarchy() {
        let button = SpatialUIFactory.makeButton(identifier: "parent")
        let child = Entity()
        button.addChild(child)
        XCTAssertEqual(SpatialUIInput.resolveTarget(child), button)
    }

    // MARK: Factory: Slider

    func testMakeSliderComposition() {
        let slider = SpatialUIFactory.makeSlider(identifier: "vol", value: 0.5)
        XCTAssertNotNil(slider.components[SpatialSliderComponent.self])
        XCTAssertNotNil(slider.findEntity(named: SpatialUIFactory.sliderThumbName))
        XCTAssertNotNil(slider.findEntity(named: SpatialUIFactory.sliderTrackName))
    }

    func testSliderThumbPositionMatchesValue() {
        let slider = SpatialUIFactory.makeSlider(identifier: "v", value: 1, range: 0...1, trackLength: 0.2)
        let thumb = slider.findEntity(named: SpatialUIFactory.sliderThumbName)!
        XCTAssertEqual(thumb.position.x, 0.1, accuracy: 1e-5)
    }

    func testSetSliderValueMovesThumbAndFiresCallback() {
        var reported: Float = -1
        let slider = SpatialUIFactory.makeSlider(identifier: "v", value: 0, range: 0...10,
                                                 trackLength: 0.2) { reported = $0 }
        SpatialUIFactory.setSliderValue(slider, localX: 0.1)
        XCTAssertEqual(slider.components[SpatialSliderComponent.self]!.value, 10, accuracy: 1e-5)
        XCTAssertEqual(reported, 10, accuracy: 1e-5)
        let thumb = slider.findEntity(named: SpatialUIFactory.sliderThumbName)!
        XCTAssertEqual(thumb.position.x, 0.1, accuracy: 1e-5)
    }

    func testSliderCallbackNotFiredWhenValueUnchanged() {
        var calls = 0
        let slider = SpatialUIFactory.makeSlider(identifier: "v", value: 1, range: 0...1) { _ in calls += 1 }
        SpatialUIFactory.setSliderValue(slider, localX: 5) // already at max
        XCTAssertEqual(calls, 0)
    }

    func testSliderDragLifecycle() {
        let slider = SpatialUIFactory.makeSlider(identifier: "v", value: 0)
        SpatialUIInput.drag(slider, localPosition: [0.05, 0, 0], source: .gazePinch)
        XCTAssertTrue(slider.components[SpatialSliderComponent.self]!.isDragging)
        SpatialUIInput.dragEnded(slider)
        XCTAssertFalse(slider.components[SpatialSliderComponent.self]!.isDragging)
    }

    // MARK: Factory: Radial Menu

    func testMakeRadialMenuChildrenHiddenUntilOpen() {
        let items = (0..<4).map { RadialMenuItem(identifier: "i\($0)", title: "\($0)") }
        let menu = SpatialUIFactory.makeRadialMenu(items: items)
        let children = menu.children.filter { $0.name.hasPrefix(SpatialUIFactory.radialItemPrefix) }
        XCTAssertEqual(children.count, 4)
        XCTAssertTrue(children.allSatisfy { !$0.isEnabled })
    }

    func testRadialMenuPressTogglesOpen() {
        let items = [RadialMenuItem(identifier: "a", title: "A")]
        let menu = SpatialUIFactory.makeRadialMenu(items: items)
        SpatialUIInput.press(menu, source: .gazePinch)
        XCTAssertTrue(menu.components[RadialMenuComponent.self]!.isOpen)
        SpatialUIInput.press(menu, source: .gazePinch)
        let comp = menu.components[RadialMenuComponent.self]!
        XCTAssertFalse(comp.isOpen)
        XCTAssertNil(comp.selectedIndex)
    }

    func testRadialSelectionFiresOnSelect() {
        var selected: RadialMenuItem?
        let items = (0..<4).map { RadialMenuItem(identifier: "i\($0)", title: "\($0)") }
        let menu = SpatialUIFactory.makeRadialMenu(items: items) { selected = $0 }
        SpatialUIFactory.selectRadialItem(menu, localPoint: [0, 0.1, 0])
        XCTAssertEqual(menu.components[RadialMenuComponent.self]!.selectedIndex, 0)
        XCTAssertEqual(selected?.identifier, "i0")
    }

    func testRadialSelectionDeadZoneClearsSelection() {
        let items = (0..<4).map { RadialMenuItem(identifier: "i\($0)", title: "\($0)") }
        let menu = SpatialUIFactory.makeRadialMenu(items: items)
        SpatialUIFactory.selectRadialItem(menu, localPoint: [0, 0.1, 0])
        SpatialUIFactory.selectRadialItem(menu, localPoint: [0.001, 0.001, 0])
        XCTAssertNil(menu.components[RadialMenuComponent.self]!.selectedIndex)
    }

    // MARK: Factory: Curved Panel

    func testMakeCurvedPanel() throws {
        let panel = try SpatialUIFactory.makeCurvedPanel(width: 0.6, height: 0.35, curveRadius: 1)
        XCTAssertNotNil(panel.components[ModelComponent.self])
        XCTAssertNotNil(panel.components[CurvedPanelComponent.self])
    }

    // MARK: Direct-touch proximity

    func testProximityDrivesPhases() {
        let button = SpatialUIFactory.makeButton(identifier: "t")
        SpatialUIInput.updateProximity(button, distance: 0.5)
        XCTAssertEqual(button.components[HoverStateComponent.self]!.phase, .none)
        SpatialUIInput.updateProximity(button, distance: 0.05)
        XCTAssertEqual(button.components[HoverStateComponent.self]!.phase, .hovering)
        SpatialUIInput.updateProximity(button, distance: 0.005)
        XCTAssertEqual(button.components[HoverStateComponent.self]!.phase, .pressed)
        XCTAssertTrue(button.components[SpatialButtonComponent.self]!.pressedThisFrame)
    }

    func testProximityPressFiresOnceUntilRelease() {
        let button = SpatialUIFactory.makeButton(identifier: "once")
        SpatialUIInput.updateProximity(button, distance: 0.005)
        var comp = button.components[SpatialButtonComponent.self]!
        XCTAssertTrue(comp.pressedThisFrame)
        comp.pressedThisFrame = false
        button.components.set(comp)
        // Still touching: no re-fire.
        SpatialUIInput.updateProximity(button, distance: 0.005)
        XCTAssertFalse(button.components[SpatialButtonComponent.self]!.pressedThisFrame)
    }

    func testProximityIgnoredWhenDirectTouchDisabled() {
        let button = SpatialUIFactory.makeButton(identifier: "gaze", input: .gazePinch)
        SpatialUIInput.updateProximity(button, distance: 0.005)
        XCTAssertEqual(button.components[HoverStateComponent.self]!.phase, .none)
    }

    // MARK: Hover lifecycle

    func testHoverBeganEndedResetsTimer() {
        let button = SpatialUIFactory.makeButton(identifier: "h")
        SpatialUIInput.hoverBegan(button, source: .gazePinch)
        XCTAssertEqual(button.components[HoverStateComponent.self]!.phase, .hovering)
        SpatialUIInput.hoverEnded(button)
        let hover = button.components[HoverStateComponent.self]!
        XCTAssertEqual(hover.phase, .none)
        XCTAssertEqual(hover.timeInPhase, 0)
    }
}
