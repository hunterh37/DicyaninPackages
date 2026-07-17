import XCTest
import simd
@testable import DicyaninSpatialUI

final class ComponentTests: XCTestCase {

    // MARK: HoverStateComponent

    func testHoverDefaults() {
        let hover = HoverStateComponent()
        XCTAssertEqual(hover.phase, .none)
        XCTAssertEqual(hover.proximity, 0)
        XCTAssertEqual(hover.timeInPhase, 0)
        XCTAssertEqual(hover.targetScale, 1)
    }

    func testHoverTargetScalePerPhase() {
        var hover = HoverStateComponent(hoverScale: 1.1, pressScale: 0.9)
        hover.phase = .hovering
        XCTAssertEqual(hover.targetScale, 1.1)
        hover.phase = .pressed
        XCTAssertEqual(hover.targetScale, 0.9)
        hover.phase = .none
        XCTAssertEqual(hover.targetScale, 1)
    }

    // MARK: SpatialInputOptions

    func testInputOptionsAll() {
        XCTAssertTrue(SpatialInputOptions.all.contains(.gazePinch))
        XCTAssertTrue(SpatialInputOptions.all.contains(.directTouch))
    }

    func testInputOptionsExclusive() {
        let gazeOnly: SpatialInputOptions = .gazePinch
        XCTAssertTrue(gazeOnly.contains(.gazePinch))
        XCTAssertFalse(gazeOnly.contains(.directTouch))
    }

    // MARK: SpatialButtonComponent

    func testButtonDefaults() {
        let button = SpatialButtonComponent(identifier: "b")
        XCTAssertEqual(button.identifier, "b")
        XCTAssertFalse(button.isToggle)
        XCTAssertFalse(button.isOn)
        XCTAssertFalse(button.pressedThisFrame)
    }

    // MARK: SpatialSliderComponent

    func testSliderClampsInitialValue() {
        let slider = SpatialSliderComponent(value: 5, range: 0...1)
        XCTAssertEqual(slider.value, 1)
    }

    func testSliderSnapsInitialValueToStep() {
        let slider = SpatialSliderComponent(value: 0.3, range: 0...1, step: 0.25)
        XCTAssertEqual(slider.value, 0.25, accuracy: 1e-6)
    }

    func testSliderNormalizedValue() {
        let slider = SpatialSliderComponent(value: 25, range: 0...100)
        XCTAssertEqual(slider.normalizedValue, 0.25, accuracy: 1e-6)
    }

    func testSliderThumbOffsetCenteredAtMid() {
        let slider = SpatialSliderComponent(value: 0.5, range: 0...1, trackLength: 0.2)
        XCTAssertEqual(slider.thumbOffsetX, 0, accuracy: 1e-6)
    }

    func testSliderThumbOffsetExtremes() {
        let lo = SpatialSliderComponent(value: 0, range: 0...1, trackLength: 0.2)
        let hi = SpatialSliderComponent(value: 1, range: 0...1, trackLength: 0.2)
        XCTAssertEqual(lo.thumbOffsetX, -0.1, accuracy: 1e-6)
        XCTAssertEqual(hi.thumbOffsetX, 0.1, accuracy: 1e-6)
    }

    func testSliderSetValueFromLocalX() {
        var slider = SpatialSliderComponent(value: 0, range: 0...10, trackLength: 0.2)
        slider.setValue(fromLocalX: 0)
        XCTAssertEqual(slider.value, 5, accuracy: 1e-5)
        slider.setValue(fromLocalX: 0.1)
        XCTAssertEqual(slider.value, 10, accuracy: 1e-5)
        slider.setValue(fromLocalX: -0.1)
        XCTAssertEqual(slider.value, 0, accuracy: 1e-5)
    }

    func testSliderSetValueClampsBeyondTrack() {
        var slider = SpatialSliderComponent(value: 0, range: 0...1, trackLength: 0.2)
        slider.setValue(fromLocalX: 5)
        XCTAssertEqual(slider.value, 1)
        slider.setValue(fromLocalX: -5)
        XCTAssertEqual(slider.value, 0)
    }

    func testSliderSetValueRespectsStep() {
        var slider = SpatialSliderComponent(value: 0, range: 0...1, step: 0.5, trackLength: 0.2)
        slider.setValue(fromLocalX: 0.04) // t = 0.7 -> snaps to 0.5
        XCTAssertEqual(slider.value, 0.5, accuracy: 1e-6)
    }

    // MARK: RadialMenuComponent

    func testRadialMenuDefaults() {
        let items = [RadialMenuItem(identifier: "a", title: "A"),
                     RadialMenuItem(identifier: "b", title: "B")]
        let menu = RadialMenuComponent(items: items)
        XCTAssertFalse(menu.isOpen)
        XCTAssertNil(menu.selectedIndex)
        XCTAssertEqual(menu.items.count, 2)
        XCTAssertEqual(menu.startAngle, .pi / 2)
    }

    // MARK: TooltipComponent

    func testTooltipDefaults() {
        let tip = TooltipComponent(text: "hi")
        XCTAssertEqual(tip.text, "hi")
        XCTAssertFalse(tip.isVisible)
        XCTAssertEqual(tip.hoverTime, 0)
        XCTAssertGreaterThan(tip.delay, 0)
    }

    // MARK: CurvedPanelComponent

    func testCurvedPanelArcAngle() {
        let panel = CurvedPanelComponent(width: 1, height: 0.5, curveRadius: 1)
        XCTAssertEqual(panel.arcAngle, 1, accuracy: 1e-6)
    }

    func testCurvedPanelClampsDegenerateInputs() {
        let panel = CurvedPanelComponent(width: 1, height: 0.5, curveRadius: 0, cornerSegments: 0)
        XCTAssertGreaterThan(panel.curveRadius, 0)
        XCTAssertGreaterThanOrEqual(panel.cornerSegments, 2)
    }
}
