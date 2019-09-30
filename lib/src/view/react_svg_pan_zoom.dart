@JS()
library react_svg_pan_zoom;

import 'package:js/js.dart';
import 'package:react/react_client/react_interop.dart';
import 'package:react/react_dom.dart' as react_dom;

import '../react_js.dart';

@JS('react_uncontrolled_svg_pan_zoom')
external react_uncontrolled_svg_pan_zoom();

/// Accessible via `UncontrolledReactSVGPanZoom.type`.
//@JS('UncontrolledReactSVGPanZoom')
//external ReactClass get _UncontrolledReactSVGPanZoom;
ReactClass get _UncontrolledReactSVGPanZoom => react_uncontrolled_svg_pan_zoom();

/// A factory for the "Foo" JS components class that allows it
/// to be used via Dart code.
///
/// Use this to render instances of the component from within Dart code.
///
/// This converts the Dart props [Map] passed into it in the
/// the same way props are converted for DOM components.
final UncontrolledReactSVGPanZoom = ReactJsComponentFactoryProxy(_UncontrolledReactSVGPanZoom);

/// JS interop wrapper class for the component,
/// allowing us to interact with component instances
/// made available via refs or [react_dom.render] calls.
///
/// This is optional, as you won't always need to access the component's API.
@JS()
class UncontrolledReactSVGPanZoomComponent {}

//////////////////////////////////////////////////////////////////////
// autosizer
@JS('autosizer')
external autosizer();

ReactClass get _AutoSizer => autosizer();

final AutoSizer = ReactJsComponentFactoryProxy(_AutoSizer);

@JS()
class AutoSizerComponent {}
