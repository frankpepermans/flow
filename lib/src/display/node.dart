library flow.display.node;

import 'dart:async';
import 'dart:math' as math;

import 'package:rxdart/rxdart.dart' as rx;

class NodeState {

  final String className;
  final bool isOpen;
  final int childIndex;
  final double width, height, recursiveWidth, recursiveHeight;

  double get actualWidth => math.max(width, recursiveWidth);
  double get actualHeight => math.max(height, recursiveHeight);

  NodeState(
    this.className,
    this.isOpen,
    this.childIndex,
    this.width,
    this.height,
    this.recursiveWidth,
    this.recursiveHeight
  );

  bool equals(NodeState otherState) => (
    otherState.className == className &&
    otherState.isOpen == isOpen &&
    otherState.childIndex == childIndex &&
    otherState.width == width &&
    otherState.height == height &&
    otherState.recursiveWidth == recursiveWidth &&
    otherState.recursiveHeight == recursiveHeight
  );

  String toString() => <String, dynamic>{
    'className': className,
    'isOpen': isOpen,
    'childIndex': childIndex,
    'width': width,
    'height': height,
    'recursiveWidth': recursiveWidth,
    'recursiveHeight': recursiveHeight
  }.toString();
}

class Node {

  Sink<String> get className$sink => _classNameController.sink;
  Sink<bool> get isOpen$sink => _isOpenController.sink;
  Sink<int> get childIndex$sink => _childIndexController.sink;
  Sink<double> get width$sink => _widthController.sink;
  Sink<double> get height$sink => _heightController.sink;
  Sink<double> get recursiveWidth$sink => _recursiveWidthController.sink;
  Sink<double> get recursiveHeight$sink => _recursiveHeightController.sink;

  rx.Observable<NodeState> get state$ => _state$;

  final StreamController<String> _classNameController = new StreamController<String>();
  final StreamController<bool> _isOpenController = new StreamController<bool>();
  final StreamController<int> _childIndexController = new StreamController<int>();
  final StreamController<double> _widthController = new StreamController<double>();
  final StreamController<double> _heightController = new StreamController<double>();
  final StreamController<double> _recursiveWidthController = new StreamController<double>();
  final StreamController<double> _recursiveHeightController = new StreamController<double>();

  rx.Observable<NodeState> _state$;

  Node() {
    _state$ = new rx.Observable<NodeState>.combineLatest(
      <Stream>[_classNameController.stream, _isOpenController.stream, _childIndexController.stream, _widthController.stream, _heightController.stream, _recursiveWidthController.stream, _recursiveHeightController.stream],
      (String className, bool isOpen, int childIndex, double width, double height, double recursiveWidth, double recursiveHeight)
        => new NodeState(className, isOpen, childIndex, width, height, recursiveWidth, recursiveHeight), asBroadcastStream: true)
      .debounce(const Duration(milliseconds: 20));
  }

  void init() {
    _childIndexController.add(0);
    _recursiveWidthController.add(.0);
    _recursiveHeightController.add(.0);

    _widthController.add(28.0);
    _heightController.add(138.0);
  }
}

