library flow.render.stage_xl_renderer;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as html;

import 'package:stagexl/stagexl.dart' as xl;
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:flow/src/render/web_renderer.dart';
import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/render/stage_xl_item_renderer.dart';
import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';
import 'package:flow/src/digest.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeStyle;
import 'package:flow/src/render/animation.dart';

class StageXLRenderer<T> extends WebRenderer<T> {

  static const int ANIMATION_TIME_MS = 300;

  final StreamController<Map<ItemRenderer<T>, xl.DisplayObjectContainer>> _parentMap$ctrl = new StreamController<Map<ItemRenderer<T>, xl.DisplayObjectContainer>>();
  final StreamController<Map<ItemRenderer<T>, Tuple2<double, double>>> _offsetTable$ctrl = new StreamController<Map<ItemRenderer<T>, Tuple2<double, double>>>();
  final StreamController<Map<NodeData<T>, RenderState<T>>> _rootItems$ctrl = new StreamController<Map<NodeData<T>, RenderState<T>>>();

  html.DivElement container;
  html.CanvasElement canvas;
  xl.Stage stage;
  xl.Sprite topContainer;
  StreamController<Tuple2<int, int>> screenSize$ctrl;

  StageXLRenderer(String containerSelector, String canvasSelector) : super() {
    container = html.querySelector(containerSelector);
    canvas = html.querySelector(canvasSelector);

    //canvas.context2D;

    container.onScroll.map((_) => true).listen(materializeStage$sink.add);

    stage = new xl.Stage(canvas,
      options: xl.Stage.defaultOptions.clone()
        ..antialias = true
        ..renderEngine = xl.RenderEngine.WebGL
        ..inputEventMode = xl.InputEventMode.MouseAndTouch
      )
      ..scaleMode = xl.StageScaleMode.NO_SCALE
      ..backgroundColor = 0xffeeeeee
      ..align = xl.StageAlign.TOP_LEFT
      ..renderMode = xl.StageRenderMode.ONCE;
    topContainer = new xl.Sprite();
    screenSize$ctrl = new StreamController<Tuple2<int, int>>();

    stage.addChild(topContainer);

    rx.observable(screenSize$ctrl.stream)
      .distinct((Tuple2<int, int> prev, Tuple2<int, int> next) => prev == next)
      .listen((Tuple2<int, int> tuple) {
        if (tuple.item1 < canvas.width) {
          new Timer.periodic(const Duration(milliseconds: 30), (Timer timer) {
            if (stage.renderMode == xl.StageRenderMode.STOP) {
              canvas.width = stage.sourceWidth = tuple.item1;
              canvas.style.width = '${tuple.item1}px';
              materializeStage$sink.add(true);

              timer.cancel();
            }
          });
        } else {
          canvas.width = stage.sourceWidth = tuple.item1;
          canvas.style.width = '${tuple.item1}px';
          materializeStage$sink.add(true);
        }

        if (tuple.item2 < canvas.height) {
          new Timer.periodic(const Duration(milliseconds: 30), (Timer timer) {
            if (stage.renderMode == xl.StageRenderMode.STOP) {
              canvas.height = stage.sourceHeight = tuple.item2;
              canvas.style.height = '${tuple.item2}px';
              materializeStage$sink.add(true);

              timer.cancel();
            }
          });
        } else {
          canvas.height = stage.sourceHeight = tuple.item2;
          canvas.style.height = '${tuple.item2}px';
          materializeStage$sink.add(true);
        }
      });

    new rx.Observable<_InvalidationTuple<T>>.combineLatest(<Stream>[state$, _parentMap$ctrl.stream, _offsetTable$ctrl.stream, _rootItems$ctrl.stream, orientation$],
        (
          Iterable<RenderState<T>> data,
          Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap,
          Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable,
          Map<NodeData<T>, RenderState<T>> rootItems,
          HierarchyOrientation orientation
        ) => new _InvalidationTuple<T>(data, parentMap, offsetTable, rootItems, orientation))
          .debounce(const Duration(milliseconds: 40))
          .map(_invalidate)
          .listen((List<List<xl.Tween>> animations) {
            animations.forEach((List<xl.Tween> animation) {
              stage.juggler.removeTweens(animation.first.tweenObject);

              stage.juggler.addChain(animation);
            });

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

  ItemRenderer<T> newDefaultItemRendererInstance() => new StageXLItemRenderer();

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

  void _onTweenUpdate(_InvalidationTuple<T> tuple, RenderState<T> entry, StageXLItemRenderer<T> sprite, StageXLItemRenderer<T> child, NodeStyle nodeStyle, double dw, double dh) {
    xl.Point pos;

    if (tuple.orientation == HierarchyOrientation.VERTICAL) {
      pos = child.globalToLocal(sprite.localToGlobal(new xl.Point(.0, entry.state.height / 2)));

      if (pos.x > .0) pos.x -= entry.state.width/3;
      else if (pos.x < .0) pos.x += entry.state.width/3;

      child.connector$sink.add(new Tuple4<double, double, double, double>(.0, -dh/2 - nodeStyle.borderSize, pos.x, pos.y + nodeStyle.borderSize));
    } else {
      pos = child.globalToLocal(sprite.localToGlobal(new xl.Point(entry.state.width / 2, .0)));

      if (pos.y > .0) pos.y -= entry.state.height/3;
      else if (pos.y < .0) pos.y += entry.state.height/3;

      child.connector$sink.add(new Tuple4<double, double, double, double>(-dw/2 - nodeStyle.borderSize, .0, pos.x + nodeStyle.borderSize, pos.y));
    }
  }

  List<List<xl.Tween>> _invalidate(_InvalidationTuple<T> tuple) {
    final List<List<xl.Tween>> tweens = <List<xl.Tween>>[];
    xl.Tween tweenA, tweenB;
    int dw = 0, dh = 0;

    tuple.data.forEach((RenderState<T> entry) {
      final Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos = entry.childData;
      final bool isRoot = entry.parentNodeData.data == null;

      if (isRoot) tuple.rootItems[entry.nodeData] = entry;

      final StageXLItemRenderer<T> sprite = entry.nodeData.itemRenderer;
      final xl.DisplayObjectContainer container = isRoot ? topContainer : entry.parentNodeData.itemRenderer;
      final StageXLItemRenderer<T> child = (childPos != null) ? childPos.item1.itemRenderer : null;

      tuple.parentMap[sprite] = container;

      if (childPos != null) {
        final NodeStyle nodeStyle = styleClient.getNodeStyle(entry.childData.item5.className);
        final double dw = childPos.item5.width;
        final double dh = childPos.item5.height;
        final bool isChildShownAnimation = entry.state.isOpen && !sprite.contains(child);
        final bool isChildHiddenAnimation = !entry.state.isOpen && sprite.contains(child);
        double currentAnimationValue = -1.0;

        tuple.offsetTable[child] = new Tuple2<double, double>(childPos.item2, childPos.item3);

        child.data$sink.add(childPos.item1.data);
        child.size$sink.add(new Tuple2<double, double>(dw, dh));

        if (tuple.orientation == HierarchyOrientation.VERTICAL) {
          tweenA = new xl.Tween(child, ANIMATION_TIME_MS / 1500)
            ..animate.x.to(childPos.item2)
            ..onUpdate = () => _onTweenUpdate(tuple, entry, sprite, child, nodeStyle, dw, dh);

          tweenB = new xl.Tween(child, ANIMATION_TIME_MS / 1500)
            ..animate.y.to(childPos.item3)
            ..onUpdate = () => _onTweenUpdate(tuple, entry, sprite, child, nodeStyle, dw, dh);
        } else {
          tweenA = new xl.Tween(child, ANIMATION_TIME_MS / 1500)
            ..animate.y.to(childPos.item3)
            ..onUpdate = () => _onTweenUpdate(tuple, entry, sprite, child, nodeStyle, dw, dh);

          tweenB = new xl.Tween(child, ANIMATION_TIME_MS / 1500)
            ..animate.x.to(childPos.item2)
            ..onUpdate = () => _onTweenUpdate(tuple, entry, sprite, child, nodeStyle, dw, dh);
        }

        if (child.animation != null && !child.animation.isComplete) {
          child.animation.stop();

          currentAnimationValue = child.animation.currentValue;
        }

        if (isChildShownAnimation) {
          final xl.Tween tweenC = tweenB;
          tweenB = tweenA;
          tweenA = tweenC;

          currentAnimationValue = (currentAnimationValue == -1.0) ? .0 : currentAnimationValue;

          tweenA.delay = childPos.item5.childIndex * ANIMATION_TIME_MS / 3000;

          child.animation = new Animation(stage.juggler, AnimationType.CHILDREN_OPEN, currentAnimationValue, 1.0, ANIMATION_TIME_MS / 500, xl.Transition.easeOutSine)..start();

          if (!sprite.contains(child)) sprite.addChild(child);
        } else if (isChildHiddenAnimation) {
          currentAnimationValue = (currentAnimationValue == -1.0) ? 1.0 : currentAnimationValue;

          tweenA.delay = childPos.item5.childIndex * ANIMATION_TIME_MS / 3000;

          tweenB.onComplete = () {
            if (sprite.contains(child)) sprite.removeChild(child);
          };

          child.animation = new Animation(stage.juggler, AnimationType.CHILDREN_CLOSE, currentAnimationValue, .0, ANIMATION_TIME_MS / 500, xl.Transition.easeOutSine)..start();
        } else {
          currentAnimationValue = (currentAnimationValue == -1.0) ? .0 : currentAnimationValue;

          child.animation = new Animation(stage.juggler, AnimationType.REPOSITION, currentAnimationValue, 1.0, ANIMATION_TIME_MS / 1000, xl.Transition.easeOutSine)..start();
        }

        tweens.add(<xl.Tween>[tweenA, tweenB].where((xl.Tween tween) => tween != null).toList(growable: false));
      }

      if (isRoot && !container.contains(sprite)) container.addChild(sprite);
    });

    final List<RenderState<T>> rootItemValues = tuple.rootItems.values.toList();

    rootItemValues.sort((RenderState<T> entryA, RenderState<T> entryB) => entryA.state.childIndex.compareTo(entryB.state.childIndex));

    double offsetX = .0, offsetY = .0;
    int childIndex = -1;

    rootItemValues.forEach((RenderState<T> entry) {
      final NodeStyle nodeStyle = styleClient.getNodeStyle(entry.state.className);
      final StageXLItemRenderer<T> sprite = entry.nodeData.itemRenderer;
      final double borderSize = nodeStyle.borderSize * 2;
      xl.Tween tween;
      double tx, ty;

      if (entry.state.childIndex != childIndex) {
        if (tuple.orientation == HierarchyOrientation.VERTICAL) {
          tx = offsetX + entry.state.actualWidth / 2 + borderSize;
          ty = entry.state.height / 2 + borderSize;

          offsetX += entry.state.actualWidth + nodeStyle.margin.item4 + nodeStyle.margin.item2;
        } else {
          tx = entry.state.width / 2 + borderSize;
          ty = offsetY + entry.state.actualHeight / 2 + borderSize;

          offsetY += entry.state.actualHeight + nodeStyle.margin.item1 + nodeStyle.margin.item3;
        }

        tuple.offsetTable[sprite] = new Tuple2<double, double>(tx, ty);

        tween = new xl.Tween(sprite, ANIMATION_TIME_MS / 1000)
          ..animate.x.to(tx)
          ..animate.y.to(ty);

        tweens.add(<xl.Tween>[tween]);

        sprite.data$sink.add(entry.nodeData.data);
        sprite.size$sink.add(new Tuple2<double, double>(entry.state.width, entry.state.height));

        childIndex = entry.state.childIndex;

        final dw0 = (offsetX + borderSize).ceil(), dh0 = (offsetY + borderSize).ceil();

        dw = (dw0 > dw) ? dw0 : dw;
        dh = (dh0 > dh) ? dh0 : dh;
      }
    });

    tuple.data.where((RenderState<T> entry) => entry.childData !=  null).forEach((RenderState<T> entry) {
      final NodeStyle nodeStyle = styleClient.getNodeStyle(entry.childData.item5.className);
      final Tuple2<double, double> selfOffset = calculateOffset(entry.nodeData, tuple.parentMap, tuple.offsetTable);
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

class _InvalidationTuple<T> {

  final Iterable<RenderState<T>> data;
  final Map<ItemRenderer<T>, xl.DisplayObjectContainer> parentMap;
  final Map<ItemRenderer<T>, Tuple2<double, double>> offsetTable;
  final Map<NodeData<T>, RenderState<T>> rootItems;
  final HierarchyOrientation orientation;

  _InvalidationTuple(
    this.data,
    this.parentMap,
    this.offsetTable,
    this.rootItems,
    this.orientation
  );
}