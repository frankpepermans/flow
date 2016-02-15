library flow.renderer;

import 'dart:async';
import 'dart:collection';

import 'package:flow/src/force_print.dart' show fprint;
import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

typedef bool NodeEqualityHandler<T>(T dataA, T dataB);
typedef int ChildCompareHandler<T>(dataA, dataB);

class Renderer<T> {

  final StreamController<Tuple3<T, T, String>> _addNodeData$ctrl = new StreamController<Tuple3<T, T, String>>();
  final StreamController<T> _removeNodeData$ctrl = new StreamController<T>();
  final StreamController<Tuple4<bool, T, T, String>> _retryNodeData$ctrl = new StreamController<Tuple4<bool, T, T, String>>();
  final StreamController<UnmodifiableListView<NodeData<T>>> _nodeData$ctrl = new StreamController<UnmodifiableListView<NodeData<T>>>.broadcast();

  final StreamController<NodeState> node$ctrl = new StreamController<NodeState>();

  NodeData<T> topLevelNodeData;

  Renderer({NodeEqualityHandler<T> equalityHandler, ChildCompareHandler<T> childCompareHandler}) {
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
          newNodeData = new NodeData<T>(tuple.item2, new Node(), childCompareHandler);

          isOpen = true;

          topLevelNodeData.addChildSink.add(newNodeData);
        }

        if (parentNodeData != null) {
          newNodeData = new NodeData<T>(tuple.item2, new Node(), childCompareHandler);

          parentNodeData.addChildSink.add(newNodeData);
        }

        new rx.Observable.combineLatest(<Stream>[
          newNodeData.node.state$.distinct((NodeState stateA, NodeState stateB) => stateA.equals(stateB)),
          newNodeData.parent$,
          newNodeData.children$
        ], (NodeState state, NodeData<T> parent, UnmodifiableListView<NodeData<T>> children) {
          return {
            'self': newNodeData,
            'state': state,
            'parent': parent,
            'children': children
          };
        }).listen(fprint);

        newNodeData.childPosition$.listen(fprint);

        newNodeData.init();

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

}