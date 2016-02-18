library flow.render.render;

import 'dart:async';

import 'package:flow/src/digest.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation;
import 'package:flow/src/render/item_renderer.dart';

export 'package:flow/src/hierarchy.dart' show HierarchyOrientation;

abstract class Renderer<T> {

  Sink<Iterable<RenderState<T>>> get state$sink => _state$ctrl.sink;
  Stream<Iterable<RenderState<T>>> get state$ => _state$ctrl.stream;

  HierarchyOrientation orientation;

  final StreamController<Iterable<RenderState<T>>> _state$ctrl = new StreamController<Iterable<RenderState<T>>>();

  ItemRenderer<T> newDefaultItemRendererInstance();

  void scheduleRender();

}