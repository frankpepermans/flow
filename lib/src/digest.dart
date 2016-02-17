library flow.digest;

import 'dart:collection';

import 'package:flow/src/node_data.dart';
import 'package:flow/src/display/node.dart';

import 'package:tuple/tuple.dart';

class RenderState<T> {

  final NodeData<T> nodeData, parentNodeData;
  final NodeState state;
  final UnmodifiableListView<NodeData<T>> children;
  final Tuple5<NodeData<T>, double, double, UnmodifiableListView<NodeState>, NodeState> childData;

  RenderState(
      this.nodeData,
      this.state,
      this.parentNodeData,
      this.children,
      this.childData);

  String toString()  => <String, dynamic>{
    'nodeData': nodeData,
    'parentNodeData': parentNodeData,
    'state': state,
    'childData': childData,
    'children': children
  }.toString();
}

class Digestable<T> {

  final int key;
  final RenderState<T> data;

  Digestable(this.key, this.data);

}

class Digest<T> {

  final Map<int, RenderState<T>> _digestables = <int, RenderState<T>>{};

  Digest();

  void append(Digestable digestable) {
    _digestables[digestable.key] = digestable.data;
  }

  Map<int, RenderState<T>> flush() => _digestables;

}