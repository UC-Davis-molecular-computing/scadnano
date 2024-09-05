import 'dart:async';
import 'dart:html';

import 'package:path/path.dart' as path;
import 'package:codemirror/codemirror.dart';
import 'package:codemirror/hints.dart';

import '../app.dart';
import '../constants.dart' as constants;

class OxviewViewComponent {
  DivElement root_element;

  OxviewViewComponent(this.root_element) {
    var iframe_element = IFrameElement()
      ..attributes = {
        'height': '100%',
        'width': '100%',
        'src': 'https://sulcgroup.github.io/oxdna-viewer/',
        'id': 'oxview-frame'
      };
    this.root_element.children.add(iframe_element);
  }
}

