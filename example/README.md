# ar_flutter_plugin_2 example

A runnable demo app for the `ar_flutter_plugin_2` plugin (referenced via a
path dependency on `../`).

## Requirements

AR runs only on a **physical device** — ARCore on Android, ARKit on iOS. It
will not render in an emulator or simulator. Camera permission is requested at
runtime.

- Android: `minSdk 28` (set in `android/app/build.gradle.kts`); the device must
  support [ARCore](https://developers.google.com/ar/devices).
- iOS: an ARKit-capable device; `NSCameraUsageDescription` is set in
  `ios/Runner/Info.plist`.

## Run

```bash
cd example
flutter pub get
flutter run              # on a connected AR-capable device
```

## Demos

| Screen | Feature exercised | Source |
| --- | --- | --- |
| Objects on planes | Plane detection, `addAnchor`, `addNode` on a plane anchor, `onNodeTap` | `lib/demos/objects_on_planes_demo.dart` |
| Object gestures | `handlePans`/`handleRotation`, `onPanEnd`/`onRotationEnd`, syncing `ARNode.transform` | `lib/demos/object_gestures_demo.dart` |
| Web object + updateNode | `addNode`/`removeNode` at the world origin and `updateNode` (programmatic rotate/scale) | `lib/demos/web_object_demo.dart` |
| Local & web objects | `localGLTF2` (bundled asset), `webGLB`, `fileSystemAppFolderGLB`, transform shuffle | `lib/demos/local_and_web_objects_demo.dart` |
| Screenshots | `ARSessionManager.snapshot()` | `lib/demos/screenshot_demo.dart` |
| Debug options | Live-toggling `showFeaturePoints` / `showPlanes` / `showWorldOrigin` | `lib/demos/debug_options_demo.dart` |
| Cloud anchors | `initGoogleCloudAnchorMode`, `uploadAnchor`/`downloadAnchor` + Firestore | `lib/demos/cloud_anchor_demo.dart` |
| External model management | Firestore-managed model list + cloud anchors | `lib/demos/external_model_demo.dart` |

Most models load as `NodeType.webGLB` from a public Khronos sample URL. Bundled
assets are `assets/images/triangle.png` (plane texture for
`customPlaneTexturePath`) and a self-contained `assets/models/Duck.gltf` (for
the local-asset demo).

### Cloud anchor demos (Firebase)

The **Cloud anchors** and **External model management** screens need a
configured Firebase project and the Google Cloud Anchor service — see
[`cloudAnchorSetup.md`](../cloudAnchorSetup.md). Without a Firebase
configuration they show a "Firebase initialization failed" screen rather than
crashing, so the rest of the app still runs. These two demos are simplified
from the original snippets: they drop the discontinued `geoflutterfire2`
geo-radius query and download the most recently uploaded anchor instead.
