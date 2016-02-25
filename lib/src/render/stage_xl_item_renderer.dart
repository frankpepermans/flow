library flow.render.stage_xl_item_renderer;

import 'package:stagexl/stagexl.dart' as xl;

import 'package:tuple/tuple.dart';

import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeStyle;

class StageXLItemRenderer<T> extends xl.Sprite with ItemRenderer<T> {

  final xl.Sprite border = new xl.Sprite();
  final xl.Sprite container = new xl.Sprite();
  final xl.Shape connector = new xl.Shape();

  StageXLItemRenderer() : super() {
    addChild(border);
    addChild(connector);
    addChild(container);

    const List<Tuple2<double, double>> views = const <Tuple2<double, double>>[
      const Tuple2<double, double>(40.0, 40.0),
      const Tuple2<double, double>(80.0, 80.0),
      const Tuple2<double, double>(160.0, 160.0)
    ];
    int viewIndex = 0;
    bool isOpen = false;

    container.onMouseClick.listen((_) {
      viewIndex++;

      if (viewIndex >= views.length) viewIndex = 0;

      resize$sink.add(views[viewIndex]);
    });

    container.onMouseRightClick.listen((_) {
      isOpen = !isOpen;

      isOpen$sink.add(isOpen);
    });

    container.onMouseOver.listen((_) {
      className$sink.add('flow-node-hover');
    });

    container.onMouseOut.listen((_) {
      className$sink.add('flow-node');
    });
  }

  @override
  void update(ItemRendererState<T> state) {
    final NodeStyle nodeStyle = styleClient.getNodeStyle(state.className);
    final xl.Graphics g = container.graphics;
    final xl.Graphics h = border.graphics;
    final double dw = state.w;
    final double dh = state.h;
    final double bw = state.w + 2 * nodeStyle.borderSize;
    final double bh = state.h + 2 * nodeStyle.borderSize;

    h.clear();
    g.clear();

    h.beginPath();
    h.rect(-bw/2, -bh/2, bw, bh);
    h.closePath();

    g.beginPath();
    g.rect(-dw/2, -dh/2, dw, dh);
    g.closePath();

    h.fillColor(nodeStyle.border);
    g.fillColor(nodeStyle.background);
  }

  void connect(ItemRendererState<T> state) {
    final NodeStyle nodeStyle = styleClient.getNodeStyle(state.className);
    final xl.Graphics g = connector.graphics;
    final double fx = state.connectorFromX;
    final double tx = state.connectorToX;
    final double fy = state.connectorFromY;
    final double ty = state.connectorToY;
    double n, o, p;

    g.clear();
    g.beginPath();

    if (state.orientation == HierarchyOrientation.VERTICAL) {
      n = nodeStyle.connectorHeight/2;
      o = fx < tx ? -nodeStyle.connectorWidth/2 : nodeStyle.connectorWidth/2;
      p = nodeStyle.padding.item1;

      g.moveTo(fx + o, fy);
      g.lineTo(fx + o, ty + p - n);
      g.lineTo(tx + o, ty + p - n);
      g.lineTo(tx + o, ty);

      g.lineTo(tx - o, ty);
      g.lineTo(tx - o, ty + p + n);
      g.lineTo(fx - o, ty + p + n);
      g.lineTo(fx - o, fy);
      g.lineTo(fx + o, fy);
    } else {
      n = nodeStyle.connectorWidth/2;
      o = fy < ty ? -nodeStyle.connectorHeight/2 : nodeStyle.connectorHeight/2;
      p = nodeStyle.padding.item4;

      g.moveTo(fx, fy + o);
      g.lineTo(tx + p - n, fy + o);
      g.lineTo(tx + p - n, ty + o);
      g.lineTo(tx, ty + o);

      g.lineTo(tx, ty - o);
      g.lineTo(tx + p + n, ty - o);
      g.lineTo(tx + p + n, fy - o);
      g.lineTo(fx, fy - o);
      g.lineTo(fx, fy + o);
    }

    g.closePath();

    g.fillColor(nodeStyle.connectorBackground);
  }
}