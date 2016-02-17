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
import 'package:flow/src/digest.dart';

import 'package:flow/src/force_print.dart';

const double PADDING = 10.0;

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

  void invalidate(Iterable<RenderState<T>> data) {
    final Map<xl.Sprite, xl.DisplayObjectContainer> parentMap = <xl.Sprite, xl.DisplayObjectContainer>{};
    final Map<xl.Sprite, Tuple2<double, double>> offsetTable = <xl.Sprite, Tuple2<double, double>>{};
    final Map<NodeData<T>, RenderState<T>> rootItems = <NodeData<T>, RenderState<T>>{};

    data.forEach((RenderState<T> entry) {
      final Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos = entry.childData;
      final bool isRoot = entry.parentNodeData.data == null;
      xl.Point coords;

      fprint(entry);

      if (isRoot) rootItems[entry.nodeData] = entry;

      if (!isRoot && !_sprites.containsKey(entry.parentNodeData)) _sprites[entry.parentNodeData] = new DebugSprite();
      if (!_sprites.containsKey(entry.nodeData)) _sprites[entry.nodeData] = new DebugSprite();
      if (childPos != null && !_sprites.containsKey(childPos.item1)) _sprites[childPos.item1] = new DebugSprite();

      final DebugSprite sprite = _sprites[entry.nodeData];
      final xl.DisplayObjectContainer container = isRoot ? topContainer : _sprites[entry.parentNodeData];
      final DebugSprite child = (childPos != null) ? _sprites[childPos.item1] : null;

      parentMap[sprite] = container;

      if (childPos != null) {
        final double dw = childPos.item5.width - PADDING;
        final double dh = childPos.item5.height - PADDING;

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

            coords = child.globalToLocal(sprite.localToGlobal(new xl.Point(.0, (entry.state.height - PADDING) / 2)));

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

    final List<RenderState<T>> rootItemValues = rootItems.values.toList();

    rootItemValues.sort((RenderState<T> entryA, RenderState<T> entryB) => entryA.state.childIndex.compareTo(entryB.state.childIndex));

    double xOffset = .0;
    int childIndex = -1;

    rootItemValues.forEach((RenderState<T> entry) {
      final DebugSprite sprite = _sprites[entry.nodeData];

      if (entry.state.childIndex != childIndex) {
        offsetTable[sprite] = new Tuple2<double, double>(xOffset + entry.state.actualWidth / 2, entry.state.height / 2);

        renderLoop.juggler.addTween(sprite, 1.3)
          ..animate.x.to(xOffset + entry.state.actualWidth / 2)
          ..animate.y.to(entry.state.height / 2);

        final double dw = entry.state.width - PADDING;
        final double dh = entry.state.height - PADDING;

        sprite.draw(dw, dh);

        xOffset += entry.state.actualWidth;

        childIndex = entry.state.childIndex;
      }
    });

    data.forEach((RenderState<T> entry) {
      final Tuple2<double, double> selfOffset = calculateOffset(entry.nodeData, parentMap, offsetTable);
      double offsetX = selfOffset.item1, offsetY = selfOffset.item2;

      if (entry.childData !=  null) {
        offsetX += entry.childData.item2 + entry.childData.item5.width/2;
        offsetY += entry.childData.item3 + entry.childData.item5.height/2;
      }

      screenSize$ctrl.add(new Tuple2<int, int>(offsetX.ceil(), offsetY.ceil()));
    });

    rootItemValues.forEach((RenderState<T> entry) {
      final DebugSprite sprite = _sprites[entry.nodeData];

      if (entry.state.childIndex != childIndex) {
        final double dw = entry.state.actualWidth - PADDING;
        final double dh = entry.state.actualHeight - PADDING;

        childIndex = entry.state.childIndex;

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