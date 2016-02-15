library flow.render.webgl_renderer;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:html' as html;

import 'package:stagexl/stagexl.dart' as xl;
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:flow/src/render/renderer.dart';
import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';

import 'package:flow/src/force_print.dart';

class WebglRenderer<T> extends Renderer {

  final Map<NodeData<T>, xl.Sprite> _sprites = <NodeData<T>, xl.Sprite>{};

  html.CanvasElement canvas;
  xl.Stage stage;
  xl.RenderLoop renderLoop;

  WebglRenderer(String selector) {
    canvas = html.querySelector(selector);
    stage = new xl.Stage(canvas,
      options: xl.Stage.defaultOptions.clone()
        ..antialias = true
        ..inputEventMode = xl.InputEventMode.MouseAndTouch
      )
      ..scaleMode = xl.StageScaleMode.NO_SCALE
      ..align = xl.StageAlign.TOP_LEFT
      ..backgroundColor = xl.Color.White;
    renderLoop = new xl.RenderLoop();

    stage.renderMode = xl.StageRenderMode.AUTO;

    renderLoop.addStage(stage);

    final StreamController<Tuple2<int, int>> screenSize$ctrl = new StreamController<Tuple2<int, int>>();

    rx.observable(screenSize$ctrl.stream)
        .startWith(<Tuple2<int, int>>[new Tuple2<int, int>(html.window.innerWidth, html.window.innerHeight)])
        .distinct((Tuple2<int, int> prev, Tuple2<int, int> next) => prev == next)
        .listen((Tuple2<int, int> tuple) {

      canvas.width = tuple.item1 - 4;
      canvas.height = tuple.item2 - 4;
    });

    stage.onEnterFrame.listen((_) => screenSize$ctrl.add(new Tuple2<int, int>(html.window.innerWidth, html.window.innerHeight)));
  }

  void invalidate(Iterable<Map<String, dynamic>> data) {
    final List<Map<String, dynamic>> rootItems = data.where((Map<String, dynamic> entry) => entry['parent'].data == null).toList(growable: false);

    rootItems.sort((Map<String, dynamic> entryA, Map<String, dynamic> entryB) => entryA['state'].childIndex.compareTo(entryB['state'].childIndex));

    data.forEach((Map<String, dynamic> entry) {
      final NodeData<T> nodeData = entry['self'];
      final NodeState state = entry['state'];
      final NodeData<T> parent = entry['parent'];
      final Tuple4<NodeData<T>, double, double, UnmodifiableListView<NodeState>> childPos = entry['childPos'];
      final bool isRoot = parent.data == null;

      if (!isRoot && !_sprites.containsKey(parent)) _sprites[parent] = new xl.Sprite();
      if (!_sprites.containsKey(nodeData)) _sprites[nodeData] = new xl.Sprite();
      if (childPos != null && !_sprites.containsKey(childPos.item1)) _sprites[childPos.item1] = new xl.Sprite();

      final xl.Sprite sprite = _sprites[nodeData];
      final xl.DisplayObjectContainer container = isRoot ? stage : _sprites[parent];
      final xl.Sprite child = (childPos != null) ? _sprites[childPos.item1] : null;

      if (childPos != null) {
        final double dh = childPos.item4.fold(.0, (double prev, NodeState curr) => math.max(prev, curr.actualHeight));

        child.x = childPos.item2;
        child.y = childPos.item3 + dh/2 + state.actualHeight/2;
      }

      final double dw = state.width - 20;
      final double dh = state.height - 20;

      sprite.graphics.clear();
      sprite.graphics.beginPath();
      sprite.graphics.rect(-dw/2, -dh/2, dw, dh);
      sprite.graphics.strokeColor(xl.Color.Red);
      sprite.graphics.fillColor(xl.Color.Black);
      sprite.graphics.closePath();

      container.addChild(sprite);
    });

    double xOffset = .0;
    int childIndex = -1;

    rootItems.forEach((Map<String, dynamic> entry) {
      final xl.Sprite sprite = _sprites[entry['self']];
      final NodeState state = entry['state'];

      if (state.childIndex != childIndex) {
        sprite.x = xOffset + state.actualWidth / 2;
        sprite.y = state.height / 2;

        xOffset += state.actualWidth;

        childIndex = state.childIndex;
      }
    });

    print(data);

  }

}