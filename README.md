# DicyaninPackages

A collection of reusable visionOS Swift packages.

## Packages

| Package | Description |
|---------|-------------|
| [DicyaninAssetPreloader](./DicyaninAssetPreloader) | Asset preloading utilities |
| [DicyaninDeviceController](./DicyaninDeviceController) | Device controller input |
| [DicyaninEntityManagement](./DicyaninEntityManagement) | Entity management framework |
| [DicyaninEntityQueries](./DicyaninEntityQueries) | Entity query system |
| [DicyaninGamecenterWrapper](./DicyaninGamecenterWrapper) | Game Center integration wrapper |
| [DicyaninGestureTipGhostHands](./DicyaninGestureTipGhostHands) | Ghost hand gesture tips |
| [DicyaninGrabbableObject](./DicyaninGrabbableObject) | Grabbable object interactions |
| [DicyaninHandGesture](https://github.com/hunterh37/DicyaninHandGesture) | Hand gesture recording, recognition, and playback |
| [DicyaninHandMenu](./DicyaninHandMenu) | Hand-anchored menu UI |
| [DicyaninHomeDioramaScene](./DicyaninHomeDioramaScene) | Home diorama scene |
| [DicyaninHUDAnchoredView](./DicyaninHUDAnchoredView) | Head-anchored HUD for RealityView attachments |
| [DicyaninHumanoidMesh](./DicyaninHumanoidMesh) | Humanoid mesh and poses |
| [DicyaninLabsMoCapRecording](./DicyaninLabsMoCapRecording) | Motion capture recording |
| [DicyaninMapNavigation](./DicyaninMapNavigation) | Map navigation |
| [DicyaninMetaballs](https://github.com/hunterh37/DicyaninMetaballs) | Metaball rendering effects |
| [DicyaninMockHandTracking](./DicyaninMockHandTracking) | Mock hand tracking for testing |
| [DicyaninRoomFX](./DicyaninRoomFX) | Room-scale visual effects |
| [DicyaninSceneMovement](./DicyaninSceneMovement) | Scene movement utilities |
| [DicyaninSceneReconstruction](./DicyaninSceneReconstruction) | Scene reconstruction utilities |
| [DicyaninSimulatorInput](./DicyaninSimulatorInput) | Simulator input support |
| [DicyaninSpatialUI](https://github.com/hunterh37/DicyaninSpatialUI) | Spatial UI components |
| [DicyaninSplash](./DicyaninSplash) | Splash screen |
| [DicyaninTextFX](./DicyaninTextFX) | Text visual effects |
| [DicyaninToonShader](./DicyaninToonShader) | Toon shading |
| [DicyaninVFXBudget](./DicyaninVFXBudget) | VFX budget management |
| [DicyaninVirtualJoystick](./DicyaninVirtualJoystick) | Virtual joystick input |
| [DicyaninWatchLink](./DicyaninWatchLink) | Apple Watch connectivity |

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
