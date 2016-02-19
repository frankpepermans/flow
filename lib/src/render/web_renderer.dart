library flow.render.web_renderer;

import 'dart:html' as html;

import 'package:tuple/tuple.dart';

import 'package:flow/src/render/renderer.dart';
import 'package:flow/src/render/item_renderer.dart';

export 'package:flow/src/hierarchy.dart' show HierarchyOrientation;

class WebRenderer<T> extends Renderer<T> {

  Map<String, html.CssStyleDeclaration> _cssStyleDeclarations;

  static const CSS_NAMES = const <String>['flow-node'];

  WebRenderer() {
    _cssStyleDeclarations = <String, html.CssStyleDeclaration>{};

    html.document.styleSheets.forEach((html.StyleSheet css) {
      if (css is html.CssStyleSheet) {
        css.cssRules.forEach((html.CssRule rule) {
          CSS_NAMES.forEach((String cssName) {
            if (rule is html.CssStyleRule && rule.selectorText == '.$cssName') {
              _cssStyleDeclarations[cssName] = new html.CssStyleDeclaration.css(rule.cssText.replaceAllMapped(new RegExp('${rule.selectorText}[\\s]*{[\\s]*([^}]+)}'), (Match match) => match.group(1)));
            }
          });
        });
      }
    });
  }

  @override
  ItemRenderer<T> newDefaultItemRendererInstance() => null;

  @override
  void scheduleRender() {}

  @override
  Tuple4<double, double, double, double> getNodePadding() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node');
    final double padding = _cssStyleValueToDouble(cssStyleDeclaration.padding);

    return new Tuple4<double, double, double, double>(
      _cssStyleValueToDouble(cssStyleDeclaration.paddingTop, defaultValue: padding),
      _cssStyleValueToDouble(cssStyleDeclaration.paddingRight, defaultValue: padding),
      _cssStyleValueToDouble(cssStyleDeclaration.paddingBottom, defaultValue: padding),
      _cssStyleValueToDouble(cssStyleDeclaration.paddingLeft, defaultValue: padding)
    );
  }

  bool hasStyleForSelectorName(String selectorName) => _cssStyleDeclarations.containsKey(selectorName);

  html.CssStyleDeclaration getStyleForSelectorName(String selectorName) {
    _cssStyleDeclarations.putIfAbsent(selectorName, () => new html.CssStyleDeclaration());

    return _cssStyleDeclarations[selectorName];
  }

  double _cssStyleValueToDouble(String styleValue, {double defaultValue: .0}) {
    final RegExp regExp = new RegExp('([\\d.]+).*');
    final String matchValue = styleValue.replaceAllMapped(regExp, (Match match) => match.group(1)).trim();

    if (matchValue.isNotEmpty) return double.parse(matchValue);

    return defaultValue;
  }

}