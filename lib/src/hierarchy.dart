library flow.renderer;

import 'dart:async';
import 'dart:collection';

import 'package:flow/src/force_print.dart' show fprint;
import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';
import 'package:flow/src/digest.dart';
import 'package:flow/src/render/renderer.dart';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';
import 'package:quiver_hashcode/hashcode.dart' as quiver;

typedef bool NodeEqualityHandler<T>(T dataA, T dataB);
typedef int ChildCompareHandler<T>(dataA, dataB);

class Hierarchy<T> {

  final Renderer<T> renderer;

  final StreamController<Tuple3<T, T, String>> _addNodeData$ctrl = new StreamController<Tuple3<T, T, String>>();
  final StreamController<T> _removeNodeData$ctrl = new StreamController<T>();
  final StreamController<Tuple4<bool, T, T, String>> _retryNodeData$ctrl = new StreamController<Tuple4<bool, T, T, String>>();
  final StreamController<UnmodifiableListView<NodeData<T>>> _nodeData$ctrl = new StreamController<UnmodifiableListView<NodeData<T>>>.broadcast();

  final StreamController<NodeState> node$ctrl = new StreamController<NodeState>();

  NodeData<T> topLevelNodeData;
  Digest _currentDigest;
  Future<Map<int, Map<String, dynamic>>> _currentDigestFuture;

  Hierarchy(this.renderer, {NodeEqualityHandler<T> equalityHandler, ChildCompareHandler<T> childCompareHandler}) {
    if (equalityHandler == null) equalityHandler = (T dataA, T dataB) => dataA == dataB;
    if (childCompareHandler == null) childCompareHandler = (T dataA, T dataB) => 0;

    topLevelNodeData = new NodeData<T>(null, new Node(), childCompareHandler)..init();

    new rx.Observable.zip(
    [
      new rx.Observable.merge(<Stream<Tuple4<bool, T, T, String>>>[
        _addNodeData$ctrl.stream.map((Tuple3<T, T, String> tuple) => new Tuple4<bool, T, T, String>(true, tuple.item1, tuple.item2, tuple.item3)),
        _removeNodeData$ctrl.stream.map((T data) => new Tuple4<bool, T, T, String>(false, data, null, null)),
        _retryNodeData$ctrl.stream
      ]),
      _nodeData$ctrl.stream
    ], (Tuple4<bool, T, T, String> tuple, UnmodifiableListView<NodeData<T>> list) {
      final List<NodeData<T>> modifier = list.toList();

      if (tuple.item1) {
        Node node;
        NodeData<T> newNodeData;
        NodeData<T> parentNodeData;
        bool isOpen = false;

        if (tuple.item3 != null) {
          parentNodeData = list.firstWhere((NodeData<T> nodeData) => equalityHandler(nodeData.data, tuple.item3), orElse: () => null);

          if (parentNodeData == null) {
            _nodeData$ctrl.stream.take(1).listen((_) => _retryNodeData$ctrl.add(tuple));

            return list;
          }
        } else {
          node = new Node();
          newNodeData = new NodeData<T>(tuple.item2, node, childCompareHandler);

          isOpen = true;

          topLevelNodeData.addChildSink.add(newNodeData);
        }

        if (parentNodeData != null) {
          node = new Node();
          newNodeData = new NodeData<T>(tuple.item2, node, childCompareHandler);

          parentNodeData.addChildSink.add(newNodeData);
        }

        new rx.Observable.combineLatest(<Stream>[
          newNodeData.node.state$.distinct((NodeState stateA, NodeState stateB) => stateA.equals(stateB)),
          newNodeData.parent$,
          newNodeData.children$,
          rx.observable(newNodeData.childPosition$).startWith([null])
        ], (NodeState state, NodeData<T> parent, UnmodifiableListView<NodeData<T>> children, Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childPos) {
          return new Digestable(quiver.hash2(newNodeData, childPos?.item1), new RenderState<T>(newNodeData, state, parent, children, childPos));
        }).listen(_digest);

        newNodeData.init();

        node?.init();

        if (tuple.item4 != null) newNodeData.node.className$ctrl.add(tuple.item4);

        newNodeData.node.isOpen$ctrl.add(isOpen);

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

  void add(T data, {T parentData, String className}) => _addNodeData$ctrl.add(new Tuple3<T, T, String>(data, parentData, className));

  void remove(T data) => _removeNodeData$ctrl.add(data);

  void _digest(Digestable digestable) {
    if (_currentDigest == null) _currentDigest = new Digest();

    _currentDigest.append(digestable);

    if (_currentDigestFuture == null) {
      final Completer<Map<int, RenderState<T>>> completer = new Completer<Map<int, RenderState<T>>>();

      new Timer(const Duration(milliseconds: 30), () {
        completer.complete(_currentDigest.flush());

        _currentDigest = null;
        _currentDigestFuture = null;
      });

      _currentDigestFuture = completer.future.then(_render);
    }
  }

  void _render(Map<int, RenderState<T>> data) {
    print('NEW LOOP');
    renderer.invalidate(data.values);
  }

}