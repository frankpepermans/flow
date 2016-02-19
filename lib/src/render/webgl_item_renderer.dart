library flow.render.webgl_item_renderer;

import 'package:stagexl/stagexl.dart' as xl;

import 'package:tuple/tuple.dart';

import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation;

class WebglItemRenderer<T> extends xl.Sprite with ItemRenderer<T> {

  final xl.Sprite container = new xl.Sprite();
  final xl.Shape connector = new xl.Shape();

  WebglItemRenderer() : super() {
    addChild(connector);
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
    final xl.Graphics h = connector.graphics;
    final double dw = state.w;
    final double dh = state.h;
    final double fx = state.connectorFromX;
    final double tx = state.connectorToX;
    final double fy = state.connectorFromY;
    final double ty = state.connectorToY;
    const double offset = 5.0;
    double o;

    g.clear();
    h.clear();

    g.beginPath();
    g.rect(-dw/2, -dh/2, dw, dh);
    g.closePath();

    g.strokeColor(xl.Color.DarkSlateGray);
    g.fillColor(xl.Color.LightSlateGray);

    h.beginPath();

    if (orientation == HierarchyOrientation.VERTICAL) {
      o = fx < tx ? -.5 : .5;

      h.moveTo(fx + o, fy);
      h.lineTo(fx + o, ty + offset - .5);
      h.lineTo(tx + o, ty + offset - .5);
      h.lineTo(tx + o, ty);

      h.lineTo(tx - o, ty);
      h.lineTo(tx - o, ty + offset + .5);
      h.lineTo(fx - o, ty + offset + .5);
      h.lineTo(fx - o, fy);
      h.lineTo(fx + o, fy);
    } else {
      o = fy < ty ? -.5 : .5;

      h.moveTo(fx, fy + o);
      h.lineTo(tx + offset - .5, fy + o);
      h.lineTo(tx + offset - .5, ty + o);
      h.lineTo(tx, ty + o);

      h.lineTo(tx, ty - o);
      h.lineTo(tx + offset + .5, ty - o);
      h.lineTo(tx + offset + .5, fy - o);
      h.lineTo(fx, fy - o);
      h.lineTo(fx, fy + o);
    }

    h.closePath();

    h.fillColor(xl.Color.OrangeRed);
  }
}