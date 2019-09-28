/// Copied from: https://github.com/greglittlefield-wf/react-dart/blob/js_components/lib/react_client.dart
/// Used to allow ReactJS components defined in JS to be used by dart-react and over_react

import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import "package:react/react.dart";
import "package:react/react_client.dart";
import "package:react/react_client/js_interop_helpers.dart"
    hide getProperty, setProperty, jsify;
import 'package:react/react_client/react_interop.dart';
import "package:react/react_dom.dart";
import "package:react/react_dom_server.dart";
import "package:react/src/react_client/synthetic_event_wrappers.dart" as events;
import "package:react/src/react_client/event_prop_key_to_event_factory.dart";

/// Creates ReactJS [ReactElement] instances for components defined in the JS.
class ReactJsComponentFactoryProxy extends ReactComponentFactoryProxy {
  /// The JS class used by this factory.
  @override
  final ReactClass type;
  final bool isContextComponent;

  /// The JS component factory used by this factory to build [ReactElement]s.
  final Function factory;

  /// Whether to automatically prepare props relating to bound values and event handlers
  /// via [ReactDomComponentFactoryProxy.convertProps] for consumption by React JS DOM components.
  ///
  /// Useful when the JS component forwards DOM props to its rendered DOM components.
  ///
  /// Disable for more custom handling of these props.
  final bool convertDomProps;

  ReactJsComponentFactoryProxy(ReactClass jsClass,
      {bool this.convertDomProps: true, bool this.isContextComponent: false})
      : this.type = jsClass,
        this.factory = React.createFactory(jsClass) {
    print('in ReactJsComponentFactoryProxy constructor');
    if (jsClass == null) {
      throw new ArgumentError('`jsClass` must not be null. '
          'Ensure that the JS component class you\'re referencing is available and being accessed correctly.');
    }
  }

  @override
  ReactElement build(Map<dynamic, dynamic> props, [List childrenArgs]) {
    dynamic potentiallyConvertedProps;
    dynamic children = _convertArgsToChildren(childrenArgs);

    if (isContextComponent) {
      if (props.containsKey('value')) {
        potentiallyConvertedProps = new Map.from(props);
        potentiallyConvertedProps['value'] =
            _jsifyContext(potentiallyConvertedProps['value']);
      }
      if (children is Function) {
        Function contextCallback = children;
        children = allowInterop((args) {
          return contextCallback(_unjsifyContext(args));
        });
      }
    }

    if (convertDomProps) {
      // We can't mutate the original since we can't be certain that the value of the
      // the converted event handler will be compatible with the Map's type parameters.
      potentiallyConvertedProps ??= new Map.from(props);
      _convertEventHandlers(potentiallyConvertedProps);
    } else {
      potentiallyConvertedProps ??= props;
    }

    return factory(jsifyAndAllowInterop(potentiallyConvertedProps), children);
  }
}


/// Converts a list of variadic children arguments to children that should be passed to ReactJS.
///
/// Returns:
///
/// - `null` if there are no args
/// - the single child if only one was specified
/// - otherwise, the same list of args, will all top-level children validated
dynamic _convertArgsToChildren(List childrenArgs) {
  if (childrenArgs.isEmpty) {
    return null;
  } else if (childrenArgs.length == 1) {
    return childrenArgs.single;
  } else {
    markChildrenValidated(childrenArgs);
    return childrenArgs;
  }
}


/// Convert packed event handler into wrapper and pass it only the Dart [SyntheticEvent] object converted from the
/// [events.SyntheticEvent] event.
_convertEventHandlers(Map args) {
  var zone = Zone.current;
  args.forEach((propKey, value) {
    var eventFactory = eventPropKeyToEventFactory[propKey];
    if (eventFactory != null && value != null) {
      // Apply allowInterop here so that the function we store in [_originalEventHandlers]
      // is the same one we'll retrieve from the JS props.
      var reactDartConvertedEventHandler =
      allowInterop((events.SyntheticEvent e, [_, __]) => zone.run(() {
        value(eventFactory(e));
      }));

      args[propKey] = reactDartConvertedEventHandler;
      _originalEventHandlers[reactDartConvertedEventHandler] = value;
    }
  });
}


InteropContextValue _jsifyContext(context) {
  var interopContext = new InteropContextValue();
  setProperty(interopContext, '___internal_dart_context_value___',
      new ReactDartContextInternal(context));
  return interopContext;
}

dynamic _unjsifyContext(interopContext) {
  return getProperty(interopContext, '___internal_dart_context_value___')
      ?.value;
}

/// A mapping from converted/wrapped JS handler functions (the result of [_convertEventHandlers])
/// to the original Dart functions (the input of [_convertEventHandlers]).
final Expando<Function> _originalEventHandlers = new Expando();
