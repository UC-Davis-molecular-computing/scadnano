import 'dart:async';
import 'dart:html';

import 'package:path/path.dart' as path;

import '../app.dart';
import 'view.dart';
import '../middleware/oxview_update_view.dart';
import '../constants.dart' as constants;

class OxviewViewComponent {
  late DivElement div;
  late IFrameElement frame;

  OxviewViewComponent() {
    this.div = DivElement()..attributes = {'id': OXVIEW_ID, 'class': 'split'};
    this.frame =
        IFrameElement()
          ..attributes = {
            'height': '100%',
            'width': '100%',
            'src': 'https://sulcgroup.github.io/oxdna-viewer/',
            'id': 'oxview-frame',
          };
    this.div.children.add(this.frame);
  }
}
