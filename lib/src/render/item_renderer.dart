library flow.render.item_renderer;

import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:rxdart/rxdart.dart' as rx;

import 'package:flow/src/hierarchy.dart' show NodeEqualityHandler, HierarchyOrientation;
import 'package:flow/src/render/style_client.dart';

class ItemRendererState<T> {

  final T data;
  final double w, h;
  final double connectorFromX, connectorFromY;
  final double connectorToX, connectorToY;
  final HierarchyOrientation orientation;
  final String className;
  final int childCount;
  final bool isOpen;

  ItemRendererState(
    this.data,
    this.w,
    this.h,
    this.connectorFromX,
    this.connectorFromY,
    this.connectorToX,
    this.connectorToY,
    this.orientation,
    this.className,
    this.childCount,
    this.isOpen
  );

  bool equals(ItemRendererState<T> other, NodeEqualityHandler<T> equalityHandler) => (
    other.orientation == orientation &&
    equalityHandler(other.data, data) &&
    other.w == w &&
    other.h == h &&
    other.connectorFromX == connectorFromX &&
    other.connectorFromY == connectorFromY &&
    other.connectorToX == connectorToX &&
    other.connectorToY == connectorToY &&
    other.className == className &&
    other.childCount == childCount &&
    other.isOpen == isOpen
  );

  String toString() => <String, dynamic>{
    'data': data,
    'w': w,
    'h': h,
    'connectorFromX': connectorFromX,
    'connectorFromY': connectorFromY,
    'connectorToX': connectorToX,
    'connectorToY': connectorToY,
    'orientation': orientation,
    'className': className,
    'childCount': childCount,
    'isOpen': isOpen
  }.toString();

}

abstract class ItemRenderer<T> {

  bool _isInitialized = false;
  StyleClient styleClient;

  bool get isInitialized => _isInitialized;
  Stream<Tuple2<double, double>> get resize$ => _resize$ctrl.stream;
  Stream<String> get className$ => _className$ctrl.stream;
  Stream<bool> get isOpen$ => _isOpen$ctrl.stream;
  Stream<HierarchyOrientation> get orientation$ => _orientation$ctrl.stream;
  Stream<double> get animation$ => _animation$ctrl.stream;

  Sink<T> get data$sink => _data$ctrl.sink;
  Sink<HierarchyOrientation> get orientation$sink => _orientation$ctrl.sink;
  Sink<String> get className$sink => _className$ctrl.sink;
  Sink<Tuple4<double, double, double, double>> get connector$sink => _connector$ctrl.sink;
  Sink<Tuple2<double, double>> get size$sink => _size$ctrl.sink;
  Sink<Tuple2<double, double>> get resize$sink => _resize$ctrl.sink;
  Sink<bool> get isOpen$sink => _isOpen$ctrl.sink;
  Sink<int> get childCount$sink => _childCount$ctrl.sink;
  Sink<double> get animation$sink => _animation$ctrl.sink;

  Stream<bool> get renderingRequired$ => _renderingRequired$ctrl.stream;

  final StreamController<T> _data$ctrl = new StreamController<T>();
  final StreamController<Tuple4<double, double, double, double>> _connector$ctrl = new StreamController<Tuple4<double, double, double, double>>();
  final StreamController<Tuple2<double, double>> _size$ctrl = new StreamController<Tuple2<double, double>>.broadcast();
  final StreamController<Tuple2<double, double>> _resize$ctrl = new StreamController<Tuple2<double, double>>.broadcast();
  final StreamController<bool> _renderingRequired$ctrl = new StreamController<bool>();
  final StreamController<HierarchyOrientation> _orientation$ctrl = new StreamController<HierarchyOrientation>.broadcast();
  final StreamController<String> _className$ctrl = new StreamController<String>.broadcast();
  final StreamController<bool> _isOpen$ctrl = new StreamController<bool>.broadcast();
  final StreamController<int> _childCount$ctrl = new StreamController<int>.broadcast();
  final StreamController<double> _animation$ctrl = new StreamController<double>.broadcast();

  int renderCount = 0;

  Tuple2<double, double> getDefaultSize(HierarchyOrientation orientation);

  void init(NodeEqualityHandler<T> equalityHandler, StyleClient styleClient) {
    this.styleClient = styleClient;

    new rx.Observable<ItemRendererState<T>>.combineLatest(<Stream>[
      _data$ctrl.stream,
      rx.observable(_connector$ctrl.stream).startWith(const <Tuple4<double, double, double, double>>[const Tuple4<double, double, double, double>(.0, .0, .0, .0)]),
      _size$ctrl.stream,
      _orientation$ctrl.stream,
      _className$ctrl.stream,
      rx.observable(_childCount$ctrl.stream).startWith(const <int>[0]),
      _isOpen$ctrl.stream
    ], (T data, Tuple4<double, double, double, double> connector, Tuple2<double, double> size, HierarchyOrientation orientation, String className, int childCount, bool isOpen) => new ItemRendererState<T>(data, size.item1, size.item2, connector.item1, connector.item2, connector.item3, connector.item4, orientation, className, childCount, isOpen))
      .distinct((ItemRendererState<T> stateA, ItemRendererState<T> stateB) => stateB.equals(stateA, equalityHandler))
      .listen((ItemRendererState<T> state) {
        update(state);
        connect(state);

        _renderingRequired$ctrl.add(true);
      });

    animation$.listen((double value) {
      updateOnAnimation(value);
    });

    _isInitialized = true;
  }

  void update(ItemRendererState<T> state);

  void updateOnAnimation(double value);

  void connect(ItemRendererState<T> state);
}