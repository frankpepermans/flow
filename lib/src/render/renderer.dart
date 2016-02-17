library flow.render.render;

import 'package:flow/src/digest.dart';

import 'package:flow/src/render/item_renderer.dart';

abstract class Renderer<T> {

  ItemRenderer<T> newDefaultItemRendererInstance();

  void invalidate(Iterable<RenderState<T>> data);

}