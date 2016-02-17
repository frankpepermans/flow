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

  final Map<NodeData<T>, DebugSprite> _sprites = <NodeData<T>, DebugSprite>{};

  html.CanvasElement canvas;
  xl.Stage stage;
  xl.RenderLoop renderLoop;
  xl.Sprite topContainer;
  StreamController<Tuple2<int, int>> screenSize$ctrl;

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
    topContainer = new xl.Sprite();
    renderLoop = new xl.RenderLoop();
    screenSize$ctrl = new StreamController<Tuple2<int, int>>();

    stage.renderMode = xl.StageRenderMode.AUTO;

    stage.addChild(topContainer);

    renderLoop.addStage(stage);

    rx.observable(screenSize$ctrl.stream)
      .distinct((Tuple2<int, int> prev, Tuple2<int, int> next) => prev == next)
      .listen((Tuple2<int, int> tuple) {
        canvas.width = math.max(tuple.item1, canvas.width);
        canvas.height = math.max(tuple.item2, canvas.height);
      print('${canvas.width}:${canvas.height}');
      });
  }

  Tuple2<double, double> calculateOffset(NodeData<T> nodeData, Map<xl.Sprite, xl.DisplayObjectContainer> parentMap, Map<xl.Sprite, Tuple2<double, double>> offsetTable) {
    final DebugSprite sprite = _sprites[nodeData];
    final Tuple2<double, double> localOffset = offsetTable[sprite];

    xl.DisplayObjectContainer parent = parentMap[sprite];
    double offsetX = localOffset.item1, offsetY = localOffset.item2;

    while (parent != null) {
      Tuple2<double, double> parentOffset = offsetTable[parent];

      if (parentOffset != null) {
        offsetX += parentOffset.item1;
        offsetY += parentOffset.item2;
      }

      parent = parentMap[parent];
    }

    return new Tuple2<double, double>(offsetX, offsetY);
  }

  void invalidate(Iterable<Map<String, dynamic>> data) {
    final Map<xl.Sprite, xl.DisplayObjectContainer> parentMap = <xl.Sprite, xl.DisplayObjectContainer>{};
    final Map<xl.Sprite, Tuple2<double, double>> offsetTable = <xl.Sprite, Tuple2<double, double>>{};
    final Map<NodeData<T>, Map<String, dynamic>> rootItems = <NodeData<T>, Map<String, dynamic>>{};

    data.forEach((Map<String, dynamic> entry) {
      final NodeData<T> nodeData = entry['self'];
      final NodeState state = entry['state'];
      final NodeData<T> parent = entry['parent'];
      final Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos = entry['childPos'];
      final bool isRoot = parent.data == null;
      xl.Point coords;

      print(entry);

      if (isRoot) rootItems[nodeData] = entry;

      if (!isRoot && !_sprites.containsKey(parent)) _sprites[parent] = new DebugSprite();
      if (!_sprites.containsKey(nodeData)) _sprites[nodeData] = new DebugSprite();
      if (childPos != null && !_sprites.containsKey(childPos.item1)) _sprites[childPos.item1] = new DebugSprite();

      final DebugSprite sprite = _sprites[nodeData];
      final xl.DisplayObjectContainer container = isRoot ? topContainer : _sprites[parent];
      final DebugSprite child = (childPos != null) ? _sprites[childPos.item1] : null;

      parentMap[sprite] = container;

      if (childPos != null) {
        final double dw = childPos.item5.width - 20;
        final double dh = childPos.item5.height - 20;

        child.onMouseClick.listen((_) {
          childPos.item1.node.state$ctrl.add(new NodeState(
              childPos.item5.className,
              childPos.item5.isOpen,
              childPos.item5.childIndex,
              childPos.item5.width,
              childPos.item5.height,
              childPos.item5.recursiveWidth,
              childPos.item5.recursiveHeight
          ));
        });

        offsetTable[child] = new Tuple2<double, double>(childPos.item2, childPos.item3);

        renderLoop.juggler.addTween(child, 1.3)
          ..animate.x.to(childPos.item2)
          ..animate.y.to(childPos.item3)
          ..onUpdate = () {
            child.draw(dw, dh);

            coords = child.globalToLocal(sprite.localToGlobal(new xl.Point(.0, (state.height - 20) / 2)));

            child.graphics.beginPath();
            child.graphics.moveTo(.0, -dh/2);
            child.graphics.lineTo(coords.x, coords.y);
            child.graphics.strokeColor(xl.Color.Red);
            child.graphics.closePath();
          };

        //child.setText('${nodeData.data}:${childPos.item1.data}\r${child.y}\r${state.actualHeight}\r${childPos.item5.actualHeight}');
      }

      container.addChild(sprite);
    });

    final List<Map<String, dynamic>> rootItemValues = rootItems.values.toList();

    rootItemValues.sort((Map<String, dynamic> entryA, Map<String, dynamic> entryB) => entryA['state'].childIndex.compareTo(entryB['state'].childIndex));

    double xOffset = .0;
    int childIndex = -1;

    rootItemValues.forEach((Map<String, dynamic> entry) {
      final DebugSprite sprite = _sprites[entry['self']];
      final NodeState state = entry['state'];

      if (state.childIndex != childIndex) {
        offsetTable[sprite] = new Tuple2<double, double>(xOffset + state.actualWidth / 2, state.height / 2);

        renderLoop.juggler.addTween(sprite, 1.3)
          ..animate.x.to(xOffset + state.actualWidth / 2)
          ..animate.y.to(state.height / 2);

        final double dw = state.width - 20;
        final double dh = state.height - 20;

        sprite.draw(dw, dh);

        xOffset += state.actualWidth;

        childIndex = state.childIndex;
      }
    });

    data.forEach((Map<String, dynamic> entry) {
      final NodeData<T> nodeData = entry['self'];
      final Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos = entry['childPos'];
      final Tuple2<double, double> selfOffset = calculateOffset(nodeData, parentMap, offsetTable);
      double offsetX = selfOffset.item1, offsetY = selfOffset.item2;

      if (childPos !=  null) {
        offsetX += childPos.item2 + childPos.item5.width/2;
        offsetY += childPos.item3 + childPos.item5.height/2;
      }

      screenSize$ctrl.add(new Tuple2<int, int>(offsetX.ceil(), offsetY.ceil()));
    });

    rootItemValues.forEach((Map<String, dynamic> entry) {
      final DebugSprite sprite = _sprites[entry['self']];
      final NodeState state = entry['state'];

      if (state.childIndex != childIndex) {
        final double dw = state.actualWidth - 20;
        final double dh = state.actualHeight - 20;

        childIndex = state.childIndex;

        screenSize$ctrl.add(new Tuple2<int, int>((sprite.x + dw/2).ceil(), (sprite.y + dh/2).ceil()));
      }
    });
  }
}

class DebugSprite extends xl.Sprite {

  xl.TextField textField;

  DebugSprite() {
    textField = new xl.TextField('');

    addChild(textField);
  }

  void setText(String text) {
    textField.text = text;
  }

  void draw(double w, double h) {
    graphics.clear();
    graphics.beginPath();
    graphics.rect(-w/2, -h/2, w, h);
    graphics.strokeColor(xl.Color.Red);
    graphics.fillColor(xl.Color.LightGray);
    graphics.closePath();
  }

}