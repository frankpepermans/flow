import 'dart:math' as math;
import 'dart:html';

import 'package:flow/flow.dart';

import 'package:flow/src/render/stage_xl_renderer.dart';

void main() {
  final StageXLRenderer<String> renderer = new StageXLRenderer<String>('#flow-container', '#flow-canvas');
  final Hierarchy<String> hierarchy = new Hierarchy<String>(renderer, childCompareHandler: (String dataA, String dataB) => dataA.compareTo(dataB));

  hierarchy.orientation = HierarchyOrientation.HORIZONTAL;

  hierarchy.add('A', className: 'flow-top-level-node');
  hierarchy.add('B', className: 'flow-top-level-node');

  _addRandomChildren(hierarchy, 'A', 0);
  _addRandomChildren(hierarchy, 'B', 0);

  querySelector('#button-orientation').onClick.listen((_) {
    if (hierarchy.orientation == HierarchyOrientation.VERTICAL)
      hierarchy.orientation = HierarchyOrientation.HORIZONTAL;
    else
      hierarchy.orientation = HierarchyOrientation.VERTICAL;
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