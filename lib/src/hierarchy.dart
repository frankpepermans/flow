library flow.renderer;

import 'dart:async';
import 'dart:collection';

import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';
import 'package:flow/src/digest.dart';
import 'package:flow/src/render/renderer.dart';
import 'package:flow/src/render/item_renderer.dart';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';
import 'package:quiver_hashcode/hashcode.dart' as quiver;

typedef bool NodeEqualityHandler<T>(T dataA, T dataB);
typedef int ChildCompareHandler<T>(dataA, dataB);

enum HierarchyOrientation {
  HORIZONTAL,
  VERTICAL
}

class Hierarchy<T> {

  final Renderer<T> renderer;
  final HierarchyOrientation orientation;

  final StreamController<Tuple4<T, T, String, ItemRenderer<T>>> _addNodeData$ctrl = new StreamController<Tuple4<T, T, String, ItemRenderer<T>>>();
  final StreamController<T> _removeNodeData$ctrl = new StreamController<T>();
  final StreamController<Tuple5<bool, T, T, String, ItemRenderer<T>>> _retryNodeData$ctrl = new StreamController<Tuple5<bool, T, T, String, ItemRenderer<T>>>();
  final StreamController<UnmodifiableListView<NodeData<T>>> _nodeData$ctrl = new StreamController<UnmodifiableListView<NodeData<T>>>.broadcast();

  final StreamController<NodeState> node$ctrl = new StreamController<NodeState>();

  NodeData<T> topLevelNodeData;
  Digest _currentDigest;

  Hierarchy(this.renderer, this.orientation, {NodeEqualityHandler<T> equalityHandler, ChildCompareHandler<T> childCompareHandler}) {
    renderer.orientation = orientation;

    if (equalityHandler == null) equalityHandler = (T dataA, T dataB) => dataA == dataB;
    if (childCompareHandler == null) childCompareHandler = (T dataA, T dataB) => 0;

    topLevelNodeData = new NodeData<T>(null, new Node(), childCompareHandler, null, orientation, renderer.nodeStyle)..init();

    new rx.Observable.zip(
    [
      new rx.Observable.merge(<Stream<Tuple5<bool, T, T, String, ItemRenderer<T>>>>[
        _addNodeData$ctrl.stream.map((Tuple4<T, T, String, ItemRenderer<T>> tuple) => new Tuple5<bool, T, T, String, ItemRenderer<T>>(true, tuple.item1, tuple.item2, tuple.item3, tuple.item4)),
        _removeNodeData$ctrl.stream.map((T data) => new Tuple5<bool, T, T, String, ItemRenderer<T>>(false, data, null, null, null)),
        _retryNodeData$ctrl.stream
      ]),
      _nodeData$ctrl.stream
    ], (Tuple5<bool, T, T, String, ItemRenderer<T>> tuple, UnmodifiableListView<NodeData<T>> list) {
      final List<NodeData<T>> modifier = list.toList();

      if (tuple.item1) {
        Node node;
        NodeData<T> newNodeData;
        NodeData<T> parentNodeData;
        ItemRenderer<T> itemRenderer;
        bool isOpen = false;

        if (tuple.item3 != null) {
          parentNodeData = list.firstWhere((NodeData<T> nodeData) => equalityHandler(nodeData.data, tuple.item3), orElse: () => null);

          if (parentNodeData == null) {
            _nodeData$ctrl.stream.take(1).listen((_) => _retryNodeData$ctrl.add(tuple));

            return list;
          }
        } else {
          itemRenderer = (tuple.item5 != null) ? tuple.item5 : renderer.newDefaultItemRendererInstance();
          node = new Node();
          newNodeData = new NodeData<T>(tuple.item2, node, childCompareHandler, itemRenderer, orientation, renderer.nodeStyle);

          itemRenderer.init(equalityHandler, orientation, renderer.nodeStyle);
          itemRenderer.renderingRequired$.listen((_) => renderer.materializeStage$sink.add(true));

          isOpen = true;

          topLevelNodeData.addChildSink.add(newNodeData);
        }

        if (parentNodeData != null) {
          itemRenderer = (tuple.item5 != null) ? tuple.item5 : renderer.newDefaultItemRendererInstance();
          node = new Node();
          newNodeData = new NodeData<T>(tuple.item2, node, childCompareHandler, itemRenderer, orientation, renderer.nodeStyle);

          itemRenderer.init(equalityHandler, orientation, renderer.nodeStyle);
          itemRenderer.renderingRequired$.listen((_) => renderer.materializeStage$sink.add(true));

          parentNodeData.addChildSink.add(newNodeData);
        }

        new rx.Observable.combineLatest(<Stream>[
          newNodeData.node.state$.distinct((NodeState stateA, NodeState stateB) => stateA.equals(stateB)),
          newNodeData.parent$,
          newNodeData.children$,
          rx.observable(newNodeData.childPosition$).startWith([null])
        ], (NodeState state, NodeData<T> parent, UnmodifiableListView<NodeData<T>> children, Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos) {
          return new Digestable(quiver.hash2(newNodeData, childPos?.item1), new RenderState<T>(newNodeData, state, parent, children, childPos));
        })
          .flatMap((Digestable digestable) => new Stream.fromFuture(_digest(digestable)))
          .listen(renderer.state$sink.add);

        if (tuple.item4 != null) newNodeData.node.className$sink.add(tuple.item4);

        newNodeData.node.isOpen$sink.add(isOpen);

        node?.init();
        newNodeData.init();

        modifier.add(newNodeData);
      } else {
        final NodeData<T> oldNodeData = list.firstWhere((NodeData<T> nodeData) => equalityHandler(nodeData.data, tuple.item2), orElse: () => null);

        if (oldNodeData == null) {
          _nodeData$ctrl.stream.take(1).listen((_) => _retryNodeData$ctrl.add(tuple));

          return list;
        }

        list.forEach((NodeData<T> nodeData) => nodeData.removeChildSink.add(oldNodeData));

        modifier.remove(oldNodeData);
      }

      return new UnmodifiableListView<NodeData<T>>(modifier);
    }).listen(_nodeData$ctrl.add);

    _nodeData$ctrl.add(new UnmodifiableListView<NodeData<T>>(const []));
  }

  void add(T data, {T parentData, String className, ItemRenderer<T> itemRenderer}) => _addNodeData$ctrl.add(new Tuple4<T, T, String, ItemRenderer<T>>(data, parentData, className, itemRenderer));

  void remove(T data) => _removeNodeData$ctrl.add(data);

  Future<Iterable<RenderState<T>>> _digest(Digestable digestable) {
    if (_currentDigest == null) _currentDigest = new Digest();

    _currentDigest.append(digestable);

    final Completer<Iterable<RenderState<T>>> completer = new Completer<Iterable<RenderState<T>>>();

    scheduleMicrotask(() {
      completer.complete(new UnmodifiableListView(_currentDigest.flush().values.toList(growable: false)));

      //_currentDigest = null;
    });

    return completer.future;
  }
}

class NodeStyle {

  final Tuple4<double, double, double, double> margin;
  final Tuple4<double, double, double, double> padding;
  final int background, border;
  final double borderSize;

  final int connectorBackground;
  final double connectorWidth, connectorHeight;

  NodeStyle(this.margin, this.padding, this.background, this.border, this.borderSize, this.connectorBackground, this.connectorWidth, this.connectorHeight);

}