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

![DicyaninMockHandTracking](https://raw.githubusercontent.com/hunterh37/DicyaninMockHandTracking/main/Screenshots/control-panel.png)

### [DicyaninVirtualJoystick](https://github.com/hunterh37/DicyaninVirtualJoystick)
A world-anchored 3D virtual joystick rig for RealityKit on visionOS/iOS.

<img src="https://raw.githubusercontent.com/hunterh37/DicyaninVirtualJoystick/main/Media/gamepad.png" width="480" />

### [DicyaninThumbController](https://github.com/hunterh37/DicyaninThumbController)
Thumb-based joystick control using hand tracking — converts thumb movement into virtual joystick input via `DicyaninARKitSession`.

![DicyaninThumbController](https://github.com/user-attachments/assets/d0d9fef3-cdb1-4b9b-9209-c8b4ceefa032)

### [DicyaninEntity](https://github.com/hunterh37/DicyaninEntity)
A sophisticated, extensible custom RealityKit entity class for 3D content creation on visionOS.

### [DicyaninEntityManagement](https://github.com/hunterh37/DicyaninEntityManagement)
Managing 3D entities and scenes in RealityKit applications.

### [DicyaninEntityDebugger](https://github.com/hunterh37/DicyaninEntityDebugger)
A real-time SwiftUI debugging interface for inspecting RealityKit entity properties, transforms, and components.

### [DicyaninSharePlay](https://github.com/hunterh37/DicyaninSharePlay)
Real-time synchronization of 3D content and game state across multiple devices via SharePlay.

### [DicyaninMultiPeer](https://github.com/hunterh37/DicyaninMultiPeer)
Synchronizing 3D content across multiple Apple devices using MultipeerConnectivity — shared AR/VR experiences between visionOS and iOS.

![DicyaninMultiPeer](https://raw.githubusercontent.com/hunterh37/DicyaninMultiPeer/master/assets/banner.png)

### [DicyaninLLMProviderKit](https://github.com/hunterh37/DicyaninLLMProviderKit)
A unified Swift interface for LLM APIs — chat completions, image generation, and streaming — across multiple providers.

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
