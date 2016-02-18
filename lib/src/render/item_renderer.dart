library flow.render.item_renderer;

import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:rxdart/rxdart.dart' as rx;

import 'package:flow/src/hierarchy.dart';

class ItemRendererState<T> {

  final T data;
  final double w, h;
  final double connectorFromX, connectorFromY;
  final double connectorToX, connectorToY;

  ItemRendererState(
    this.data,
    this.w,
    this.h,
    this.connectorFromX,
    this.connectorFromY,
    this.connectorToX,
    this.connectorToY
  );

  bool equals(ItemRendererState<T> other, NodeEqualityHandler<T> equalityHandler) => (
    equalityHandler(other.data, data) &&
    other.w == w &&
    other.h == h &&
    other.connectorFromX == connectorFromX &&
    other.connectorFromY == connectorFromY &&
    other.connectorToX == connectorToX &&
    other.connectorToY == connectorToY
  );

}

abstract class ItemRenderer<T> {

  Sink<T> get data$sink => _data$ctrl.sink;
  Sink<Tuple4<double, double, double, double>> get connector$sink => _connector$ctrl.sink;
  Sink<Tuple2<double, double>> get size$sink => _size$ctrl.sink;

  Stream<bool> get renderingRequired$ => _renderingRequired$ctrl.stream;

  final StreamController<T> _data$ctrl = new StreamController<T>();
  final StreamController<Tuple4<double, double, double, double>> _connector$ctrl = new StreamController<Tuple4<double, double, double, double>>();
  final StreamController<Tuple2<double, double>> _size$ctrl = new StreamController<Tuple2<double, double>>();
  final StreamController<bool> _renderingRequired$ctrl = new StreamController<bool>();

  int renderCount = 0;

  void init(NodeEqualityHandler<T> equalityHandler) {
    new rx.Observable<ItemRendererState<T>>.combineLatest(<Stream>[
      _data$ctrl.stream,
      rx.observable(_connector$ctrl.stream).startWith(const <Tuple4<double, double, double, double>>[const Tuple4<double, double, double, double>(.0, .0, .0, .0)]),
      _size$ctrl.stream
    ], (T data, Tuple4<double, double, double, double> connector, Tuple2<double, double> size) => new ItemRendererState<T>(data, size.item1, size.item2, connector.item1, connector.item2, connector.item3, connector.item4))
      .distinct((ItemRendererState<T> stateA, ItemRendererState<T> stateB) => stateB.equals(stateA, equalityHandler))
      .listen((ItemRendererState<T> state) {
        update(state);

        _renderingRequired$ctrl.add(true);
      });
  }

  void update(ItemRendererState<T> state);
}