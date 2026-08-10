import 'package:flutter/material.dart';

import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';

import '../main.dart';

/// Toggles the session's debug visualisations (feature points, planes, world
/// origin) live by re-calling [ARSessionManager.onInitialize].
class DebugOptionsDemo extends StatefulWidget {
  const DebugOptionsDemo({super.key});

  @override
  State<DebugOptionsDemo> createState() => _DebugOptionsDemoState();
}

class _DebugOptionsDemoState extends State<DebugOptionsDemo> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool _showFeaturePoints = false;
  bool _showPlanes = true;
  bool _showWorldOrigin = false;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug options')),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            showPlatformType: true,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              color: Colors.white.withValues(alpha: 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Feature points'),
                    value: _showFeaturePoints,
                    onChanged: (v) => setState(() {
                      _showFeaturePoints = v;
                      _applySettings();
                    }),
                  ),
                  SwitchListTile(
                    title: const Text('Planes'),
                    value: _showPlanes,
                    onChanged: (v) => setState(() {
                      _showPlanes = v;
                      _applySettings();
                    }),
                  ),
                  SwitchListTile(
                    title: const Text('World origin'),
                    value: _showWorldOrigin,
                    onChanged: (v) => setState(() {
                      _showWorldOrigin = v;
                      _applySettings();
                    }),
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
    objectManager.onInitialize();
    _applySettings();
  }

  void _applySettings() {
    arSessionManager?.onInitialize(
      showFeaturePoints: _showFeaturePoints,
      showPlanes: _showPlanes,
      customPlaneTexturePath: kPlaneTextureAsset,
      showWorldOrigin: _showWorldOrigin,
    );
  }
}
