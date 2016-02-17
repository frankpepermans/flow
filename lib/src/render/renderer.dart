library flow.render.render;

import 'package:flow/src/digest.dart';

abstract class Renderer<T> {

  void invalidate(Iterable<RenderState<T>> data);

}