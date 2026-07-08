import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

const String _localModelAsset = 'assets/models/Duck.gltf';
const String _fileSystemModelName = 'Duck.glb';

/// Adds objects at the world origin from three sources — a bundled asset
/// (`localGLTF2`), the web (`webGLB`) and the app's documents directory
/// (`fileSystemAppFolderGLB`) — and shuffles their transforms.
class LocalAndWebObjectsDemo extends StatefulWidget {
  const LocalAndWebObjectsDemo({super.key});

  @override
  State<LocalAndWebObjectsDemo> createState() => _LocalAndWebObjectsDemoState();
}

class _LocalAndWebObjectsDemoState extends State<LocalAndWebObjectsDemo> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  ARNode? localNode;
  ARNode? webNode;
  ARNode? fileSystemNode;
  bool _fileReady = false;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local & web objects')),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _toggleLocal,
                    child: const Text('Local asset'),
                  ),
                  ElevatedButton(
                    onPressed: _toggleWeb,
                    child: const Text('Web'),
                  ),
                  ElevatedButton(
                    onPressed: _fileReady ? _toggleFileSystem : null,
                    child: const Text('File system'),
                  ),
                  ElevatedButton(
                    onPressed: localNode == null ? null : () => _shuffle(localNode!),
                    child: const Text('Shuffle local'),
                  ),
                  ElevatedButton(
                    onPressed: webNode == null ? null : () => _shuffle(webNode!),
                    child: const Text('Shuffle web'),
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
      handleTaps: false,
      // Enabled so updateNode() (used by the shuffle buttons) is applied on
      // Android, where transform sync is gated behind gesture handling.
      handlePans: true,
      handleRotation: true,
    );
    objectManager.onInitialize();

    // Download a GLB into the documents directory for the file-system demo.
    _downloadFileSystemModel();
  }

  Future<void> _downloadFileSystemModel() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(kDuckGlbUrl));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      final dir = (await getApplicationDocumentsDirectory()).path;
      await File('$dir/$_fileSystemModelName').writeAsBytes(bytes);
      client.close();
      if (mounted) setState(() => _fileReady = true);
    } catch (e) {
      debugPrint('File-system model download failed: $e');
    }
  }

  Future<void> _toggleLocal() async {
    if (localNode != null) {
      arObjectManager!.removeNode(localNode!);
      setState(() => localNode = null);
      return;
    }
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: _localModelAsset,
      scale: Vector3(0.2, 0.2, 0.2),
    );
    if (await arObjectManager!.addNode(node) == true) {
      setState(() => localNode = node);
    } else {
      _snack('Adding local object failed');
    }
  }

  Future<void> _toggleWeb() async {
    if (webNode != null) {
      arObjectManager!.removeNode(webNode!);
      setState(() => webNode = null);
      return;
    }
    final node = ARNode(
      type: NodeType.webGLB,
      uri: kDuckGlbUrl,
      scale: Vector3(0.2, 0.2, 0.2),
    );
    if (await arObjectManager!.addNode(node) == true) {
      setState(() => webNode = node);
    } else {
      _snack('Adding web object failed');
    }
  }

  Future<void> _toggleFileSystem() async {
    if (fileSystemNode != null) {
      arObjectManager!.removeNode(fileSystemNode!);
      setState(() => fileSystemNode = null);
      return;
    }
    final node = ARNode(
      type: NodeType.fileSystemAppFolderGLB,
      uri: _fileSystemModelName,
      scale: Vector3(0.2, 0.2, 0.2),
    );
    if (await arObjectManager!.addNode(node) == true) {
      setState(() => fileSystemNode = node);
    } else {
      _snack('Adding file-system object failed');
    }
  }

  void _shuffle(ARNode node) {
    final random = Random();
    final scale = random.nextDouble() / 3 + 0.1;
    final translation = Vector3.zero();
    translation[random.nextInt(3)] = random.nextDouble() / 3;
    final axis = Vector3.zero();
    axis[random.nextInt(3)] = 1.0;

    final transform = Matrix4.identity()
      ..setTranslation(translation)
      ..rotate(axis, random.nextDouble())
      ..scaleByDouble(scale, scale, scale, 1);
    node.transform = transform;
    arObjectManager!.updateNode(node);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
