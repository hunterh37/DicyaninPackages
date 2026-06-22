<p align="center">
  <img src="banner.png" alt="DicyaninLabs" width="100%" />
</p>

# Dicyanin Swift Packages

Open-source Swift packages for **visionOS / RealityKit** development by [Dicyanin Labs](https://github.com/hunterh37).
A modular toolkit for hand tracking, gestures, input, entities, networking, and debugging on Apple Vision Pro.

---

## 📦 Packages

### [DicyaninARKitSession](https://github.com/hunterh37/DicyaninARKitSession)
A shared ARKit session manager that provides hand tracking to visionOS apps. The foundation other Dicyanin input packages build on.

### [DicyaninHandTracking](https://github.com/hunterh37/DicyaninHandTracking)
Hand tracking and interaction with 3D objects in visionOS applications.

### [DicyaninHandGesture](https://github.com/hunterh37/DicyaninHandGesture)
A clean, reusable interface for hand gesture detection in visionOS.

### [DicyaninMockHandTracking](https://github.com/hunterh37/DicyaninMockHandTracking)
Simulated hand tracking for the visionOS simulator (where ARKit hand tracking isn't available). Write against one hand-pose source — mock in the simulator, live ARKit on device, no code changes.

<img src="https://raw.githubusercontent.com/hunterh37/DicyaninMockHandTracking/main/Screenshots/control-panel.png" width="250" />

### [DicyaninVirtualJoystick](https://github.com/hunterh37/DicyaninVirtualJoystick)
A world-anchored 3D virtual joystick rig for RealityKit on visionOS/iOS.

<img src="https://raw.githubusercontent.com/hunterh37/DicyaninVirtualJoystick/main/Media/gamepad.png" width="250" />

### [DicyaninThumbController](https://github.com/hunterh37/DicyaninThumbController)
Thumb-based joystick control using hand tracking — converts thumb movement into virtual joystick input via `DicyaninARKitSession`.

<img src="https://github.com/user-attachments/assets/d0d9fef3-cdb1-4b9b-9209-c8b4ceefa032" width="250" />

### [DicyaninEntity](https://github.com/hunterh37/DicyaninEntity)
A sophisticated, extensible custom RealityKit entity class for 3D content creation on visionOS.

### [DicyaninEntityManagement](https://github.com/hunterh37/DicyaninEntityManagement)
Managing 3D entities and scenes in RealityKit applications.

### [DicyaninEntityDebugger](https://github.com/hunterh37/DicyaninEntityDebugger)
A real-time SwiftUI debugging interface for inspecting RealityKit entity properties, transforms, and components.

### [DicyaninEntityQueries](https://github.com/hunterh37/DicyaninEntityQueries)
A reusable ECS query-caching layer for RealityKit/visionOS — runs scene queries once per frame and hands every system pre-built, parallel-indexed snapshots to read instead of re-querying.

### [DicyaninSharePlay](https://github.com/hunterh37/DicyaninSharePlay)
Real-time synchronization of 3D content and game state across multiple devices via SharePlay.

### [DicyaninMultiPeer](https://github.com/hunterh37/DicyaninMultiPeer)
Synchronizing 3D content across multiple Apple devices using MultipeerConnectivity — shared AR/VR experiences between visionOS and iOS.

<img src="https://raw.githubusercontent.com/hunterh37/DicyaninMultiPeer/master/assets/banner.png" width="250" />

### [DicyaninLLMProviderKit](https://github.com/hunterh37/DicyaninLLMProviderKit)
A unified Swift interface for LLM APIs — chat completions, image generation, and streaming — across multiple providers.

### [DicyaninAssetPreloader](https://github.com/hunterh37/DicyaninAssetPreloader)
Loads RealityKit assets ahead of time, caches the parsed base resources, and vends cheap clones on demand — so no model is parsed from disk on the main thread mid-experience. Dependency-free, `@MainActor` throughout.

### [DicyaninSceneReconstruction](https://github.com/hunterh37/DicyaninSceneReconstruction)
Wraps Apple's `SceneReconstructionProvider` into a clean service: start/stop scene reconstruction, get tracked mesh anchors and their `ModelEntity` chunks with real static colliders, track scan coverage, and raycast to the floor.

### [DicyaninVFXBudget](https://github.com/hunterh37/DicyaninVFXBudget)
A per-frame VFX budgeting layer for high-load visionOS scenes — caps live effect counts, rate-limits spawns, and FIFO ring-buffer evicts the oldest effect when a cap is exceeded, holding the 90 Hz frame budget when many effects are on screen at once.

### [ImmersiveTesting](https://github.com/hunterh37/immersivetesting)
A framework for immersive unit testing on visionOS — drives headless scene-state verification so you can assert that entities actually land in the RealityKit graph, are independent clones, and behave correctly. Used as the test backbone across several Dicyanin packages.

---

## 🔗 Resources

- **Example projects:** [DicyaninPackagesExampleProjects](https://github.com/hunterh37/DicyaninPackagesExampleProjects)
- **Website:** [Dicyanin Labs](https://dicyaninlabs.com)

## 📥 Installation

Add any package via Swift Package Manager in Xcode:

```
File → Add Package Dependencies… → paste the repo URL
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hunterh37/DicyaninARKitSession.git", branch: "master")
]
```
