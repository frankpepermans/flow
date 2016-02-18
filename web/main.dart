import 'dart:math' as math;

import 'package:flow/flow.dart';

import 'package:flow/src/render/webgl_renderer.dart';

void main() {
  final WebglRenderer<String> renderer = new WebglRenderer<String>('#stage');
  final Hierarchy<String> hierarchy = new Hierarchy<String>(renderer, HierarchyOrientation.HORIZONTAL, childCompareHandler: (String dataA, String dataB) => dataA.compareTo(dataB));
  final math.Random R = new math.Random();

  hierarchy.add('A', className: 'top-level-node');

  _addRandomChildren(hierarchy, 'A', 0);
}

void _addRandomChildren(Hierarchy<String> hierarchy, String parent, int level) {
  final math.Random R = new math.Random();
  final int len = R.nextInt(3) + 1;

  for (int i=0; i<len; i++) {
    String next = R.nextInt(0xffffff).toString();
    hierarchy.add(next, parentData: parent);

    if (level < 5) _addRandomChildren(hierarchy, next, level + 1);
  }
}