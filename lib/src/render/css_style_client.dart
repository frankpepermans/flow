library flow.render.css_style_client;

import 'dart:html' as html;

import 'package:tuple/tuple.dart';

import 'package:flow/src/render/style_client.dart';
import 'package:flow/src/hierarchy.dart' show NodeStyle;

import 'package:flow/src/force_print.dart' show fprint;

class CssStyleClient extends StyleClient {

  Map<String, html.CssStyleDeclaration> _cssStyleDeclarations;

  CssStyleClient() {
    _cssStyleDeclarations = <String, html.CssStyleDeclaration>{};

    html.document.styleSheets.forEach((html.StyleSheet css) {
      if (css is html.CssStyleSheet) {
        css.cssRules.forEach((html.CssRule rule) {
          if (rule is html.CssStyleRule) {
            _cssStyleDeclarations[rule.selectorText.split('.').last] = new html.CssStyleDeclaration.css(rule.cssText.replaceAllMapped(new RegExp('${rule.selectorText}[\\s]*{[\\s]*([^}]+)}'), (Match match) => match.group(1)));
          }
        });
      }
    });
  }

  final Map<String, NodeStyle> _cachedNodeStyles = <String, NodeStyle>{};

  @override
  NodeStyle getNodeStyle(String className) {
    if (!_cachedNodeStyles.containsKey(className)) _cachedNodeStyles[className] = new NodeStyle(
        getNodeMargin(className),
        getNodePadding(className),
        getNodeBackgroundColor(className),
        getNodeBorderColor(className),
        getNodeBorderSize(className),
        getConnectorBackgroundColor(className),
        getConnectorWidth(className),
        getConnectorHeight(className)
    );

    return _cachedNodeStyles[className];
  }

  @override
  Tuple4<double, double, double, double> getNodeMargin(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className);
    final double margin = _cssStyleValueToDouble(cssStyleDeclaration.margin);

    return new Tuple4<double, double, double, double>(
        _cssStyleValueToDouble(cssStyleDeclaration.marginTop, defaultValue: margin),
        _cssStyleValueToDouble(cssStyleDeclaration.marginRight, defaultValue: margin),
        _cssStyleValueToDouble(cssStyleDeclaration.marginBottom, defaultValue: margin),
        _cssStyleValueToDouble(cssStyleDeclaration.marginLeft, defaultValue: margin)
    );
  }

  @override
  Tuple4<double, double, double, double> getNodePadding(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className);
    final double padding = _cssStyleValueToDouble(cssStyleDeclaration.padding);

    return new Tuple4<double, double, double, double>(
        _cssStyleValueToDouble(cssStyleDeclaration.paddingTop, defaultValue: padding),
        _cssStyleValueToDouble(cssStyleDeclaration.paddingRight, defaultValue: padding),
        _cssStyleValueToDouble(cssStyleDeclaration.paddingBottom, defaultValue: padding),
        _cssStyleValueToDouble(cssStyleDeclaration.paddingLeft, defaultValue: padding)
    );
  }

  @override
  int getNodeBackgroundColor(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className);

    return _cssStyleValueToInt(cssStyleDeclaration.backgroundColor);
  }

  @override
  int getNodeBorderColor(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className);

    return _cssStyleValueToInt(cssStyleDeclaration.borderColor);
  }

  @override
  double getNodeBorderSize(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className);

    return _cssStyleValueToDouble(cssStyleDeclaration.borderWidth, defaultValue: 1.0);
  }

  @override
  int getConnectorBackgroundColor(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className + '-connector');

    return _cssStyleValueToInt(cssStyleDeclaration.backgroundColor);
  }

  @override
  double getConnectorWidth(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className + '-connector');

    return _cssStyleValueToDouble(cssStyleDeclaration.width, defaultValue: 1.0);
  }

  @override
  double getConnectorHeight(String className) {
    final html.CssStyleDeclaration cssStyleDeclaration = getStyleForSelectorName(className + '-connector');

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

