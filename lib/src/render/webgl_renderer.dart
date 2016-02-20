library flow.render.webgl_renderer;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:html' as html;

import 'package:stagexl/stagexl.dart' as xl;
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:flow/src/render/web_renderer.dart';
import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/render/webgl_item_renderer.dart';
import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';
import 'package:flow/src/digest.dart';

class WebglRenderer<T> extends WebRenderer<T> {

  final StreamController<Map<ItemRenderer<T>, xl.DisplayObjectContainer>> _parentMap$ctrl = new StreamController<Map<ItemRenderer<T>, xl.DisplayObjectContainer>>();
  final StreamController<Map<ItemRenderer<T>, Tuple2<double, double>>> _offsetTable$ctrl = new StreamController<Map<ItemRenderer<T>, Tuple2<double, double>>>();
  final StreamController<Map<NodeData<T>, RenderState<T>>> _rootItems$ctrl = new StreamController<Map<NodeData<T>, RenderState<T>>>();

  html.CanvasElement canvas;
  html.CanvasRenderingContext2D canvasRenderingContext2D;
  html.CanvasRenderingContext canvasRenderingContext3D;
  xl.Stage stage;
  xl.Sprite topContainer;
  StreamController<Tuple2<int, int>> screenSize$ctrl;

  WebglRenderer(String selector) : super() {
    canvas = html.querySelector(selector);

    html.window.onScroll.map((_) => true).listen(materializeStage$sink.add);

    canvasRenderingContext2D = canvas.context2D;
    canvasRenderingContext3D = canvas.getContext3d();

    print('hasRenderingContext2D: ${(canvasRenderingContext2D != null)}');
    print('hasRenderingContext3D: ${(canvasRenderingContext3D != null)}');

    stage = new xl.Stage(canvas,
      options: xl.Stage.defaultOptions.clone()
        ..antialias = true
        ..renderEngine = xl.RenderEngine.WebGL
        ..inputEventMode = xl.InputEventMode.MouseAndTouch
      )
      ..scaleMode = xl.StageScaleMode.NO_SCALE
      ..align = xl.StageAlign.TOP_LEFT
      ..backgroundColor = xl.Color.White
      ..renderMode = xl.StageRenderMode.ONCE;
    topContainer = new xl.Sprite();
    screenSize$ctrl = new StreamController<Tuple2<int, int>>();

    stage.addChild(topContainer);

    rx.observable(screenSize$ctrl.stream)
      .distinct((Tuple2<int, int> prev, Tuple2<int, int> next) => prev == next)
      .listen((Tuple2<int, int> tuple) {
        canvas.width = math.max(canvas.parent.clientWidth, tuple.item1);
        canvas.height = math.max(canvas.parent.clientHeight, tuple.item2);

        materializeStage$sink.add(true);
      });

    new rx.Observable<Tuple4<Iterable<RenderState<T>>, Map<ItemRenderer<T>, xl.DisplayObjectContainer>, Map<ItemRenderer<T>, Tuple2<double, double>>, Map<NodeData<T>, RenderState<T>>>>.combineLatest(<Stream>[state$, _parentMap$ctrl.stream, _offsetTable$ctrl.stream, _rootItems$ctrl.stream],
      (Iterable<RenderState<T>> data, Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap, Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable, Map<NodeData<T>, RenderState<T>> rootItems) {
        return new Tuple4<Iterable<RenderState<T>>, Map<ItemRenderer<T>, xl.DisplayObjectContainer>, Map<ItemRenderer<T>, Tuple2<double, double>>, Map<NodeData<T>, RenderState<T>>>(data, parentMap, offsetTable, rootItems);
      })
        .debounce(const Duration(milliseconds: 20))
        .map(_invalidate)
        .flatMapLatest((List<xl.Tween> animations) => rx.observable(animationStream).take(1).flatMapLatest((_) => new Stream<xl.Tween>.fromIterable(animations)))
        .listen((xl.Tween animation) {
          stage.juggler.add(animation);

          materializeStage$sink.add(true);
        });

    _parentMap$ctrl.add(<ItemRenderer<T>, xl.DisplayObjectContainer>{});
    _offsetTable$ctrl.add(<ItemRenderer<T>, Tuple2<double, double>>{});
    _rootItems$ctrl.add(<NodeData<T>, RenderState<T>>{});

    new xl.RenderLoop()..addStage(stage);

    materializeStage$
      .listen((_) {
        stage.renderMode = xl.StageRenderMode.ONCE;
      });
  }

  ItemRenderer<T> newDefaultItemRendererInstance() => new WebglItemRenderer();

