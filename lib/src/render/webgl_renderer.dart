library flow.render.webgl_renderer;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:html' as html;

import 'package:stagexl/stagexl.dart' as xl;
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:flow/src/render/renderer.dart';
import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/render/webgl_item_renderer.dart';
import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';
import 'package:flow/src/digest.dart';

import 'package:flow/src/force_print.dart';

const double PADDING = 10.0;

class WebglRenderer<T> extends Renderer {

  final StreamController<Map<ItemRenderer<T>, xl.DisplayObjectContainer>> _parentMap$ctrl = new StreamController<Map<ItemRenderer<T>, xl.DisplayObjectContainer>>();
  final StreamController<Map<ItemRenderer<T>, Tuple2<double, double>>> _offsetTable$ctrl = new StreamController<Map<ItemRenderer<T>, Tuple2<double, double>>>();
  final StreamController<Map<NodeData<T>, RenderState<T>>> _rootItems$ctrl = new StreamController<Map<NodeData<T>, RenderState<T>>>();

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

    stage.renderMode = xl.StageRenderMode.ONCE;

    stage.addChild(topContainer);

    renderLoop.addStage(stage);

    rx.observable(screenSize$ctrl.stream)
      .distinct((Tuple2<int, int> prev, Tuple2<int, int> next) => prev == next)
      .listen((Tuple2<int, int> tuple) {
        canvas.width = math.max(tuple.item1, canvas.width);
        canvas.height = math.max(tuple.item2, canvas.height);
      });

    new rx.Observable<Tuple4<Iterable<RenderState<T>>, Map<ItemRenderer<T>, xl.DisplayObjectContainer>, Map<ItemRenderer<T>, Tuple2<double, double>>, Map<NodeData<T>, RenderState<T>>>>.combineLatest(<Stream>[state$, _parentMap$ctrl.stream, _offsetTable$ctrl.stream, _rootItems$ctrl.stream],
      (Iterable<RenderState<T>> data, Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap, Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable, Map<NodeData<T>, RenderState<T>> rootItems) {
        return new Tuple4<Iterable<RenderState<T>>, Map<ItemRenderer<T>, xl.DisplayObjectContainer>, Map<ItemRenderer<T>, Tuple2<double, double>>, Map<NodeData<T>, RenderState<T>>>(data, parentMap, offsetTable, rootItems);
      }).listen(_invalidate);

    _parentMap$ctrl.add(<ItemRenderer<T>, xl.DisplayObjectContainer>{});
    _offsetTable$ctrl.add(<ItemRenderer<T>, Tuple2<double, double>>{});
    _rootItems$ctrl.add(<NodeData<T>, RenderState<T>>{});
  }

  ItemRenderer<T> newDefaultItemRendererInstance() => new WebglItemRenderer();

  Tuple2<double, double> calculateOffset(NodeData<T> nodeData, Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap, Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable) {
    final ItemRenderer<T> sprite = nodeData.itemRenderer;
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

  void scheduleRender() {
    stage.renderMode = xl.StageRenderMode.ONCE;
  }

  void _invalidate(Tuple4<Iterable<RenderState<T>>, Map<ItemRenderer<T>, xl.DisplayObjectContainer>, Map<ItemRenderer<T>, Tuple2<double, double>>, Map<NodeData<T>, RenderState<T>>> tuple) {
    final Iterable<RenderState<T>> data = tuple.item1;
    final Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap = tuple.item2;
    final Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable = tuple.item3;
    final Map<NodeData<T>, RenderState<T>> rootItems = tuple.item4;

    data.forEach((RenderState<T> entry) {
      final Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos = entry.childData;
      final bool isRoot = entry.parentNodeData.data == null;

      if (isRoot) rootItems[entry.nodeData] = entry;

      final WebglItemRenderer<T> sprite = entry.nodeData.itemRenderer;
      final xl.DisplayObjectContainer container = isRoot ? topContainer : entry.parentNodeData.itemRenderer;
      final WebglItemRenderer<T> child = (childPos != null) ? childPos.item1.itemRenderer : null;

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

        renderLoop.juggler.addTween(child, .3)
          ..animate.x.to(childPos.item2)
          ..animate.y.to(childPos.item3)
          ..onUpdate = () {
            final xl.Point pos = child.globalToLocal(sprite.localToGlobal(new xl.Point(.0, (entry.state.height - PADDING) / 2)));

            child.data$sink.add(childPos.item1.data);
            child.size$sink.add(new Tuple2<double, double>(dw, dh));
            child.connector$sink.add(new Tuple4<double, double, double, double>(.0, -dh/2, pos.x, pos.y));
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
      final WebglItemRenderer<T> sprite = entry.nodeData.itemRenderer;

      if (entry.state.childIndex != childIndex) {
        offsetTable[sprite] = new Tuple2<double, double>(xOffset + entry.state.actualWidth / 2, entry.state.height / 2);

        renderLoop.juggler.addTween(sprite, .3)
          ..animate.x.to(xOffset + entry.state.actualWidth / 2)
          ..animate.y.to(entry.state.height / 2);

        final double dw = entry.state.width - PADDING;
        final double dh = entry.state.height - PADDING;

        sprite.data$sink.add(entry.nodeData.data);
        sprite.size$sink.add(new Tuple2<double, double>(dw, dh));

        xOffset += entry.state.actualWidth;

        childIndex = entry.state.childIndex;
      }
    });

    data.forEach((RenderState<T> entry) {
      final Tuple2<double, double> selfOffset = calculateOffset(entry.nodeData, parentMap, offsetTable);
      double offsetX = selfOffset.item1, offsetY = selfOffset.item2;

      if (entry.childData !=  null) {
        offsetX += entry.childData.item2 + entry.childData.item5.actualWidth/2;
        offsetY += entry.childData.item3 + entry.childData.item5.actualHeight/2;
      }

      screenSize$ctrl.add(new Tuple2<int, int>(offsetX.ceil(), offsetY.ceil()));
    });
  }
}