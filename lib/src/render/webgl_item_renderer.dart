library flow.render.webgl_item_renderer;

import 'package:stagexl/stagexl.dart' as xl;

import 'package:flow/src/render/item_renderer.dart';

class WebglItemRenderer<T> extends xl.Sprite with ItemRenderer<T> {

  WebglItemRenderer() : super();

  @override
  void update(ItemRendererState<T> state) {
    graphics.clear();

    graphics.beginPath();
    graphics.rect(-state.w/2, -state.h/2, state.w, state.h);
    graphics.strokeColor(xl.Color.Red);
    graphics.fillColor(xl.Color.LightGray);
    graphics.closePath();

    graphics.beginPath();
    graphics.moveTo(state.connectorFromX, state.connectorFromY);
    graphics.lineTo(state.connectorToX, state.connectorToY);
    graphics.strokeColor(xl.Color.Red);
    graphics.closePath();
  }
}