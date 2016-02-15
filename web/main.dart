import 'package:flow/flow.dart';

void main() {
  Renderer<String> renderer = new Renderer<String>(childCompareHandler: (String dataA, String dataB) => dataA.compareTo(dataB));

  renderer.add('B', parentData: 'A');
  renderer.add('C', parentData: 'A');
  renderer.add('D', parentData: 'C');
  renderer.add('A', className: 'top-level-node');
  //renderer.remove('C');
  renderer.add('E', parentData: 'A');
  renderer.add('F', className: 'top-level-node');

  /*
  A F
  B C E
    D
   */
}