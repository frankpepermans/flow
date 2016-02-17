library flow.display.node;

import 'dart:async';
import 'dart:math' as math;

import 'package:stream_channel/stream_channel.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart' show Tuple2;

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

  Sink<String> get className$ctrl => _classNameController;
  Sink<bool> get isOpen$ctrl => _isOpenController;
  Sink<int> get childIndex$ctrl => _childIndexController;
  Sink<double> get recursiveWidth$ctrl => _recursiveWidthController;
  Sink<double> get recursiveHeight$ctrl => _recursiveHeightController;

  Stream<NodeState> state$;
  Sink<NodeState> state$ctrl;
  StreamController<Tuple2<double, double>> size$ctrl;

  StreamController<String> _classNameController = new StreamController<String>();
  StreamController<bool> _isOpenController = new StreamController<bool>();
  StreamController<int> _childIndexController = new StreamController<int>();
  StreamController<double> _widthController = new StreamController<double>();
  StreamController<double> _heightController = new StreamController<double>();
  StreamController<double> _recursiveWidthController = new StreamController<double>();
  StreamController<double> _recursiveHeightController = new StreamController<double>();

  Node() {
    StreamChannelController<NodeState> controller = new StreamChannelController<NodeState>(allowForeignErrors: false);

    state$ = controller.foreign.stream.asBroadcastStream();
    state$ctrl = controller.local.sink;
    size$ctrl = new StreamController<Tuple2<double, double>>();

    final rx.Observable<NodeState> combinedState$ = new rx.Observable<NodeState>.combineLatest(
      <Stream>[_classNameController.stream, _isOpenController.stream, _childIndexController.stream, _widthController.stream, _heightController.stream, _recursiveWidthController.stream, _recursiveHeightController.stream],
      (String className, bool isOpen, int childIndex, double width, double height, double recursiveWidth, double recursiveHeight)
        => new NodeState(className, isOpen, childIndex, width, height, recursiveWidth, recursiveHeight));

    combinedState$.pipe(controller.local.sink);

    _classNameController.add('node');
    _isOpenController.add(false);
    _childIndexController.add(0);
    _widthController.add(.0);
    _heightController.add(.0);
    _recursiveWidthController.add(.0);
    _recursiveHeightController.add(.0);
  }

  void init() {
    final math.Random R = new math.Random();

    if (GEN == null) GEN = _gen();

    _widthController.add(40.0);
    _heightController.add(200.0);

    // mock async content loaded
    /*new Timer.periodic(new Duration(milliseconds: 1000), (_) {
      _widthController.add(R.nextDouble() * 200.0 + 50.0);
      _heightController.add(R.nextDouble() * 200.0 + 50.0);
    });*/
  }

  static Iterable<double> GEN;
  static int GEN_I = 0;

  void render(Tuple2<NodeState, Tuple2<double, double>> data) {

  }

  Iterable<double> _gen() sync* {
    double s = 100.0;

    while (true) {
      s += 10.0;

      if (s > 200.0) s = 100.0;

      yield s;
    }
  }

}

