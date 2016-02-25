library flow.node_data;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flow/src/display/node.dart';
import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/render/style_client.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeStyle;

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

import 'package:flow/src/force_print.dart';

typedef int ChildCompareHandler<T>(dataA, dataB);

enum NodeDataChildOperation {
  ADD,
  REMOVE
}

class NodeData<T> {

  Sink<NodeData> get addChildSink => _addChild$ctrl.sink;
  Sink<NodeData> get removeChildSink => _removeChild$ctrl.sink;
  Sink<HierarchyOrientation> get orientationSink => _orientation$ctrl.sink;

  Stream<NodeData> get parent$ => _parent$ctrl.stream;
  Stream<Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>> get childPosition$ => _childPosition$ctrl.stream;
  Stream<UnmodifiableListView<NodeData<T>>> get children$ => _children$ctrl.stream;

  final StreamController<Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>> _childPosition$ctrl = new StreamController<Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>>();
  final StreamController<NodeData<T>> _addChild$ctrl = new StreamController<NodeData<T>>();
  final StreamController<NodeData<T>> _removeChild$ctrl = new StreamController<NodeData<T>>();
  final StreamController<Tuple2<NodeData<T>, NodeDataChildOperation>> _retryChild$ctrl = new StreamController<Tuple2<NodeData<T>, NodeDataChildOperation>>();
  final StreamController<NodeData<T>> _parent$ctrl = new StreamController<NodeData<T>>.broadcast();
  final StreamController<UnmodifiableListView<NodeData<T>>> _children$ctrl = new StreamController<UnmodifiableListView<NodeData<T>>>.broadcast();
  final StreamController<HierarchyOrientation> _orientation$ctrl = new StreamController<HierarchyOrientation>.broadcast();

  final ItemRenderer<T> itemRenderer;
  final T data;
  final Node node;
  final ChildCompareHandler childCompareHandler;
  final StyleClient styleClient;

  HierarchyOrientation _orientation;

  NodeData(this.data, this.node, this.childCompareHandler, this.itemRenderer, this.styleClient) {
    _orientation$ctrl.stream.listen((HierarchyOrientation orientation) {
      _orientation = orientation;

      node.recursiveWidth$sink.add(.0);
      node.recursiveHeight$sink.add(.0);
    });
  }

