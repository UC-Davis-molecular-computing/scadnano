import 'package:logging/logging.dart';
import 'package:over_react/over_react.dart' hide ErrorBoundaryState, ErrorBoundaryProps;
import 'package:over_react/src/component/error_boundary.dart';
import 'package:over_react/src/component/error_boundary_api.dart';
import 'package:over_react/src/component/error_boundary_recoverable.dart';

import '../app.dart';
import '../constants.dart' as constants;
import '../actions/actions.dart' as actions;

part 'design_main_error_boundary.over_react.g.dart';

@Factory()
UiFactory<DesignMainErrorBoundaryProps> DesignMainErrorBoundary = _$DesignMainErrorBoundary;

@Props()
class DesignMainErrorBoundaryProps = UiProps with ErrorBoundaryProps;

mixin DesignMainErrorBoundaryStateMixin on UiState {
  dynamic error;
}

@State()
class DesignMainErrorBoundaryState = UiState with ErrorBoundaryState, DesignMainErrorBoundaryStateMixin;

@Component2(isWrapper: true, isErrorBoundary: true)
class DesignMainErrorBoundaryComponent<T extends DesignMainErrorBoundaryProps,
    S extends DesignMainErrorBoundaryState> extends UiStatefulComponent2<T, S> with ErrorBoundaryApi<T, S> {
  @override
  get defaultProps => (newProps()
    ..identicalErrorFrequencyTolerance = Duration(seconds: 5)
    ..loggerName = defaultErrorBoundaryLoggerName
    ..shouldLogErrors = true);

  @override
  get initialState => (newState()
    ..hasError = false
    ..showFallbackUIOnError = true);

  @override
  Map getDerivedStateFromError(error) => (newState()
    ..hasError = true
    ..error = error
    ..showFallbackUIOnError = true);

  @override
  void componentDidCatch(error, ReactErrorInfo info) {
    if (props.onComponentDidCatch != null) {
      props.onComponentDidCatch(error, info);
    }

    _logErrorCaughtByErrorBoundary(error, info);

    if (props.onComponentIsUnrecoverable != null) {
      props.onComponentIsUnrecoverable(error, info);
    }
  }

  @override
  render() {
    if (state.hasError) {
      var error = state.error;
//      var escaper = HtmlEscape();
      var escaped_error_message = 'You have discovered a bug in scadnano.  '
          'Please file a bug report as a GitHub issue at\n'
          '  ${constants.BUG_REPORT_URL}\n'
          'and include the following information:\n\n'
          '${error.toString()}\n\nstack trace:\n${error.stackTrace}' //escaper.convert(
          //  )
          ;

      send_error(escaped_error_message);
      return null;
    }
    return (RecoverableErrorBoundary()
      ..addTestId('RecoverableErrorBoundary')
      ..modifyProps(addUnconsumedProps))(props.children); // [1]
  }

  @override
  void componentDidUpdate(Map prevProps, Map prevState, [dynamic snapshot]) {
    // If the child is different, and the error boundary is currently in an error state,
    // give the children a chance to mount.
    if (state.hasError) {
      final childThatCausedError = typedPropsFactory(prevProps).children.single;
      if (childThatCausedError != props.children.single) {
        reset();
      }
    }
  }

  /// Resets the [ErrorBoundaryState] to a non-error state.
  ///
  /// This can be called manually on the component instance using a `ref` -
  /// or by passing in a new child instance after a child has thrown an error.
  void reset() {
    setState(initialState);
  }

  String get _loggerName {
    if (props.logger != null) return props.logger.name;

    return props.loggerName ?? defaultErrorBoundaryLoggerName;
  }

  void _logErrorCaughtByErrorBoundary(
    /*Error|Exception*/ dynamic error,
    ReactErrorInfo info, {
    bool isRecoverable = true,
  }) {
    if (!props.shouldLogErrors) return;

    final message =
        'An unrecoverable error was caught by an ErrorBoundary (attempting to remount it was unsuccessful): \nInfo: ${info.componentStack}';

    (props.logger ?? Logger(_loggerName)).severe(message, error, info.dartStackTrace);
  }
}

send_error(String escaped_error_message) async{
  app.dispatch(actions.ErrorMessageSet(escaped_error_message));
  app.view.design_view.render(app.state);
}
