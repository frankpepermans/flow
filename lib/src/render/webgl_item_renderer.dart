library flow.render.webgl_item_renderer;

import 'package:stagexl/stagexl.dart' as xl;

import 'package:flow/src/render/item_renderer.dart';

class WebglItemRenderer<T> extends xl.Sprite with ItemRenderer<T> {

  @override
  void clear() => graphics.clear();

  @override
  void draw(double w, double h) {
    graphics.beginPath();
    graphics.rect(-w/2, -h/2, w, h);
    graphics.strokeColor(xl.Color.Red);
    graphics.fillColor(xl.Color.LightGray);
    graphics.closePath();
  }

  @override
  void connect(double fromX, double fromY, double toX, double toY) {
    graphics.beginPath();
    graphics.moveTo(fromX, fromY);
    graphics.lineTo(toX, toY);
    graphics.strokeColor(xl.Color.Red);
    graphics.closePath();
  }

  @override
  void invalidateData() {
    print(data);
  }
}