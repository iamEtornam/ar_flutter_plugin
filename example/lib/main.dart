import 'package:flutter/material.dart';

import 'demos/cloud_anchor_demo.dart';
import 'demos/debug_options_demo.dart';
import 'demos/external_model_demo.dart';
import 'demos/local_and_web_objects_demo.dart';
import 'demos/object_gestures_demo.dart';
import 'demos/objects_on_planes_demo.dart';
import 'demos/screenshot_demo.dart';
import 'demos/web_object_demo.dart';

/// A self-contained GLB model hosted by Khronos, used by the demos so no
/// binary asset needs to be bundled with this example.
const String kDuckGlbUrl =
    'https://github.com/KhronosGroup/glTF-Sample-Models/raw/refs/heads/main/2.0/Duck/glTF-Binary/Duck.glb';

/// Flutter asset key for the plane texture bundled with this example.
const String kPlaneTextureAsset = 'assets/images/triangle.png';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Flutter Plugin Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class _Demo {
  const _Demo(this.title, this.subtitle, this.builder);
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final List<_Demo> _demos = [
    _Demo('Objects on planes', 'Tap a detected plane to anchor a 3D model',
        (_) => const ObjectsOnPlanesDemo()),
    _Demo('Object gestures', 'Pan and rotate placed models with your fingers',
        (_) => const ObjectGesturesDemo()),
    _Demo('Web object + updateNode',
        'Place a web model, then rotate/scale it programmatically',
        (_) => const WebObjectDemo()),
    _Demo('Local & web objects',
        'Place bundled-asset, web and file-system models at the origin',
        (_) => const LocalAndWebObjectsDemo()),
    _Demo('Screenshots', 'Capture the current AR scene as an image',
        (_) => const ScreenshotDemo()),
    _Demo('Debug options', 'Toggle feature points, planes and world origin',
        (_) => const DebugOptionsDemo()),
    _Demo('Cloud anchors', 'Host & resolve anchors (needs Firebase setup)',
        (_) => const CloudAnchorDemo()),
    _Demo('External model management',
        'Choose Firestore-managed models to place (needs Firebase setup)',
        (_) => const ExternalModelDemo()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Flutter Plugin')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'These demos require a physical ARCore (Android) or ARKit (iOS) '
              'device with camera access. They will not render in an emulator '
              'or simulator.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _demos.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final demo = _demos[index];
                return ListTile(
                  leading: const Icon(Icons.view_in_ar),
                  title: Text(demo.title),
                  subtitle: Text(demo.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: demo.builder)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
