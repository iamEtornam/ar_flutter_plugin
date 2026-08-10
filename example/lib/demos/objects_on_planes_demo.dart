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

/// Tapping a detected plane creates an [ARPlaneAnchor] with a 3D model attached.
class ObjectsOnPlanesDemo extends StatefulWidget {
  const ObjectsOnPlanesDemo({super.key});

  @override
  State<ObjectsOnPlanesDemo> createState() => _ObjectsOnPlanesDemoState();
}

class _ObjectsOnPlanesDemoState extends State<ObjectsOnPlanesDemo> {
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
      appBar: AppBar(title: const Text('Objects on planes')),
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
              child: ElevatedButton.icon(
                onPressed: _removeEverything,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove everything'),
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
    objectManager.onNodeTap = _onNodeTapped;
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

  void _onNodeTapped(List<String> tappedNodes) =>
      _snack('Tapped ${tappedNodes.length} node(s)');

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
