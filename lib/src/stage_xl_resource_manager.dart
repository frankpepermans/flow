library flow.stage_xl_resource_manager;

import 'package:stagexl/stagexl.dart' as xl;

class StageXLResourceManager {

  static final xl.ResourceManager RESOURCE_MANAGER = new xl.ResourceManager();

  xl.ResourceManager get resourceManager => RESOURCE_MANAGER;

}