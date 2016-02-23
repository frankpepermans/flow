library flow.render.web_renderer;

import 'dart:async';
import 'dart:html' as html;

import 'package:flow/src/render/renderer.dart';
import 'package:flow/src/render/item_renderer.dart';
import 'package:flow/src/render/style_client.dart';
import 'package:flow/src/render/css_style_client.dart';

class WebRenderer<T> extends Renderer<T> {

  Stream<num> get animationStream => getAnimationStream();

  final CssStyleClient _styleClient = new CssStyleClient();

  StyleClient get styleClient => _styleClient;

  WebRenderer();

  @override
  ItemRenderer<T> newDefaultItemRendererInstance() => null;

  Stream<num> getAnimationStream() async* {
    while (true) yield await html.window.animationFrame;
  }
}