library flow.render.render;

abstract class Renderer<T> {

  void invalidate(Iterable<Map<String, dynamic>> data);

}