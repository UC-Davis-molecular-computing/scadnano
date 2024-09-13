@JS()
library scadnano;

import 'package:js/js.dart';
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';

/// JS interop classes for [React Color](http://casesandberg.github.io/react-color/).
@JS()
class ReactColor {
  external static ReactClass get ChromePicker;

  external static ReactClass get SketchPicker;
}

// Avoid using Chrome due to bug: https://github.com/UC-Davis-molecular-computing/scadnano/issues/547
final ChromePicker = ReactJsComponentFactoryProxy(ReactColor.ChromePicker);
final SketchPicker = ReactJsComponentFactoryProxy(ReactColor.SketchPicker);
