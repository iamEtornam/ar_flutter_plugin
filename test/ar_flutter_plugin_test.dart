import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';

void main() {
  const MethodChannel channel = MethodChannel('ar_flutter_plugin_2');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ArFlutterPlugin.platformVersion, '42');
  });

  // Regression test for upstream issue #8: the session event handlers used to
  // be declared `late` and non-nullable, so reading them before the app
  // assigned one threw `LateInitializationError: Field 'onPlaneDetected' has
  // not been initialized.` They must now be nullable and default to null.
  testWidgets('session event handlers are null-safe when unset (issue #8)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));

    final sessionManager =
        ARSessionManager(0, context, PlaneDetectionConfig.none);

    expect(sessionManager.onPlaneOrPointTap, isNull);
    expect(sessionManager.onPlaneDetected, isNull);
  });

  // Regression test for upstream issue #6: `updateNode` did not exist even
  // though it was the documented way to sync transform changes. It must push a
  // `transformationChanged` call (the method the native side already handles).
  test('updateNode pushes transformationChanged to the object channel (issue #6)',
      () async {
    const objectChannel = MethodChannel('arobjects_0');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(objectChannel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(objectChannel, null));

    final objectManager = ARObjectManager(0);
    final node = ARNode(
        type: NodeType.localGLTF2, uri: 'model.gltf', name: 'myNode');

    await objectManager.updateNode(node);

    expect(calls.single.method, 'transformationChanged');
    final args = calls.single.arguments as Map;
    expect(args['name'], 'myNode');
    expect(args['transformation'], isA<List<dynamic>>());
    expect((args['transformation'] as List).length, 16);
  });
}
