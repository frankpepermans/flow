library flow.render.webgl_item_renderer;

import 'package:stagexl/stagexl.dart' as xl;

import 'package:tuple/tuple.dart';

import 'package:flow/src/render/item_renderer.dart';

class WebglItemRenderer<T> extends xl.Sprite with ItemRenderer<T> {

  final xl.Sprite container = new xl.Sprite();

  WebglItemRenderer() : super() {
    addChild(container);

    bool isOpen = false;

    container.onMouseClick.listen((_) {
      resize$sink.add(isOpen ? const Tuple2<double, double>(40.0, 40.0) : const Tuple2<double, double>(80.0, 80.0));

      isOpen = !isOpen;
    });
  }

  @override
  void update(ItemRendererState<T> state) {
    final xl.Graphics g = container.graphics;

    g.clear();

    g.beginPath();
    g.rect(-state.w/2, -state.h/2, state.w, state.h);
    g.strokeColor(xl.Color.Red);
    g.fillColor(xl.Color.LightGray);
    g.closePath();

    g.beginPath();
    g.moveTo(state.connectorFromX, state.connectorFromY);
    g.lineTo(state.connectorToX, state.connectorToY);
    g.strokeColor(xl.Color.Red);
    g.closePath();
  }
}