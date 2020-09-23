@JS()
library scadnano;

import 'package:js/js.dart';
import 'package:react/react_client.dart';
import 'package:react/react_client/react_interop.dart';

/// JS interop classes for [React Color](http://casesandberg.github.io/react-color/).
@JS()
class ReactColor {
  external static ReactClass get ChromePicker;
}

final ChromePicker = ReactJsComponentFactoryProxy(ReactColor.ChromePicker);
