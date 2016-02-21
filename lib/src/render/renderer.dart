library flow.render.renderer;

import 'dart:async';

import 'package:tuple/tuple.dart';

import 'package:flow/src/digest.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeStyle;
import 'package:flow/src/render/item_renderer.dart';

export 'package:flow/src/hierarchy.dart' show HierarchyOrientation;

abstract class Renderer<T> {

  Stream<num> get animationStream;

  NodeStyle nodeStyle;

  Sink<Iterable<RenderState<T>>> get state$sink => _state$ctrl.sink;
  Stream<Iterable<RenderState<T>>> get state$ => _state$ctrl.stream;

  Sink<bool> get materializeStage$sink => _materializeStage$ctrl.sink;
  Stream<bool> get materializeStage$ => _materializeStage$ctrl.stream;

  Sink<HierarchyOrientation> get orientation$sink => _orientation$ctrl.sink;
  Stream<HierarchyOrientation> get orientation$ => _orientation$ctrl.stream;

  final StreamController<Iterable<RenderState<T>>> _state$ctrl = new StreamController<Iterable<RenderState<T>>>();
  final StreamController<bool> _materializeStage$ctrl = new StreamController<bool>();
  final StreamController<HierarchyOrientation> _orientation$ctrl = new StreamController<HierarchyOrientation>();

  ItemRenderer<T> newDefaultItemRendererInstance();

  Tuple4<double, double, double, double> getNodeMargin();
  Tuple4<double, double, double, double> getNodePadding();
  int getNodeBackgroundColor();
  int getNodeBorderColor();
  double getNodeBorderSize();

  int getConnectorBackgroundColor();
  double getConnectorWidth();
  double getConnectorHeight();

}