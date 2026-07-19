# DicyaninPackages

A collection of reusable visionOS Swift packages.

## Packages

| Package | Description |
|---------|-------------|
| [DicyaninAssetPreloader](https://github.com/hunterh37/DicyaninAssetPreloader) | Asset preloading utilities |
| [DicyaninDeviceController](https://github.com/hunterh37/DicyaninDeviceController) | Device controller input |
| [DicyaninEntityQueries](https://github.com/hunterh37/DicyaninEntityQueries) | Entity query system |
| [DicyaninGamecenterWrapper](https://github.com/hunterh37/DicyaninGamecenterWrapper) | Game Center integration wrapper |
| [DicyaninGestureTipGhostHands](https://github.com/hunterh37/DicyaninGestureTipGhostHands) | Ghost hand gesture tips |
| [DicyaninGrabbableObject](https://github.com/hunterh37/DicyaninGrabbableObject) | Grabbable object interactions |
| [DicyaninHandGesture](https://github.com/hunterh37/DicyaninHandGesture) | Hand gesture recording, recognition, and playback |
| [DicyaninHandMenu](https://github.com/hunterh37/DicyaninHandMenu) | Hand-anchored menu UI |
| [DicyaninHomeDioramaScene](https://github.com/hunterh37/DicyaninHomeDioramaScene) | Home diorama scene |
| [DicyaninHUDAnchoredView](https://github.com/hunterh37/DicyaninHUDAnchoredView) | Head-anchored HUD for RealityView attachments |
| [DicyaninHumanoidMesh](https://github.com/hunterh37/DicyaninHumanoidMesh) | Humanoid mesh and poses |
| [DicyaninLabsMoCapRecording](https://github.com/hunterh37/DicyaninLabsMoCapRecording) | Motion capture recording |
| [DicyaninMapNavigation](https://github.com/hunterh37/DicyaninMapNavigation) | Map navigation |
| [DicyaninMetaballs](https://github.com/hunterh37/DicyaninMetaballs) | Metaball rendering effects |
| [DicyaninMockHandTracking](https://github.com/hunterh37/DicyaninMockHandTracking) | Mock hand tracking for testing |
| [DicyaninRoomFX](https://github.com/hunterh37/DicyaninRoomFX) | Room-scale visual effects |
| [DicyaninSceneMovement](https://github.com/hunterh37/DicyaninSceneMovement) | Scene movement utilities |
| [DicyaninSceneReconstruction](https://github.com/hunterh37/DicyaninSceneReconstruction) | Scene reconstruction utilities |
| [DicyaninSimulatorInput](https://github.com/hunterh37/DicyaninSimulatorInput) | Simulator input support |
| [DicyaninSpatialUI](https://github.com/hunterh37/DicyaninSpatialUI) | Spatial UI components |
| [DicyaninSplash](https://github.com/hunterh37/DicyaninSplash) | Splash screen |
| [DicyaninTextFX](https://github.com/hunterh37/DicyaninTextFX) | Text visual effects |
| [DicyaninToonShader](https://github.com/hunterh37/DicyaninToonShader) | Toon shading |
| [DicyaninVFXBudget](https://github.com/hunterh37/DicyaninVFXBudget) | VFX budget management |
| [DicyaninVirtualJoystick](https://github.com/hunterh37/DicyaninVirtualJoystick) | Virtual joystick input |
| [DicyaninWatchLink](https://github.com/hunterh37/DicyaninWatchLink) | Apple Watch connectivity |

## Component Gallery

Screenshots below are produced by the [`RenderGallery`](./RenderGallery) tool. Each
macOS-buildable spatial component is rendered offscreen with RealityKit via
`RealityRenderer` and written to PNG (`swift run <Package>Gallery`). Packages whose
visuals are visionOS-only (ARKit hand tracking, scene reconstruction) expose a
cross-platform preview entity that mirrors their real geometry. Pure logic and
system-integration packages (networking, Game Center) are shown as schematic cards.

### DicyaninAssetPreloader

![Asset Preloader](./docs/screenshots/assetpreloader.png)

### DicyaninDeviceController

![Controllable scene](./docs/screenshots/devicecontroller-scene.png)

### DicyaninEntityQueries

Query matches highlighted (green) against non-matching entities (gray).

![Entity Queries](./docs/screenshots/entityqueries-highlight.png)

### DicyaninGamecenterWrapper

![Game Center Wrapper](./docs/screenshots/gamecenter.png)

### DicyaninGestureTipGhostHands

| Twist | Pinch |
|-------|-------|
| ![Twist](./docs/screenshots/ghosthand-twist.png) | ![Pinch](./docs/screenshots/ghosthand-pinch.png) |

### DicyaninGrabbableObject

| Grabbable | Debug overlay |
|-----------|---------------|
| ![Grabbable cube](./docs/screenshots/grabbable-cube.png) | ![Debug overlay](./docs/screenshots/grabbable-debug.png) |

### DicyaninHandGesture

![Hand Gesture](./docs/screenshots/handgesture.png)

### DicyaninHandMenu

![Hand Menu](./docs/screenshots/handmenu-orb.png)

### DicyaninHomeDioramaScene

| Summer | Autumn | Winter |
|--------|--------|--------|
| ![Summer](./docs/screenshots/diorama-summer.png) | ![Autumn](./docs/screenshots/diorama-autumn.png) | ![Winter](./docs/screenshots/diorama-winter.png) |

### DicyaninHUDAnchoredView

![HUD Anchored View](./docs/screenshots/hudanchoredview.png)

### DicyaninHumanoidMesh

| A-Pose | T-Pose | Sitting |
|--------|--------|---------|
| ![A-Pose](./docs/screenshots/humanoid-a-pose.png) | ![T-Pose](./docs/screenshots/humanoid-t-pose.png) | ![Sitting](./docs/screenshots/humanoid-sitting.png) |

| Yoga Tree | Dabbing | Big Wave |
|-----------|---------|----------|
| ![Yoga Tree](./docs/screenshots/humanoid-yoga-tree.png) | ![Dabbing](./docs/screenshots/humanoid-dabbing.png) | ![Big Wave](./docs/screenshots/humanoid-big-wave.png) |

### DicyaninLabsMoCapRecording

![MoCap skeleton](./docs/screenshots/mocap-skeleton.png)

### DicyaninMapNavigation

| Top | Angle |
|-----|-------|
| ![Route top](./docs/screenshots/route-top.png) | ![Route angle](./docs/screenshots/route-angle.png) |

### DicyaninMetaballs

| Two-Ball Merge | Cluster | Carved Hole |
|----------------|---------|-------------|
| ![Two-Ball Merge](./docs/screenshots/metaball-two-ball-merge.png) | ![Cluster](./docs/screenshots/metaball-cluster.png) | ![Carved Hole](./docs/screenshots/metaball-carved-hole.png) |

| Lava Lamp | Vortex | DNA Helix |
|-----------|--------|-----------|
| ![Lava Lamp](./docs/screenshots/metaball-preset-lavaLamp.png) | ![Vortex](./docs/screenshots/metaball-preset-vortex.png) | ![DNA Helix](./docs/screenshots/metaball-preset-dnaHelix.png) |

### DicyaninMockHandTracking

Left hand open, right hand pinched.

![Mock hands](./docs/screenshots/mockhands.png)

### DicyaninRoomFX

Portal reveal effect (jagged-rimmed portal disc).

![Portal reveal](./docs/screenshots/roomfx-portal.png)

### DicyaninSceneMovement

| Walk Orb | Reticle | Laser |
|----------|---------|-------|
| ![Walk Orb](./docs/screenshots/movement-walk-orb.png) | ![Reticle](./docs/screenshots/movement-reticle.png) | ![Laser](./docs/screenshots/movement-laser.png) |

### DicyaninSceneReconstruction

![Scene Reconstruction](./docs/screenshots/scenereconstruction.png)

### DicyaninSimulatorInput

Full-body skeleton reconstructed from streamed pose input.

![Skeleton](./docs/screenshots/siminput-skeleton.png)

### DicyaninSpatialUI

| Curved Panel | Button | Toggle Button |
|--------------|--------|---------------|
| ![Curved Panel](./docs/screenshots/spatialui-curved-panel.png) | ![Button](./docs/screenshots/spatialui-button.png) | ![Toggle Button](./docs/screenshots/spatialui-toggle-button.png) |

| Slider | Radial Menu | Tooltip |
|--------|-------------|---------|
| ![Slider](./docs/screenshots/spatialui-slider.png) | ![Radial Menu](./docs/screenshots/spatialui-radial-menu.png) | ![Tooltip](./docs/screenshots/spatialui-tooltip.png) |

### DicyaninSplash

| Cyber Green | Cyan | Magenta |
|-------------|------|---------|
| ![Cyber Green](./docs/screenshots/splash-cybergreen.png) | ![Cyan](./docs/screenshots/splash-cyan.png) | ![Magenta](./docs/screenshots/splash-magenta.png) |

### DicyaninTextFX

| Neon | Gold | Chrome |
|------|------|--------|
| ![Neon](./docs/screenshots/textfx-neon.png) | ![Gold](./docs/screenshots/textfx-gold.png) | ![Chrome](./docs/screenshots/textfx-chrome.png) |

| Candy (arc) | Graffiti |
|-------------|----------|
| ![Candy](./docs/screenshots/textfx-candy.png) | ![Graffiti](./docs/screenshots/textfx-graffiti.png) |

### DicyaninToonShader

| Arcade | Film Noir | Game Boy |
|--------|-----------|----------|
| ![Arcade](./docs/screenshots/toon-arcade.png) | ![Film Noir](./docs/screenshots/toon-filmnoir.png) | ![Game Boy](./docs/screenshots/toon-gameboy.png) |

| Psychedelic | Rubber Hose | Thermal |
|-------------|-------------|---------|
| ![Psychedelic](./docs/screenshots/toon-psychedelic.png) | ![Rubber Hose](./docs/screenshots/toon-rubberhose.png) | ![Thermal](./docs/screenshots/toon-thermal.png) |

### DicyaninVFXBudget

Spawn requests gated to a per-category cap; admitted entities laid out in a ring.

![VFX Budget](./docs/screenshots/vfxbudget-ring.png)

### DicyaninVirtualJoystick

| 3D Gamepad | Angled | Arcade Pillar |
|------------|--------|---------------|
| ![Gamepad](./docs/screenshots/gamepad3d.png) | ![Gamepad angled](./docs/screenshots/gamepad3d-angle.png) | ![Arcade pillar](./docs/screenshots/gamepad-pillar.png) |

### DicyaninWatchLink

![Watch Link](./docs/screenshots/watchlink.png)

---

<p align="center">
  <img src="banner.png" alt="DicyaninLabs" width="100%" />
</p>
