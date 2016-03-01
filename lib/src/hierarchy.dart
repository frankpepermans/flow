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

import 'package:flow/src/force_print.dart';

typedef bool NodeEqualityHandler<T>(T dataA, T dataB);
typedef int ChildCompareHandler<T>(dataA, dataB);

enum HierarchyOrientation {
  HORIZONTAL,
  VERTICAL
}

class Hierarchy<T> {

  final Renderer<T> renderer;

  HierarchyOrientation get orientation => _orientation;

  void set orientation(HierarchyOrientation orientation) => _orientation$ctrl.add(orientation);

  final StreamController<Tuple4<T, T, String, Function>> _addNodeData$ctrl = new StreamController<Tuple4<T, T, String, Function>>();
  final StreamController<T> _removeNodeData$ctrl = new StreamController<T>();
  final StreamController<Tuple5<bool, T, T, String, Function>> _retryNodeData$ctrl = new StreamController<Tuple5<bool, T, T, String, Function>>();
  final StreamController<UnmodifiableListView<NodeData<T>>> _nodeData$ctrl = new StreamController<UnmodifiableListView<NodeData<T>>>.broadcast();
  final StreamController<HierarchyOrientation> _orientation$ctrl = new StreamController<HierarchyOrientation>.broadcast();

  final StreamController<NodeState> node$ctrl = new StreamController<NodeState>();

  NodeData<T> topLevelNodeData;
  Digest<T> _currentDigest;
  HierarchyOrientation _orientation;

  Hierarchy(this.renderer, {NodeEqualityHandler<T> equalityHandler, ChildCompareHandler<T> childCompareHandler}) {
    if (equalityHandler == null) equalityHandler = (T dataA, T dataB) => dataA == dataB;
    if (childCompareHandler == null) childCompareHandler = (T dataA, T dataB) => 0;

    topLevelNodeData = new NodeData<T>(null, new Node(), childCompareHandler, null, renderer.styleClient)
      ..init();

    _orientation$ctrl.stream.distinct((HierarchyOrientation oA, HierarchyOrientation oB) => oA == oB).listen((HierarchyOrientation orientation) {
      _orientation = orientation;

      renderer.orientation$sink.add(orientation);
      topLevelNodeData.orientationSink.add(orientation);
    });

    new rx.Observable.zip(
    [
      new rx.Observable.merge(<Stream<Tuple5<bool, T, T, String, Function>>>[
        _addNodeData$ctrl.stream.map((Tuple4<T, T, String, Function> tuple) => new Tuple5<bool, T, T, String, Function>(true, tuple.item1, tuple.item2, tuple.item3, tuple.item4)),
        _removeNodeData$ctrl.stream.map((T data) => new Tuple5<bool, T, T, String, Function>(false, data, null, null, null)),
        _retryNodeData$ctrl.stream
      ]),
      _nodeData$ctrl.stream
    ], (Tuple5<bool, T, T, String, Function> tuple, UnmodifiableListView<NodeData<T>> list) {
      final List<NodeData<T>> modifier = list.toList();
      final String className = (tuple.item4 != null) ? tuple.item4 : 'flow-node';

      if (tuple.item1) {
        Node node;
        NodeData<T> newNodeData;
        NodeData<T> parentNodeData;
        ItemRenderer<T> itemRenderer;

        if (tuple.item3 != null) {
          parentNodeData = list.firstWhere((NodeData<T> nodeData) => equalityHandler(nodeData.data, tuple.item3), orElse: () => null);

          if (parentNodeData == null) {
            _nodeData$ctrl.stream.take(1).listen((_) => _retryNodeData$ctrl.add(tuple));

            return list;
          }
        } else {
          itemRenderer = (tuple.item5 != null) ? tuple.item5(tuple.item2) as ItemRenderer<T> : renderer.newDefaultItemRendererInstance();
          node = new Node();
          newNodeData = new NodeData<T>(tuple.item2, node, childCompareHandler, itemRenderer, renderer.styleClient);

          newNodeData.node.isOpen$sink.add(true);

          itemRenderer.init(equalityHandler, renderer.styleClient);

          itemRenderer.className$.listen((String className) {
            node.className$sink.add(className);
          });

          itemRenderer.className$sink.add(className);

          rx.observable(_orientation$ctrl.stream)
            .startWith(<HierarchyOrientation>[_orientation])
            .distinct((HierarchyOrientation oA, HierarchyOrientation oB) => oA == oB)
            .listen((HierarchyOrientation orientation) {
              newNodeData.orientationSink.add(orientation);

              itemRenderer.orientation$sink.add(orientation);
            });

          itemRenderer.renderingRequired$.listen((_) => renderer.materializeStage$sink.add(true));

          topLevelNodeData.addChildSink.add(newNodeData);
        }

        if (parentNodeData != null) {
          itemRenderer = (tuple.item5 != null) ? tuple.item5(tuple.item2) as ItemRenderer<T> : renderer.newDefaultItemRendererInstance();
          node = new Node();
          newNodeData = new NodeData<T>(tuple.item2, node, childCompareHandler, itemRenderer, renderer.styleClient);

          newNodeData.node.isOpen$sink.add(false);

          itemRenderer.init(equalityHandler, renderer.styleClient);

          itemRenderer.className$.listen((String className) {
            node.className$sink.add(className);
          });

          itemRenderer.className$sink.add(className);

          rx.observable(_orientation$ctrl.stream)
            .startWith(<HierarchyOrientation>[_orientation])
            .distinct((HierarchyOrientation oA, HierarchyOrientation oB) => oA == oB)
            .listen((HierarchyOrientation orientation) {
              newNodeData.orientationSink.add(orientation);

              itemRenderer.orientation$sink.add(orientation);
            });

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
          .map((Digestable<T> digestable) => _digest(digestable))
          .listen(renderer.state$sink.add);

        newNodeData.node.className$sink.add(className);

        node?.init(itemRenderer?.getDefaultSize(_orientation));
        newNodeData.init();

        itemRenderer?.orientation$sink?.add(_orientation);

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

  void add(T data, {T parentData, String className, ItemRenderer<T> itemRenderer(T data)}) => _addNodeData$ctrl.add(new Tuple4<T, T, String, Function>(data, parentData, className, itemRenderer));

  void remove(T data) => _removeNodeData$ctrl.add(data);

  UnmodifiableListView<RenderState<T>> _digest(Digestable<T> digestable) {
    if (_currentDigest == null) _currentDigest = new Digest();

    _currentDigest.append(digestable);

    return new UnmodifiableListView<RenderState<T>>(_currentDigest.flush().values.toList(growable: false));
  }
}

class NodeStyle {

  final Tuple4<double, double, double, double> margin;
  final Tuple4<double, double, double, double> padding;
  final int background, border;
  final double borderSize;

  final int connectorBackground;
  final double connectorWidth, connectorHeight, connectorRadius;

  NodeStyle(this.margin, this.padding, this.background, this.border, this.borderSize, this.connectorRadius, this.connectorBackground, this.connectorWidth, this.connectorHeight);

}