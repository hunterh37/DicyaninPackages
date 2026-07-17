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

Screenshots below are rendered offscreen with RealityKit on macOS by the
[`RenderGallery`](./RenderGallery) tool (`swift run RenderGallery`), which loads
each macOS-buildable spatial component, renders it via `RealityRenderer`, and
writes PNGs.

### DicyaninHumanoidMesh

| A-Pose | T-Pose | Sitting |
|--------|--------|---------|
| ![A-Pose](./docs/screenshots/humanoid-a-pose.png) | ![T-Pose](./docs/screenshots/humanoid-t-pose.png) | ![Sitting](./docs/screenshots/humanoid-sitting.png) |

| Yoga Tree | Dabbing | Big Wave |
|-----------|---------|----------|
| ![Yoga Tree](./docs/screenshots/humanoid-yoga-tree.png) | ![Dabbing](./docs/screenshots/humanoid-dabbing.png) | ![Big Wave](./docs/screenshots/humanoid-big-wave.png) |

### DicyaninSpatialUI

| Curved Panel | Button | Toggle Button |
|--------------|--------|---------------|
| ![Curved Panel](./docs/screenshots/spatialui-curved-panel.png) | ![Button](./docs/screenshots/spatialui-button.png) | ![Toggle Button](./docs/screenshots/spatialui-toggle-button.png) |

| Slider | Radial Menu | Tooltip |
|--------|-------------|---------|
| ![Slider](./docs/screenshots/spatialui-slider.png) | ![Radial Menu](./docs/screenshots/spatialui-radial-menu.png) | ![Tooltip](./docs/screenshots/spatialui-tooltip.png) |

### DicyaninVirtualJoystick

| 3D Gamepad | Angled | Arcade Pillar |
|------------|--------|---------------|
| ![Gamepad](./docs/screenshots/gamepad3d.png) | ![Gamepad angled](./docs/screenshots/gamepad3d-angle.png) | ![Arcade pillar](./docs/screenshots/gamepad-pillar.png) |

### DicyaninMetaballs

| Two-Ball Merge | Cluster | Carved Hole |
|----------------|---------|-------------|
| ![Two-Ball Merge](./docs/screenshots/metaball-two-ball-merge.png) | ![Cluster](./docs/screenshots/metaball-cluster.png) | ![Carved Hole](./docs/screenshots/metaball-carved-hole.png) |

| Lava Lamp | Vortex | DNA Helix |
|-----------|--------|-----------|
| ![Lava Lamp](./docs/screenshots/metaball-preset-lavaLamp.png) | ![Vortex](./docs/screenshots/metaball-preset-vortex.png) | ![DNA Helix](./docs/screenshots/metaball-preset-dnaHelix.png) |

---

<p align="center">
  <img src="banner.png" alt="DicyaninLabs" width="100%" />
</p>