  Tuple2<double, double> calculateOffset(NodeData<T> nodeData, Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap, Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable) {
    final ItemRenderer<T> sprite = nodeData.itemRenderer;
    final Tuple2<double, double> localOffset = offsetTable[sprite];

    if (localOffset == null) return const Tuple2<double, double>(.0, .0);

    xl.DisplayObjectContainer parent = parentMap[sprite];
    double offsetX = localOffset.item1, offsetY = localOffset.item2;

    while (true) {
      Tuple2<double, double> parentOffset = offsetTable[parent];

      if (parentOffset != null) {
        offsetX += parentOffset.item1;
        offsetY += parentOffset.item2;
      }

      if (parent == topContainer) break;

      parent = parentMap[parent];

      if (parent == null) parent = topContainer;
    }

    return new Tuple2<double, double>(offsetX, offsetY);
  }

  List<xl.Tween> _invalidate(Tuple4<Iterable<RenderState<T>>, Map<ItemRenderer<T>, xl.DisplayObjectContainer>, Map<ItemRenderer<T>, Tuple2<double, double>>, Map<NodeData<T>, RenderState<T>>> tuple) {
    final Iterable<RenderState<T>> data = tuple.item1;
    final Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap = tuple.item2;
    final Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable = tuple.item3;
    final Map<NodeData<T>, RenderState<T>> rootItems = tuple.item4;
    final List<xl.Tween> tweens = <xl.Tween>[];
    int dw = 0, dh = 0;

    data.forEach((RenderState<T> entry) {
      final Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos = entry.childData;
      final bool isRoot = entry.parentNodeData.data == null;

      if (isRoot) rootItems[entry.nodeData] = entry;

      final WebglItemRenderer<T> sprite = entry.nodeData.itemRenderer;
      final xl.DisplayObjectContainer container = isRoot ? topContainer : entry.parentNodeData.itemRenderer;
      final WebglItemRenderer<T> child = (childPos != null) ? childPos.item1.itemRenderer : null;

      parentMap[sprite] = container;

      if (childPos != null) {
        final double dw = childPos.item5.width;
        final double dh = childPos.item5.height;

        offsetTable[child] = new Tuple2<double, double>(childPos.item2, childPos.item3);

        tweens.add(new xl.Tween(child, .3)
          ..animate.x.to(childPos.item2)
          ..animate.y.to(childPos.item3)
          ..onUpdate = () {
            xl.Point pos;

            child.data$sink.add(childPos.item1.data);
            child.size$sink.add(new Tuple2<double, double>(dw, dh));

            if (orientation == HierarchyOrientation.VERTICAL) {
              pos = child.globalToLocal(sprite.localToGlobal(new xl.Point(.0, entry.state.height / 2)));

              child.connector$sink.add(new Tuple4<double, double, double, double>(.0, -dh/2, pos.x, pos.y));
            } else {
              pos = child.globalToLocal(sprite.localToGlobal(new xl.Point(entry.state.width / 2, .0)));

              child.connector$sink.add(new Tuple4<double, double, double, double>(-dw/2, .0, pos.x, pos.y));
            }
          });

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
      final double borderSize = nodeStyle.borderSize * 2;

      if (entry.state.childIndex != childIndex) {
        if (orientation == HierarchyOrientation.VERTICAL) {
          offsetTable[sprite] = new Tuple2<double, double>(xOffset + entry.state.actualWidth / 2 + borderSize, entry.state.height / 2 + borderSize);

          tweens.add(new xl.Tween(sprite, .3)
            ..animate.x.to(xOffset + entry.state.actualWidth / 2 + borderSize)
            ..animate.y.to(entry.state.height / 2 + borderSize));
        } else {
          offsetTable[sprite] = new Tuple2<double, double>(entry.state.width / 2 + borderSize, xOffset + entry.state.actualHeight / 2 + borderSize);

          tweens.add(new xl.Tween(sprite, .3)
            ..animate.x.to(entry.state.width / 2 + borderSize)
            ..animate.y.to(xOffset + entry.state.actualHeight / 2 + borderSize));
        }

        final double dw = entry.state.width;
        final double dh = entry.state.height;

        sprite.data$sink.add(entry.nodeData.data);
        sprite.size$sink.add(new Tuple2<double, double>(dw, dh));

        xOffset += entry.state.actualWidth;

        childIndex = entry.state.childIndex;
      }
    });

    data.where((RenderState<T> entry) => entry.childData !=  null).forEach((RenderState<T> entry) {
      final Tuple2<double, double> selfOffset = calculateOffset(entry.nodeData, parentMap, offsetTable);
      final double borderSize = nodeStyle.borderSize * 2;
      double offsetX = selfOffset.item1, offsetY = selfOffset.item2;

      offsetX += entry.childData.item2 + entry.childData.item5.actualWidth/2;
      offsetY += entry.childData.item3 + entry.childData.item5.actualHeight/2;

      final dw0 = (offsetX + borderSize).ceil(), dh0 = (offsetY + borderSize).ceil();

      dw = (dw0 > dw) ? dw0 : dw;
      dh = (dh0 > dh) ? dh0 : dh;
    });

    screenSize$ctrl.add(new Tuple2<int, int>(dw, dh));

    return tweens;
  }
}