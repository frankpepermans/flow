library flow.flow_node_item_renderer;

import 'dart:async';
import 'dart:math' as math;

import 'package:tuple/tuple.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:stagexl/stagexl.dart' as xl;

import 'package:flow/src/render/stage_xl_item_renderer.dart';
import 'package:flow/src/hierarchy.dart' show HierarchyOrientation, NodeEqualityHandler;
import 'package:flow/src/render/style_client.dart';
import 'package:flow/src/stage_xl_resource_manager.dart';
import 'package:flow/src/render/item_renderer.dart';

import 'hierarchy_data_generator.dart';

final StageXLResourceManager resourceManager = new StageXLResourceManager();
final xl.TextureAtlas atlas = resourceManager.resourceManager.getTextureAtlas("atlas");
final xl.TextureAtlas mugs = resourceManager.resourceManager.getTextureAtlas("mugs");

class FlowNodeItemRenderer<T extends Person> extends StageXLItemRenderer<T> {

  xl.TextField nameField, jobField, jobMainField, cityField;
  xl.Sprite backgroundGroup, buttonGroup, arrowGroup, mugGroup;
  xl.Bitmap backgroundStatic, buttonStatic, mugStatic;
  xl.Shape arrow;
  xl.Mask mask;
  int viewIndex = 0, lastIndex = 0;

  bool _disableMouseEvents = false;

  final List<Tuple2<double, double>> views = const <Tuple2<double, double>>[
    const Tuple2<double, double>(28.0, 138.0),
    const Tuple2<double, double>(138.0, 138.0),
    const Tuple2<double, double>(348.0, 197.0)
  ];

  FlowNodeItemRenderer() : super() {
    nameField = new xl.TextField()..mouseEnabled = false;
    jobField = new xl.TextField()..mouseEnabled = false;
    jobMainField = new xl.TextField()..mouseEnabled = false;
    cityField = new xl.TextField()..mouseEnabled = false;
    backgroundGroup = new xl.Sprite()..mouseEnabled = false;
    mugGroup = new xl.Sprite()..mouseEnabled = false;
    buttonGroup = new xl.Sprite();
    arrowGroup = new xl.Sprite()..mouseEnabled = false;

    addChild(backgroundGroup);
    addChild(mugGroup);
    addChild(nameField);
    addChild(jobField);
    addChild(jobMainField);
    addChild(cityField);
    addChild(buttonGroup);
    addChild(arrowGroup);

    isOpen$.listen((bool isOpen) {
      if (isOpen && viewIndex == 0) {
        lastIndex = viewIndex;
        viewIndex = 1;

        resize$sink.add(views[viewIndex]);
      }
    });
  }

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

    new rx.Observable.merge(<Stream>[container.onMouseClick, container.onTouchTap])
      .listen((_) {
        lastIndex = viewIndex;
        viewIndex++;

        if (viewIndex >= views.length) viewIndex = 0;

        resize$sink.add(views[viewIndex]);
      });

    new rx.Observable.merge(<Stream>[buttonGroup.onMouseClick, buttonGroup.onTouchTap])
      .listen((_) {
        lastIndex = viewIndex;
        isOpen = !isOpen;

        if (isOpen && viewIndex == 0) {
          viewIndex = 1;
        } else if (!isOpen && viewIndex > 0) {
          viewIndex = 0;
        }

        resize$sink.add(views[viewIndex]);

        isOpen$sink.add(isOpen);
      });

    container.onMouseOver.listen((_) {
      if (!_disableMouseEvents) className$sink.add('flow-node-hover');
    });

