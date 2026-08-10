import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

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

import '../firebase/firebase_manager.dart';
import '../main.dart';

/// Like the cloud-anchor demo, but the model to place is chosen from a list
/// managed in a Firestore `models` collection (fields: `name`, `image`, `uri`).
///
/// Requires a configured Firebase project (see `cloudAnchorSetup.md`).
class ExternalModelDemo extends StatefulWidget {
  const ExternalModelDemo({super.key});

  @override
  State<ExternalModelDemo> createState() => _ExternalModelDemoState();
}

class _ExternalModelDemoState extends State<ExternalModelDemo> {
  final FirebaseManager _firebase = FirebaseManager();
  bool _initialized = false;
  bool _error = false;

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final List<ARNode> nodes = [];
  final List<ARAnchor> anchors = [];
  bool _modelChoiceActive = false;

  AvailableModel _selectedModel =
      const AvailableModel('Duck', kDuckGlbUrl, '');

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    final ok = await _firebase.initialize();
    if (!mounted) return;
    setState(() {
      _initialized = ok;
      _error = !ok;
    });
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        appBar: AppBar(title: const Text('External model management')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Firebase initialization failed.\n'
                  'Add a Firebase configuration to run this demo.',
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = false);
                  _initFirebase();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('External model management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('External model management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: () =>
                setState(() => _modelChoiceActive = !_modelChoiceActive),
          ),
        ],
      ),
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
              child: ElevatedButton.icon(
                onPressed: _removeEverything,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove everything'),
              ),
            ),
          ),
          if (_modelChoiceActive)
            Align(
              alignment: Alignment.centerLeft,
              child: _ModelSelectionPanel(
                firebase: _firebase,
                onSelected: (model) => setState(() {
                  _selectedModel = model;
                  _modelChoiceActive = false;
                }),
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
    anchorManager.initGoogleCloudAnchorMode();

    sessionManager.onPlaneOrPointTap = _onPlaneOrPointTapped;
    objectManager.onNodeTap = _onNodeTapped;
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hits) async {
    final planeHits =
        hits.where((h) => h.type == ARHitTestResultType.plane).toList();
    if (planeHits.isEmpty) return;

    final anchor = ARPlaneAnchor(
        transformation: planeHits.first.worldTransform, ttl: 2);
    if (await arAnchorManager!.addAnchor(anchor) != true) {
      _snack('Adding anchor failed');
      return;
    }
    anchors.add(anchor);

    final node = ARNode(
      type: NodeType.webGLB,
      uri: _selectedModel.uri,
      scale: Vector3(0.2, 0.2, 0.2),
      position: Vector3(0, 0, 0),
      rotation: Vector4(1, 0, 0, 0),
      data: {'onTapText': 'I am a ${_selectedModel.name}'},
    );
    if (await arObjectManager!.addNode(node, planeAnchor: anchor) == true) {
      nodes.add(node);
    } else {
      _snack('Adding node failed');
    }
  }

  void _onNodeTapped(List<String> nodeNames) {
    if (nodeNames.isEmpty) return;
    for (final n in nodes) {
      if (n.name == nodeNames.first) {
        _snack(n.data?['onTapText']?.toString() ?? 'Tapped a node');
        return;
      }
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

class _ModelSelectionPanel extends StatefulWidget {
  const _ModelSelectionPanel({required this.firebase, required this.onSelected});

  final FirebaseManager firebase;
  final ValueChanged<AvailableModel> onSelected;

  @override
  State<_ModelSelectionPanel> createState() => _ModelSelectionPanelState();
}

class _ModelSelectionPanelState extends State<_ModelSelectionPanel> {
  final List<AvailableModel> _models = [];

  @override
  void initState() {
    super.initState();
    widget.firebase.downloadAvailableModels((snapshot) {
      if (!mounted) return;
      setState(() {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          _models.add(AvailableModel(
            (data['name'] ?? 'Model').toString(),
            (data['uri'] ?? '').toString(),
            _imageUrl(data['image']),
          ));
        }
      });
    });
  }

  static String _imageUrl(dynamic image) {
    if (image is String) return image;
    if (image is List && image.isNotEmpty) {
      final first = image.first;
      if (first is Map && first['downloadURL'] != null) {
        return first['downloadURL'].toString();
      }
      return first.toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      color: Colors.white.withValues(alpha: 0.85),
      child: _models.isEmpty
          ? const Center(child: Text('No models in Firestore'))
          : ListView.builder(
              itemCount: _models.length,
              itemBuilder: (context, index) {
                final model = _models[index];
                return Card(
                  child: ListTile(
                    leading: model.image.isEmpty
                        ? const Icon(Icons.view_in_ar)
                        : Image.network(
                            model.image,
                            width: 40,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image),
                          ),
                    title: Text(model.name),
                    onTap: () => widget.onSelected(model),
                  ),
                );
              },
            ),
    );
  }
}
