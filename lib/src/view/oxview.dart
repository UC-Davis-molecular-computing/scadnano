import 'dart:async';
import 'package:web/web.dart';

import 'package:path/path.dart' as path;

import '../app.dart';
import 'view.dart';
import '../middleware/oxview_update_view.dart';
import '../constants.dart' as constants;

class OxviewViewComponent {
  late HTMLDivElement div;
  late HTMLIFrameElement frame;

  OxviewViewComponent() {
    this.div = HTMLDivElement()
      ..setAttribute('id', OXVIEW_ID)
      ..setAttribute('class', 'split');
    this.frame = HTMLIFrameElement()
      ..setAttribute('height', '100%')
      ..setAttribute('width', '100%')
      ..setAttribute('src', 'https://sulcgroup.github.io/oxdna-viewer/')
      ..setAttribute('id', 'oxview-frame');
    this.div.append(this.frame);
  }
}