    container.onMouseOut.listen((_) {
      if (!_disableMouseEvents) className$sink.add('flow-node');
    });
  }

  @override
  void update(ItemRendererState<T> state) {
    super.update(state);

    backgroundGroup.mask = new xl.Mask.rectangle(-state.w/2, -state.h/2, state.w, state.h);
    mugGroup.mask = new xl.Mask.rectangle(-state.w/2, -state.h/2, state.w, state.h);
    buttonGroup.mask = new xl.Mask.rectangle(-state.w/2, -state.h/2, state.w, state.h);

    if (animation == null) setBackground();

    final Person person = state.data;

    setButton(state.childCount > 0, state.isOpen);

    if (viewIndex > 0) setMug(person.image);
    else setMug(null);

    nameField.rotation = (viewIndex == 0) ? math.PI / 2 : .0;

    nameField.text = '${person.lastName} ${person.firstName}';

    jobMainField.visible = (viewIndex == 2);
    jobMainField.width = state.w/2 + 20.0;
    jobMainField.x = -30.0;
    jobMainField.y = -50.0;
    jobMainField.text = person.jobMain;

    jobField.visible = (viewIndex == 2);
    jobField.width = state.w/2 + 20.0;
    jobField.x = -30.0;
    jobField.y = -30.0;
    jobField.text = person.jobTitle;

    cityField.visible = (viewIndex == 2);
    cityField.width = state.w/2 + 20.0;
    cityField.x = -30.0;
    cityField.y = -10.0;
    cityField.text = person.city;

    switch (viewIndex) {
      case 0:
        nameField.defaultTextFormat = new xl.TextFormat('Arial', 12.0, xl.Color.DarkSlateGray, align: xl.TextFormatAlign.LEFT);
        nameField.width = state.h - 27.0;
        nameField.x = 7.0;
        nameField.y = -60.0;
        break;
      case 1:
        nameField.defaultTextFormat = new xl.TextFormat('Arial', 12.0, xl.Color.DarkSlateGray, align: xl.TextFormatAlign.CENTER);
        nameField.width = state.w - 20.0;
        nameField.x = 10.0 - state.w/2;
        nameField.y = -57.0;
        break;
      case 2:
        nameField.defaultTextFormat = new xl.TextFormat('Arial', 12.0, xl.Color.DarkSlateGray, align: xl.TextFormatAlign.CENTER);
        nameField.width = state.w - 20.0;
        nameField.x = 10.0 - state.w/2;
        nameField.y = -87.0;
        break;
    }

    if (state.childCount > 0) {
      const int size = 5;

      if (arrow == null) arrow = new xl.Shape();

      if (!arrowGroup.contains(arrow)) arrowGroup.addChild(arrow);

      final xl.Graphics g = arrow.graphics;

      arrow.x = 0;
      arrow.y = state.h / 2 - (state.isOpen ? 9 : 7) - ((viewIndex == 2) ? 4 : 0);

      g.clear();

      g.beginPath();

      final double cx = size * math.sin(2 * math.PI / 3);
      final double cy = -size * math.cos(2 * math.PI / 3);

      g.moveTo(0, -size);
      g.lineTo(cx, cy);
      g.lineTo(-cx, cy);
      g.lineTo(0, -size);

      g.fillColor(state.isOpen ? xl.Color.White : xl.Color.Black);
      g.closePath();

      arrow.rotation = state.isOpen ? math.PI : .0;
    } else {
      if (arrow != null && arrowGroup.contains(arrow)) arrowGroup.removeChild(arrow);
    }
  }

  @override
  void updateOnAnimation(AnimationInfo info) {
    super.updateOnAnimation(info);

    final Tuple2<double, double> dwhA = views[viewIndex];
    final Tuple2<double, double> dwhB = views[lastIndex];
    final double sx = dwhB.item1 / dwhA.item1;
    final double sy = dwhB.item2 / dwhA.item2;
    final double tx = 1.0 - sx, ty = 1.0 - sy;

    if (info.position == AnimationPosition.START) setBackground();

    if (info.type != AnimationType.REPOSITION) {
      container.alpha = info.time;
      border.alpha = info.time;
      backgroundGroup.alpha = info.time;
      buttonGroup.alpha = info.time;
      arrowGroup.alpha = info.time;
    } else {
      container.alpha = 1.0;
      border.alpha = 1.0;
      backgroundGroup.alpha = 1.0;
      buttonGroup.alpha = 1.0;
      arrowGroup.alpha = 1.0;

      if (info.position == AnimationPosition.START && (viewIndex != lastIndex)) {
        _disableMouseEvents = true;
      }

      if (dwhA.item1 != dwhB.item1) {
        container.scaleX = border.scaleX = backgroundGroup.scaleX = buttonGroup.scaleX = arrowGroup.scaleX = sx + info.time * tx;
      }

      if (dwhA.item2 != dwhB.item2) {
        container.scaleY = border.scaleY = backgroundGroup.scaleY = buttonGroup.scaleY = arrowGroup.scaleY = sy + info.time * ty;
      }

      if (info.position == AnimationPosition.COMPLETE && (viewIndex != lastIndex)) {
        _disableMouseEvents = false;

        lastIndex = viewIndex;
      }
    }
  }

  void setBackground() {
    xl.BitmapData bmp;

    switch (viewIndex) {
      case 0: bmp = atlas.getBitmapData('bg-small'); break;
      case 1: bmp = atlas.getBitmapData('bg-medium'); break;
      case 2: bmp = atlas.getBitmapData('bg-large'); break;
    }

    if (backgroundStatic != null) {
      if (backgroundGroup.contains(backgroundStatic)) backgroundGroup.removeChild(backgroundStatic);
    }

    backgroundStatic = new xl.Bitmap(bmp)
      ..x = -views[viewIndex].item1 / 2
      ..y = -views[viewIndex].item2 / 2;

    backgroundGroup.addChild(backgroundStatic);
  }

  void setButton(bool hasChildren, bool isOpen) {
    xl.BitmapData bmp;

    if (hasChildren) {
      switch (viewIndex) {
        case 0: bmp = atlas.getBitmapData(isOpen ? 'btn-small-hover' : 'btn-small'); break;
        case 1: bmp = atlas.getBitmapData(isOpen ? 'btn-medium-hover' : 'btn-medium'); break;
        case 2: bmp = atlas.getBitmapData(isOpen ? 'btn-large-hover' : 'btn-large'); break;
      }
    }

    if (buttonStatic != null) {
      if (buttonGroup.contains(buttonStatic)) buttonGroup.removeChild(buttonStatic);
    }

    if (hasChildren) {
      if (viewIndex == 2) {
        buttonStatic = new xl.Bitmap(bmp)
          ..x = -views[viewIndex].item1 / 2
          ..y = views[viewIndex].item2 / 2 - bmp.height;
      } else {
        buttonStatic = new xl.Bitmap(bmp)
          ..x = -views[viewIndex].item1 / 2 + 1
          ..y = views[viewIndex].item2 / 2 - bmp.height - 1;
      }

      buttonGroup.addChild(buttonStatic);
    }
  }

  void setMug(String imageName) {
    final xl.Graphics g = mugGroup.graphics;

    g.clear();

    if (mugStatic != null) {
      if (mugGroup.contains(mugStatic)) mugGroup.removeChild(mugStatic);
    }

    if (imageName == null) return;

    final double d = (viewIndex == 1) ? 60.0 : 100.0;
    final double x = (viewIndex == 2) ? -110.0 : .0;
    final double y = (viewIndex == 1) ? 10.0 : 4.0;

    final xl.BitmapData bmp = mugs.getBitmapData(imageName);

    mugStatic = new xl.Bitmap(bmp)
      ..x = -d/2 + x
      ..y = -d/2 + y
      ..width = d
      ..height = d;

    g.beginPath();
    g.rect(x -d/2 - 3.0, y -d/2 - 3.0, d + 6.0, d + 6.0);
    g.fillColor(xl.Color.LightGray);
    g.closePath();

    g.beginPath();
    g.rect(x -d/2 - 1.0, y -d/2 - 1.0, d + 2.0, d + 2.0);
    g.fillColor(xl.Color.White);
    g.closePath();

    mugGroup.addChild(mugStatic);
  }

}