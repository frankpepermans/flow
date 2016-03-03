import 'dart:math' as math;
import 'dart:html';

import 'package:flow/flow.dart';

import 'package:flow/src/render/stage_xl_renderer.dart';
import 'package:flow/src/stage_xl_resource_manager.dart';

import 'flow_node_item_renderer.dart';
import 'hierarchy_data_generator.dart';

void main() {
  final StageXLResourceManager rm = new StageXLResourceManager();

  rm.resourceManager.addTextureAtlas('atlas', 'atlas.json');
  rm.resourceManager.addTextureAtlas('mugs', 'mugs.json');

  rm.resourceManager.load()
    .then((_) {
      final StageXLRenderer<Person> renderer = new StageXLRenderer<Person>('#flow-container', '#flow-canvas');
      final Hierarchy<Person> hierarchy = new Hierarchy<Person>(renderer, childCompareHandler: (Person dataA, Person dataB) => dataA.compareTo(dataB));

      hierarchy.orientation = HierarchyOrientation.VERTICAL;

      new HierarchyDataGenerator().generate(500).forEach((Person person, Person owner) {
        if (owner == null) {
          hierarchy.add(person, className: 'flow-top-level-node', itemRenderer: (Person data) => new FlowNodeItemRenderer<Person>());
        } else {
          hierarchy.add(person, parentData: owner, itemRenderer: (Person data) => new FlowNodeItemRenderer<Person>());
        }
      });
    });
}