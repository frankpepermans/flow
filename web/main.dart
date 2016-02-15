import 'dart:html' as html;

import 'package:stagexl/stagexl.dart' as xl;

import 'package:flow/flow.dart';

import 'package:flow/src/render/webgl_renderer.dart';

void main() {
  WebglRenderer<String> renderer = new WebglRenderer<String>('#stage');
  Hierarchy<String> hierarchy = new Hierarchy<String>(renderer, childCompareHandler: (String dataA, String dataB) => dataA.compareTo(dataB));

  hierarchy.add('B', parentData: 'A');
  hierarchy.add('C', parentData: 'A');
  hierarchy.add('D', parentData: 'C');
  hierarchy.add('A', className: 'top-level-node');
  //renderer.remove('C');
  hierarchy.add('E', parentData: 'A');
  hierarchy.add('F', parentData: 'A');
  hierarchy.add('G', parentData: 'C');

  /*
  A F
  B C E
    D
   */
}