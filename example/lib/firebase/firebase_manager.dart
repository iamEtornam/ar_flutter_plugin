import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';

/// A model entry the "external model management" demo lets the user pick from,
/// backed by a Firestore `models` collection.
class AvailableModel {
  const AvailableModel(this.name, this.uri, this.image);
  final String name;
  final String uri;
  final String image;
}

typedef QueryListener = void Function(
    QuerySnapshot<Map<String, dynamic>> snapshot);

/// Thin wrapper around Firestore used by the cloud-anchor demos.
///
/// This is a simplified adaptation of the original `examples/` snippets: it
/// drops the `geoflutterfire2` geo-radius query (that package is unmaintained
/// and conflicts with current `cloud_firestore`) and downloads the most recent
/// anchor instead. Storing/serving anchors by geographic location is left as an
/// exercise — see the plugin docs and `cloudAnchorSetup.md`.
class FirebaseManager {
  CollectionReference<Map<String, dynamic>>? _anchors;
  CollectionReference<Map<String, dynamic>>? _objects;
  CollectionReference<Map<String, dynamic>>? _models;

  /// Returns true once Firebase is initialized. Returns false (rather than
  /// throwing) when no Firebase configuration is present, so the demo can show
  /// a friendly message instead of crashing.
  Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();
      final firestore = FirebaseFirestore.instance;
      _anchors = firestore.collection('anchors');
      _objects = firestore.collection('objects');
      _models = firestore.collection('models');
      return true;
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      return false;
    }
  }

  Future<void> uploadAnchor(ARAnchor anchor) async {
    final anchors = _anchors;
    if (anchors == null) return;
    final serialized = anchor.toJson();
    final ttl = (serialized['ttl'] as int?) ?? 1;
    serialized['expirationTime'] =
        DateTime.now().millisecondsSinceEpoch / 1000 + ttl * 24 * 60 * 60;
    try {
      await anchors.add(serialized);
    } catch (e) {
      debugPrint('Failed to add anchor: $e');
    }
  }

  Future<void> uploadObject(ARNode node) async {
    final objects = _objects;
    if (objects == null) return;
    try {
      await objects.add(node.toMap());
    } catch (e) {
      debugPrint('Failed to add object: $e');
    }
  }

  /// Downloads the most recently uploaded anchor document.
  Future<void> downloadLatestAnchor(QueryListener listener) async {
    final anchors = _anchors;
    if (anchors == null) return;
    try {
      final snapshot =
          await anchors.orderBy('expirationTime').limitToLast(1).get();
      listener(snapshot);
    } catch (e) {
      debugPrint('Failed to download anchor: $e');
    }
  }

  /// Downloads the object documents whose `name` is one of the anchor's children.
  Future<void> getObjectsFromAnchor(
      ARPlaneAnchor anchor, QueryListener listener) async {
    final objects = _objects;
    if (objects == null || anchor.childNodes.isEmpty) return;
    try {
      final snapshot =
          await objects.where('name', whereIn: anchor.childNodes).get();
      listener(snapshot);
    } catch (e) {
      debugPrint('Failed to download objects: $e');
    }
  }

  /// Downloads every entry of the `models` collection.
  Future<void> downloadAvailableModels(QueryListener listener) async {
    final models = _models;
    if (models == null) return;
    try {
      listener(await models.get());
    } catch (e) {
      debugPrint('Failed to download models: $e');
    }
  }
}
