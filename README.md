# DicyaninPackages

A collection of reusable visionOS Swift packages.

## Packages

| Package | Description |
|---------|-------------|
| [DicyaninHandGesture](https://github.com/hunterh37/DicyaninHandGesture) | Hand gesture recording, recognition, and playback |
| [DicyaninAssetPreloader](./DicyaninAssetPreloader) | Asset preloading utilities |
| [DicyaninEntityManagement](./DicyaninEntityManagement) | Entity management framework |
| [DicyaninEntityQueries](./DicyaninEntityQueries) | Entity query system |
| [DicyaninGrabbableObject](./DicyaninGrabbableObject) | Grabbable object interactions |
| [DicyaninMockHandTracking](./DicyaninMockHandTracking) | Mock hand tracking for testing |
| [DicyaninSceneReconstruction](./DicyaninSceneReconstruction) | Scene reconstruction utilities |
| [DicyaninVFXBudget](./DicyaninVFXBudget) | VFX budget management |
| [DicyaninVirtualJoystick](./DicyaninVirtualJoystick) | Virtual joystick input |

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
