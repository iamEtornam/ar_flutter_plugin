import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';

import '../main.dart';

/// Places models on planes and captures the AR scene with
/// [ARSessionManager.snapshot].
class ScreenshotDemo extends StatefulWidget {
  const ScreenshotDemo({super.key});

  @override
  State<ScreenshotDemo> createState() => _ScreenshotDemoState();
}

class _ScreenshotDemoState extends State<ScreenshotDemo> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final List<ARNode> nodes = [];
  final List<ARAnchor> anchors = [];

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screenshots')),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _removeEverything,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove everything'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _takeScreenshot,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take screenshot'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    sessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: kPlaneTextureAsset,
      showWorldOrigin: true,
    );
    objectManager.onInitialize();

    sessionManager.onPlaneOrPointTap = _onPlaneOrPointTapped;
  }

  Future<void> _takeScreenshot() async {
    final image = await arSessionManager!.snapshot();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hits) async {
    final planeHits =
        hits.where((h) => h.type == ARHitTestResultType.plane).toList();
    if (planeHits.isEmpty) return;

    final anchor = ARPlaneAnchor(transformation: planeHits.first.worldTransform);
    final didAddAnchor = await arAnchorManager!.addAnchor(anchor);
    if (didAddAnchor != true) {
      _snack('Adding anchor failed');
      return;
    }
    anchors.add(anchor);

    final node = ARNode(
      type: NodeType.webGLB,
      uri: kDuckGlbUrl,
      scale: Vector3(0.2, 0.2, 0.2),
      position: Vector3(0, 0, 0),
      rotation: Vector4(1, 0, 0, 0),
    );
    final didAddNode = await arObjectManager!.addNode(node, planeAnchor: anchor);
    if (didAddNode == true) {
      nodes.add(node);
    } else {
      _snack('Adding node failed');
    }
  }

  Future<void> _removeEverything() async {
    for (final anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();
    nodes.clear();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
