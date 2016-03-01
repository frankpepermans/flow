library flow.render.stage_xl_item_renderer;

import 'package:stagexl/stagexl.dart' as xl;

import 'package:tuple/tuple.dart';

import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeStyle, NodeEqualityHandler;

class StageXLItemRenderer<T> extends xl.Sprite with ItemRenderer<T> {

  final xl.Sprite border = new xl.Sprite();
  final xl.Sprite container = new xl.Sprite();
  final xl.Shape connector = new xl.Shape();

  Tuple2<double, double> getDefaultSize(HierarchyOrientation orientation) => const Tuple2<double, double>(.0, .0);

  StageXLItemRenderer() : super() {
    addChild(connector);
    addChild(border);
    addChild(container);
  }

  @override
  void update(ItemRendererState<T> state) {
    final NodeStyle nodeStyle = styleClient.getNodeStyle(state.className);
    final xl.Graphics g = container.graphics;
    final xl.Graphics h = border.graphics;
    final double dw = state.w;
    final double dh = state.h;
    final double bw = dw + 2 * nodeStyle.borderSize;
    final double bh = dh + 2 * nodeStyle.borderSize;

    h.clear();
    g.clear();

    h.beginPath();
    h.rect(-bw/2, -bh/2, bw, bh);
    h.closePath();

    g.beginPath();
    g.rect(-dw/2, -dh/2, dw, dh);
    g.closePath();

    g.fillColor(xl.Color.White);

    g.beginPath();
    g.rect(-dw/2, -dh/2, dw, dh);
    g.closePath();

    h.fillColor(nodeStyle.border);
    g.fillColor(nodeStyle.background);
  }

  @override
  void updateOnAnimation(double value) {
    container.alpha = value;
    border.alpha = value;
  }

  @override
  void connect(ItemRendererState<T> state) {
    final NodeStyle nodeStyle = styleClient.getNodeStyle(state.className);
    final xl.Graphics g = connector.graphics;
    final double fx = state.connectorFromX;
    final double tx = state.connectorToX;
    final double fy = state.connectorFromY;
    final double ty = state.connectorToY;
    double n, o, p, q;

    g.clear();
    g.beginPath();

    if (state.orientation == HierarchyOrientation.VERTICAL) {
      if (ty <= fy) {
        n = nodeStyle.connectorHeight/2;
        o = fx < tx ? -nodeStyle.connectorWidth/2 : nodeStyle.connectorWidth/2;
        p = nodeStyle.padding.item1;
        q = (tx > fx) ? (nodeStyle.connectorRadius <= tx - fx ? nodeStyle.connectorRadius : tx - fx) : (tx < fx) ? -(nodeStyle.connectorRadius <= fx - tx ? nodeStyle.connectorRadius : fx - tx) : 0.0;

        g.moveTo(fx + o, fy);
        g.lineTo(fx + o, ty + p - n + nodeStyle.connectorRadius);
        g.quadraticCurveTo(fx + o, ty + p - n, fx + o + q, ty + p - n);
        g.lineTo(tx + o - q, ty + p - n);
        g.quadraticCurveTo(tx + o, ty + p - n, tx + o, ty + p - n - nodeStyle.connectorRadius);
        g.lineTo(tx + o, ty);
        g.lineTo(tx - o, ty);
        g.lineTo(tx - o, ty + p + n - nodeStyle.connectorRadius);
        g.quadraticCurveTo(tx - o, ty + p + n, tx - o - q, ty + p + n);
        g.lineTo(fx - o + q, ty + p + n);
        g.quadraticCurveTo(fx - o, ty + p + n, fx - o, ty + p + n + nodeStyle.connectorRadius);
        g.lineTo(fx - o, fy);
        g.lineTo(fx + o, fy);
      }
    } else {
      if (tx <= fx) {
        n = nodeStyle.connectorWidth/2;
        o = fy < ty ? -nodeStyle.connectorHeight/2 : nodeStyle.connectorHeight/2;
        p = nodeStyle.padding.item4;
        q = (ty > fy) ? (nodeStyle.connectorRadius <= ty - fy ? nodeStyle.connectorRadius : ty - fy) : (ty < fy) ? -(nodeStyle.connectorRadius <= fy - ty ? nodeStyle.connectorRadius : fy - ty) : 0.0;

        g.moveTo(fx, fy + o);
        g.lineTo(tx + p - n + nodeStyle.connectorRadius, fy + o);
        g.quadraticCurveTo(tx + p - n, fy + o, tx + p - n, fy + o + q);
        g.lineTo(tx + p - n, ty + o - q);
        g.quadraticCurveTo(tx + p - n, ty + o, tx + p - n - nodeStyle.connectorRadius, ty + o);
        g.lineTo(tx, ty + o);
        g.lineTo(tx, ty - o);
        g.lineTo(tx + p + n - nodeStyle.connectorRadius, ty - o);
        g.quadraticCurveTo(tx + p + n, ty - o, tx + p + n, ty - o - q);
        g.lineTo(tx + p + n, fy - o + q);
        g.quadraticCurveTo(tx + p + n, fy - o, tx + p + n + nodeStyle.connectorRadius, fy - o);
        g.lineTo(fx, fy - o);
        g.lineTo(fx, fy + o);
      }
    }

    g.closePath();

    g.fillColor(nodeStyle.connectorBackground);
  }
}