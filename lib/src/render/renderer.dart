library flow.render.renderer;

import 'dart:async';
import 'dart:html' as html;

import 'package:tuple/tuple.dart';

import 'package:flow/src/digest.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeStyle;
import 'package:flow/src/render/item_renderer.dart';

export 'package:flow/src/hierarchy.dart' show HierarchyOrientation;

abstract class Renderer<T> {

  NodeStyle nodeStyle;

  Sink<Iterable<RenderState<T>>> get state$sink => _state$ctrl.sink;
  Stream<Iterable<RenderState<T>>> get state$ => _state$ctrl.stream;

  Sink<bool> get materializeStage$sink => _materializeStage$ctrl.sink;
  Stream<bool> get materializeStage$ => _materializeStage$ctrl.stream;

  HierarchyOrientation orientation;

  final StreamController<Iterable<RenderState<T>>> _state$ctrl = new StreamController<Iterable<RenderState<T>>>();
  final StreamController<bool> _materializeStage$ctrl = new StreamController<bool>();

  ItemRenderer<T> newDefaultItemRendererInstance();

  Stream<num> getAnimationStream();

  Tuple4<double, double, double, double> getNodeMargin();
  Tuple4<double, double, double, double> getNodePadding();
  int getNodeBackgroundColor();
  int getNodeBorderColor();
  double getNodeBorderSize();

  int getConnectorBackgroundColor();
  double getConnectorWidth();
  double getConnectorHeight();

}