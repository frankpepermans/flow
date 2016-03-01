library flow_example.flow_node_item_renderer;

import 'dart:async';

import 'package:tuple/tuple.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:stagexl/stagexl.dart' as xl;

import 'package:flow/src/render/stage_xl_item_renderer.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeEqualityHandler;
import 'package:flow/src/render/style_client.dart';
import 'package:flow/src/stage_xl_resource_manager.dart';

final StageXLResourceManager resourceManager = new StageXLResourceManager();
final xl.TextureAtlas atlas = resourceManager.resourceManager.getTextureAtlas("atlas");

class FlowNodeItemRenderer<T> extends StageXLItemRenderer<T> {

  xl.Bitmap backgroundStatic;
  int viewIndex = 0;

  final List<Tuple2<double, double>> views = const <Tuple2<double, double>>[
    const Tuple2<double, double>(28.0, 138.0),
    const Tuple2<double, double>(138.0, 138.0),
    const Tuple2<double, double>(348.0, 197.0)
  ];

  Tuple2<double, double> getDefaultSize(HierarchyOrientation orientation) {
    switch (orientation) {
      case HierarchyOrientation.VERTICAL:
        return views.first;
      case HierarchyOrientation.HORIZONTAL:
        return new Tuple2<double, double>(views.first.item2, views.first.item1);
    }
  }

  @override
  void init(NodeEqualityHandler<T> equalityHandler, StyleClient styleClient) {
    super.init(equalityHandler, styleClient);

    bool isOpen = false;

    container.onMouseClick
      .listen((_) {
        viewIndex++;

        if (viewIndex >= views.length) viewIndex = 0;

        resize$sink.add(views[viewIndex]);

        setBackground();
      });

    container.onMouseRightClick
      .listen((_) {
        isOpen = !isOpen;

        if (isOpen && viewIndex == 0) {
          viewIndex = 1;
        } else if (!isOpen && viewIndex > 0) {
          viewIndex = 0;
        }

        resize$sink.add(views[viewIndex]);

        isOpen$sink.add(isOpen);

        setBackground();
      });

    container.onMouseOver.listen((_) {
      className$sink.add('flow-node-hover');
    });

    container.onMouseOut.listen((_) {
      className$sink.add('flow-node');
    });

    setBackground();
  }

  void setBackground() {
    xl.BitmapData bmp;

    switch (viewIndex) {
      case 0: bmp = atlas.getBitmapData('bg-small'); break;
      case 1: bmp = atlas.getBitmapData('bg-medium'); break;
      case 2: bmp = atlas.getBitmapData('bg-large'); break;
    }

    if (backgroundStatic != null) {
      if (container.contains(backgroundStatic)) container.removeChild(backgroundStatic);
    }

    backgroundStatic = new xl.Bitmap(bmp)
      ..x = -views[viewIndex].item1 / 2
      ..y = -views[viewIndex].item2 / 2;

    container.addChild(backgroundStatic);
  }

}