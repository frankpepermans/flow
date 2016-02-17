library flow.node_data;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flow/src/force_print.dart' show fprint;
import 'package:flow/src/display/node.dart';

import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

typedef int ChildCompareHandler<T>(dataA, dataB);

enum NodeDataChildOperation {
  ADD,
  REMOVE
}

class NodeData<T> {

  Sink<NodeData> get addChildSink => _addChild$ctrl.sink;
  Sink<NodeData> get removeChildSink => _removeChild$ctrl.sink;
  Stream<NodeData> get parent$ => _parent$ctrl.stream;
  Stream<Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>> get childPosition$ => _childPosition$ctrl.stream;
  Stream<UnmodifiableListView<NodeData<T>>> get children$ => _children$ctrl.stream;

  final StreamController<Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>> _childPosition$ctrl = new StreamController<Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>>();
  final StreamController<NodeData<T>> _addChild$ctrl = new StreamController<NodeData<T>>();
  final StreamController<NodeData<T>> _removeChild$ctrl = new StreamController<NodeData<T>>();
  final StreamController<Tuple2<NodeData<T>, NodeDataChildOperation>> _retryChild$ctrl = new StreamController<Tuple2<NodeData<T>, NodeDataChildOperation>>();
  final StreamController<NodeData<T>> _parent$ctrl = new StreamController<NodeData<T>>.broadcast();
  final StreamController<UnmodifiableListView<NodeData<T>>> _children$ctrl = new StreamController<UnmodifiableListView<NodeData<T>>>.broadcast();

  final T data;
  final Node node;
  final ChildCompareHandler childCompareHandler;

  NodeData(this.data, this.node, this.childCompareHandler);

  void init() {
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

                for (int i=0; i<len; i++) {
                  NodeData<T> nodeData = children.elementAt(i);

                  nodeData.node.state$.distinct((NodeState stateA, NodeState stateB) => stateA.equals(stateB)).listen((NodeState childState) {
                    childStates[i] = childState;

                    childStates$.add(new UnmodifiableListView<NodeState>(childStates));
                  });
                }

                return childStates$.stream;
              })
            ], (NodeState state, NodeState childState, UnmodifiableListView<NodeState> childrenStates) {
              final Tuple2<double, double> dwh = childrenStates.fold(new Tuple2<double, double>(.0, state.actualHeight), (Tuple2<double, double> prevValue, NodeState currValue) => new Tuple2(prevValue.item1 + currValue.actualWidth, math.max(prevValue.item2, currValue.actualHeight)));
              final double y = dwh.item2;
              double x = -dwh.item1/2 + childState.actualWidth/2;

              for (int i=0; i<childState.childIndex; i++) x += childrenStates[i].actualWidth;

              return new Tuple6<NodeData<T>, double, double, Tuple2<double, double>, UnmodifiableListView<NodeState>, NodeState>(tuple.item1, x, y, dwh, childrenStates, childState);
            }).takeUntil(tuple.item1.parent$.where((NodeData nodeData) => nodeData == null)).listen((Tuple6<NodeData<T>, double, double, Tuple2<double, double>, UnmodifiableListView<NodeState>, NodeState> tuple) {
              _childPosition$ctrl.add(new Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState>(tuple.item1, tuple.item2, tuple.item3, tuple.item5, tuple.item6));

              node.recursiveWidth$ctrl.add(tuple.item4.item1);
              //node.recursiveHeight$ctrl.add(tuple.item4.item2);

              tuple.item1.node.recursiveHeight$ctrl.add(tuple.item4.item2);
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
          nodeData.node.childIndex$ctrl.add(i);
        }

        _children$ctrl.add(list);
      }
    });

    _parent$ctrl.add(null);
    _children$ctrl.add(new UnmodifiableListView<NodeData<T>>(const []));
  }

  String toString() => data.toString();

}