library flow.render.web_renderer;

import 'dart:html' as html;

import 'package:tuple/tuple.dart';

import 'package:flow/src/render/renderer.dart';
import 'package:flow/src/render/item_renderer.dart';

export 'package:flow/src/hierarchy.dart' show HierarchyOrientation;

class WebRenderer<T> extends Renderer<T> {

  Map<String, html.CssStyleDeclaration> _cssStyleDeclarations;

  static const CSS_NAMES = const <String>['flow-node', 'flow-node-connector'];

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
  Tuple4<double, double, double, double> getNodeMargin() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node');
    final double margin = _cssStyleValueToDouble(cssStyleDeclaration.margin);

    return new Tuple4<double, double, double, double>(
        _cssStyleValueToDouble(cssStyleDeclaration.marginTop, defaultValue: margin),
        _cssStyleValueToDouble(cssStyleDeclaration.marginRight, defaultValue: margin),
        _cssStyleValueToDouble(cssStyleDeclaration.marginBottom, defaultValue: margin),
        _cssStyleValueToDouble(cssStyleDeclaration.marginLeft, defaultValue: margin)
    );
  }

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

  @override
  int getNodeBackgroundColor() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node');

    return _cssStyleValueToInt(cssStyleDeclaration.backgroundColor);
  }

  @override
  int getNodeBorderColor() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node');

    return _cssStyleValueToInt(cssStyleDeclaration.borderColor);
  }

  @override
  double getNodeBorderSize() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node');

    return _cssStyleValueToDouble(cssStyleDeclaration.borderWidth, defaultValue: 1.0);
  }

  @override
  int getConnectorBackgroundColor() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node-connector');

    return _cssStyleValueToInt(cssStyleDeclaration.backgroundColor);
  }

  @override
  double getConnectorWidth() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node-connector');

    return _cssStyleValueToDouble(cssStyleDeclaration.width, defaultValue: 1.0);
  }

  @override
  double getConnectorHeight() {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName('flow-node-connector');

    return _cssStyleValueToDouble(cssStyleDeclaration.height, defaultValue: 1.0);
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

  int _cssStyleValueToInt(String styleValue, {int defaultValue: 0}) {
    if (styleValue.contains('rgb(')) {
      final Iterable<int> rgb = styleValue.split('rgb(').last.split(')').first.split(',').map((String value) => int.parse(value.trim()));

      return (0xff << 24) | (rgb.first << 16) | (rgb.elementAt(1) << 8) | rgb.last;
    }

    return defaultValue;
  }

}