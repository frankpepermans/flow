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
  hierarchy.add('H', parentData: 'B');
  hierarchy.add('I', parentData: 'B');
  hierarchy.add('J', parentData: 'D');
  hierarchy.add('K', parentData: 'D');
  hierarchy.add('L', parentData: 'B');
  hierarchy.add('M', parentData: 'E');
  hierarchy.add('N', parentData: 'F');
  hierarchy.add('O', parentData: 'G');
  hierarchy.add('P', parentData: 'H');
  hierarchy.add('Q', parentData: 'I');
  hierarchy.add('R', parentData: 'I');
  hierarchy.add('S', parentData: 'I');
  hierarchy.add('T', parentData: 'J');
  hierarchy.add('U', parentData: 'J');
  hierarchy.add('V', parentData: 'K');
  hierarchy.add('W', parentData: 'L');
  hierarchy.add('X', parentData: 'M');
  hierarchy.add('Y', parentData: 'N');
  hierarchy.add('Z', parentData: 'N');



  /*
  A F
  B C E
    D
   */
}