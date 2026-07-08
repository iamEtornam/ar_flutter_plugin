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

import '../firebase/firebase_manager.dart';
import '../main.dart';

/// Places objects, hosts their anchor with the Google Cloud Anchor service, and
/// resolves it back so the scene can be shared across devices.
///
/// Requires a configured Firebase project (see `cloudAnchorSetup.md`). Without
/// one this screen shows a friendly "initialization failed" message instead of
/// crashing.
class CloudAnchorDemo extends StatefulWidget {
  const CloudAnchorDemo({super.key});

  @override
  State<CloudAnchorDemo> createState() => _CloudAnchorDemoState();
}

class _CloudAnchorDemoState extends State<CloudAnchorDemo> {
  final FirebaseManager _firebase = FirebaseManager();
  bool _initialized = false;
  bool _error = false;

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final List<ARNode> nodes = [];
  final List<ARAnchor> anchors = [];
  final Map<String, Map<String, dynamic>> _downloadsInProgress = {};

  bool _readyToUpload = false;
  bool _readyToDownload = true;

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
      return _MessageScaffold(
        title: 'Cloud anchors',
        message: 'Firebase initialization failed.\n'
            'Add a Firebase configuration to run this demo.',
        onRetry: () {
          setState(() => _error = false);
          _initFirebase();
        },
      );
    }
    if (!_initialized) {
      return const _MessageScaffold(
        title: 'Cloud anchors',
        message: 'Initializing Firebase…',
        showProgress: true,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud anchors')),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_readyToUpload)
                    ElevatedButton(
                        onPressed: _upload, child: const Text('Upload')),
                  if (_readyToDownload)
                    ElevatedButton(
                        onPressed: _download, child: const Text('Download')),
                ],
              ),
            ),
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
    anchorManager.onAnchorUploaded = _onAnchorUploaded;
    anchorManager.onAnchorDownloaded = _onAnchorDownloaded;
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
      uri: kDuckGlbUrl,
      scale: Vector3(0.2, 0.2, 0.2),
      position: Vector3(0, 0, 0),
      rotation: Vector4(1, 0, 0, 0),
      data: {'onTapText': 'Ouch, that hurt!'},
    );
    if (await arObjectManager!.addNode(node, planeAnchor: anchor) == true) {
      nodes.add(node);
      setState(() => _readyToUpload = true);
    } else {
      _snack('Adding node failed');
    }
  }

  void _onNodeTapped(List<String> nodeNames) {
    if (nodeNames.isEmpty) return;
    ARNode? tapped;
    for (final n in nodes) {
      if (n.name == nodeNames.first) {
        tapped = n;
        break;
      }
    }
    _snack(tapped?.data?['onTapText']?.toString() ?? 'Tapped a node');
  }

  Future<void> _upload() async {
    if (anchors.isEmpty) return;
    await arAnchorManager!.uploadAnchor(anchors.last);
    setState(() => _readyToUpload = false);
  }

  void _onAnchorUploaded(ARAnchor anchor) {
    _firebase.uploadAnchor(anchor);
    if (anchor is ARPlaneAnchor) {
      for (final nodeName in anchor.childNodes) {
        for (final node in nodes) {
          if (node.name == nodeName) {
            _firebase.uploadObject(node);
            break;
          }
        }
      }
    }
    setState(() {
      _readyToDownload = true;
      _readyToUpload = false;
    });
    _snack('Upload successful');
  }

  ARAnchor _onAnchorDownloaded(Map<String, dynamic> serializedAnchor) {
    final cloudId = serializedAnchor['cloudanchorid'];
    final raw = _downloadsInProgress.remove(cloudId) ?? serializedAnchor;
    final anchor = ARPlaneAnchor.fromJson(raw);
    anchors.add(anchor);

    _firebase.getObjectsFromAnchor(anchor, (snapshot) {
      for (final doc in snapshot.docs) {
        final node = ARNode.fromMap(doc.data());
        arObjectManager!.addNode(node, planeAnchor: anchor);
        nodes.add(node);
      }
    });

    return anchor;
  }

  Future<void> _download() async {
    await _firebase.downloadLatestAnchor((snapshot) {
      if (snapshot.docs.isEmpty) {
        _snack('No uploaded anchors found');
        return;
      }
      final doc = snapshot.docs.first;
      final data = doc.data();
      final cloudId = data['cloudanchorid'] as String?;
      if (cloudId == null) return;
      _downloadsInProgress[cloudId] = data;
      arAnchorManager!.downloadAnchor(cloudId);
    });
    setState(() => _readyToDownload = false);
  }

  Future<void> _removeEverything() async {
    for (final anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();
    nodes.clear();
    setState(() {
      _readyToDownload = true;
      _readyToUpload = false;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Simple scaffold for the loading / error states.
class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({
    required this.title,
    required this.message,
    this.showProgress = false,
    this.onRetry,
  });

  final String title;
  final String message;
  final bool showProgress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message, textAlign: TextAlign.center),
            ),
            if (onRetry != null)
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
