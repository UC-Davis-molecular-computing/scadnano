import 'dart:async';

import 'package:meta/meta.dart';
import 'package:over_react/over_react.dart';

mixin RedrawCounterMixin<T extends UiProps> on UiComponent2<T> {
  int _desiredRedrawCount = 1;
  Completer<int> _didRedraw = Completer<int>();

  @visibleForTesting
  Completer<int> didRedraw([int desiredRedrawCount = 1]) {
    _desiredRedrawCount = desiredRedrawCount;
    return _didRedraw;
  }

  @visibleForTesting
  int redrawCount = 0;

  @override
  @mustCallSuper
  void componentDidUpdate(__, ___, [____]) {
    super.componentDidUpdate(__, ___, ____);

    redrawCount++;
    if (redrawCount < _desiredRedrawCount) {
      return;
    }
    _didRedraw.complete(redrawCount);
    _didRedraw = Completer<int>();
  }
}