  void init() {
    if (itemRenderer != null) {
      itemRenderer.resize$.listen((Tuple2<double, double> tuple) {
        node.width$sink.add(tuple.item1);
        node.height$sink.add(tuple.item2);
      });

      itemRenderer.isOpen$.listen((bool isOpen) => node.isOpen$sink.add(isOpen));
    }

    new rx.Observable<UnmodifiableListView<NodeData<T>>>.zip(
      <Stream>[
        new rx.Observable.merge(<Stream<Tuple2<NodeData<T>, NodeDataChildOperation>>>[
          _addChild$ctrl.stream.map((NodeData<T> nodeData) => new Tuple2<NodeData<T>, NodeDataChildOperation>(nodeData, NodeDataChildOperation.ADD)),
          _removeChild$ctrl.stream.map((NodeData<T> nodeData) => new Tuple2<NodeData<T>, NodeDataChildOperation>(nodeData, NodeDataChildOperation.REMOVE)),
          _retryChild$ctrl.stream
        ]),
        children$
      ], (Tuple2<NodeData<T>, NodeDataChildOperation> tuple, UnmodifiableListView<NodeData<T>> children) {
        final List<NodeData<T>> list = children.toList();

        switch (tuple.item2) {
          case NodeDataChildOperation.ADD:
            list.add(tuple.item1);

            new rx.Observable.combineLatest(<Stream>[
              node.state$.distinct((NodeState stateA, NodeState stateB) => stateA.equals(stateB)),
              tuple.item1.node.state$.distinct((NodeState stateA, NodeState stateB) => stateA.equals(stateB)),
              rx.observable(children$).flatMapLatest((UnmodifiableListView<NodeData<T>> children) {
                final int len = children.length;
                final List<NodeState> childStates = new List<NodeState>(len);
                final StreamController<UnmodifiableListView<NodeState>> childStates$ = new StreamController<UnmodifiableListView<NodeState>>();
                final List<bool> triggerMap = new List<bool>.generate(len, (_) => false);

                for (int i=0; i<len; i++) {
                  NodeData<T> nodeData = children.elementAt(i);

                  nodeData.node.state$.distinct((NodeState stateA, NodeState stateB) => stateA.equals(stateB)).listen((NodeState childState) {
                    childStates[i] = childState;
                    triggerMap[i] = true;

                    if (!triggerMap.contains(false) && childState.childIndex < len) childStates$.add(new UnmodifiableListView<NodeState>(childStates));
                  });
                }

                return childStates$.stream;
              }),
              rx.observable(_orientation$ctrl.stream).startWith(<HierarchyOrientation>[_orientation])
            ], (NodeState state, NodeState childState, UnmodifiableListView<NodeState> childrenStates, HierarchyOrientation orientation) {
              final NodeStyle nodeStyle = styleClient.getNodeStyle(state.className);
              Tuple2<double, double> dwh = new Tuple2<double, double>(.0, .0);
              double x = .0, y = .0;

              if (state.isOpen) {
                if (orientation == HierarchyOrientation.VERTICAL) {
                  childrenStates.forEach((NodeState entryNodeState) => dwh = new Tuple2<double, double>(dwh.item1 + entryNodeState.actualWidth + nodeStyle.margin.item2 + nodeStyle.margin.item4, math.max(dwh.item2, entryNodeState.height)));

                  x = -dwh.item1/2 + childState.actualWidth/2;
                  y = state.height/2 + dwh.item2/2 + nodeStyle.margin.item1 + nodeStyle.margin.item3;

                  for (int i=0; i<childState.childIndex; i++) x += childrenStates[i].actualWidth + nodeStyle.margin.item2 + nodeStyle.margin.item4;

                  x += nodeStyle.margin.item4;
                } else {
                  childrenStates.forEach((NodeState entryNodeState) => dwh = new Tuple2<double, double>(math.max(dwh.item1, entryNodeState.width), dwh.item2 + entryNodeState.actualHeight + nodeStyle.margin.item1 + nodeStyle.margin.item3));

                  x = state.width/2 + dwh.item1/2 + nodeStyle.margin.item2 + nodeStyle.margin.item4;
                  y = -dwh.item2/2 + childState.actualHeight/2;

                  for (int i=0; i<childState.childIndex; i++) y += childrenStates[i].actualHeight + nodeStyle.margin.item1 + nodeStyle.margin.item3;

                  y += nodeStyle.margin.item1;
                }
              }

              return new Tuple7<NodeData<T>, double, double, Tuple2<double, double>, UnmodifiableListView<NodeState>, NodeState, HierarchyOrientation>(tuple.item1, x, y, dwh, childrenStates, childState, orientation);
            }).takeUntil(tuple.item1.parent$.where((NodeData nodeData) => nodeData == null)).listen((Tuple7<NodeData<T>, double, double, Tuple2<double, double>, UnmodifiableListView<NodeState>, NodeState, HierarchyOrientation> tuple) {
              final NodeStyle nodeStyle = styleClient.getNodeStyle(tuple.item6.className);

              _childPosition$ctrl.add(new Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>(tuple.item1, tuple.item2, tuple.item3, tuple.item5, tuple.item6));

              if (tuple.item7 == HierarchyOrientation.VERTICAL) {
                node.recursiveWidth$sink.add(tuple.item4.item1 - nodeStyle.margin.item2 - nodeStyle.margin.item4);

                tuple.item1.node.recursiveHeight$sink.add(tuple.item4.item2);
              } else {
                node.recursiveHeight$sink.add(tuple.item4.item2 - nodeStyle.margin.item1 - nodeStyle.margin.item3);

                tuple.item1.node.recursiveWidth$sink.add(tuple.item4.item1);
              }
            });
            break;
          case NodeDataChildOperation.REMOVE:
            if (!list.remove(tuple.item1)) {
              _children$ctrl.stream.take(1).listen((_) => _retryChild$ctrl.add(tuple));

              return null;
            } else {
              tuple.item1._parent$ctrl.add(null);
            }
            break;
        }

        return new UnmodifiableListView<NodeData<T>>(list..sort((NodeData<T> dataA, NodeData<T> dataB) => childCompareHandler(dataA.data, dataB.data)));
    }).listen((UnmodifiableListView<NodeData<T>> list) {
      if (list != null) {
        final int len = list.length;
        NodeData<T> nodeData;

        for (int i=0; i<len; i++) {
          nodeData = list.elementAt(i);

          nodeData._parent$ctrl.add(this);
          nodeData.node.childIndex$sink.add(i);
        }

        _children$ctrl.add(list);
      }
    });

    _children$ctrl.add(new UnmodifiableListView<NodeData<T>>(const []));
  }

  String toString() => data.toString();

}