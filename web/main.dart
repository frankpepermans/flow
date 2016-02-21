import 'dart:math' as math;
import 'dart:html';

import 'package:flow/flow.dart';

import 'package:flow/src/render/webgl_renderer.dart';

void main() {
  final WebglRenderer<String> renderer = new WebglRenderer<String>('#flow-container', '#flow-canvas');
  final Hierarchy<String> hierarchy = new Hierarchy<String>(renderer, childCompareHandler: (String dataA, String dataB) => dataA.compareTo(dataB));

  hierarchy.setOrientation(HierarchyOrientation.HORIZONTAL);

  hierarchy.add('A', className: 'top-level-node');
  hierarchy.add('B', className: 'top-level-node');

  _addRandomChildren(hierarchy, 'A', 0);
  _addRandomChildren(hierarchy, 'B', 0);

  querySelector('#button-orientation').onClick.listen((_) {
    if (hierarchy.orientation == HierarchyOrientation.VERTICAL)
      hierarchy.setOrientation(HierarchyOrientation.HORIZONTAL);
    else
      hierarchy.setOrientation(HierarchyOrientation.VERTICAL);
  });
}

void _addRandomChildren(Hierarchy<String> hierarchy, String parent, int level) {
  final math.Random R = new math.Random();
  final int len = R.nextInt(3) + 1;

  for (int i=0; i<len; i++) {
    String next = R.nextInt(0xffffff).toString();
    hierarchy.add(next, parentData: parent);

    if (level < 4) _addRandomChildren(hierarchy, next, level + 1);
  }
}