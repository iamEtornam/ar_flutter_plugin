import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';

import '../main.dart';

/// Loads a GLB model from the web at the world origin, then demonstrates
/// [ARObjectManager.updateNode] by rotating and scaling it programmatically.
///
/// Note: on Android the transform sync only takes effect when pan or rotation
/// handling is enabled, so this demo turns both on.
class WebObjectDemo extends StatefulWidget {
  const WebObjectDemo({super.key});

  @override
  State<WebObjectDemo> createState() => _WebObjectDemoState();
}

class _WebObjectDemoState extends State<WebObjectDemo> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  ARNode? _node;
  double _scale = 0.2;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNode = _node != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Web object + updateNode')),
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
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: hasNode ? null : _addNode,
                    icon: const Icon(Icons.add),
                    label: const Text('Add model'),
                  ),
                  ElevatedButton.icon(
                    onPressed: hasNode ? _rotate : null,
                    icon: const Icon(Icons.rotate_right),
                    label: const Text('Rotate 45°'),
                  ),
                  ElevatedButton.icon(
                    onPressed: hasNode ? _scaleUp : null,
                    icon: const Icon(Icons.zoom_in),
                    label: const Text('Scale up'),
                  ),
                  ElevatedButton.icon(
                    onPressed: hasNode ? _remove : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
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

    sessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: kPlaneTextureAsset,
      showWorldOrigin: true,
      handlePans: true,
      handleRotation: true,
    );
    objectManager.onInitialize();
  }

  Future<void> _addNode() async {
    final node = ARNode(
      type: NodeType.webGLB,
      uri: kDuckGlbUrl,
      scale: Vector3.all(_scale),
      position: Vector3(0, 0, -1), // 1 metre in front of the world origin
    );
    final didAdd = await arObjectManager!.addNode(node);
    if (didAdd == true) {
      setState(() => _node = node);
    } else {
      _snack('Adding node failed');
    }
  }

  // Both handlers mutate the node's transform and push it to the native engine
  // with updateNode — the method added for upstream issue #6.
  void _rotate() {
    final node = _node!;
    final angles = node.eulerAngles;
    node.eulerAngles = Vector3(angles.x, angles.y + math.pi / 4, angles.z);
    arObjectManager!.updateNode(node);
  }

  void _scaleUp() {
    final node = _node!;
    _scale = (_scale + 0.1).clamp(0.1, 1.0);
    node.scale = Vector3.all(_scale);
    arObjectManager!.updateNode(node);
  }

  void _remove() {
    arObjectManager!.removeNode(_node!);
    setState(() => _node = null);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
