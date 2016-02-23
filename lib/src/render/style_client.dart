library flow.render.style_client;

import 'package:tuple/tuple.dart';

import 'package:flow/src/hierarchy.dart' show NodeStyle;

abstract class StyleClient {

  NodeStyle getNodeStyle(String className);

  Tuple4<double, double, double, double> getNodeMargin(String className);
  Tuple4<double, double, double, double> getNodePadding(String className);
  int getNodeBackgroundColor(String className);
  int getNodeBorderColor(String className);
  double getNodeBorderSize(String className);

  int getConnectorBackgroundColor(String className);
  double getConnectorWidth(String className);
  double getConnectorHeight(String className);

}