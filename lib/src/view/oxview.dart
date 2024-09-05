import 'dart:async';
import 'dart:html';

import 'package:path/path.dart' as path;
import 'package:codemirror/codemirror.dart';
import 'package:codemirror/hints.dart';

import '../app.dart';
import '../constants.dart' as constants;

//TODO: compile Python scripts in the browser using pyodide (or something)

/// This should only be created once in the app lifetime, so not much happens in the render() method.
/// Since it uses the CodeMirror library, it falls a bit outside of the reactive component framework of the
/// rest of the view and acts more like an outside agent communicating with the rest of the app.
/// (except for the fact that the app can choose to hide or show it, but it remains "rendered" in the background
/// and is simply removed from/added to the DOM)
///
/// However, other than being hidden/shown, this does not react to any changes happening outside of its element.
/// The updating of its source code goes through the normal event loop but only involves elements in this component.
class OxviewViewComponent {
  DivElement root_element;

  OxviewViewComponent(this.root_element) {
    var iframe_element = IFrameElement()
      ..attributes = {
        'height': '100%',
        'src': 'https://sulcgroup.github.io/oxdna-viewer/',
        'id': 'oxview-frame'
      };
    this.root_element.children.add(iframe_element);
  }
}

