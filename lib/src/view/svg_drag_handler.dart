import 'dart:async';
import 'dart:html';
// `Point` looks "unnecessarily" imported only because dart:html re-exports it from dart:math.
// package:web does not, so keep this explicit — it makes the issue #1029 port a no-op here.
// ignore: unnecessary_import
import 'dart:math';
import 'dart:svg' as svg;

/// Detects a click-and-drag gesture on an SVG element using native Pointer Events.
///
/// This replaces `package:dnd`, which was unmaintained (last published 2021) and depended on
/// `dart:html` and the removed-in-future `dart:js`. See issue #1123.
///
/// We only ever used `package:dnd` as a drag *gesture detector* — never its drop zones, drag
/// avatars, or HTML5 drag-and-drop support — so this is a direct, much smaller replacement.
///
/// Two behaviors here are deliberate improvements over `package:dnd`:
///
/// * [preventDefault] is called only when a gesture actually begins ([should_start] returned
///   true). `package:dnd` called it on *every* pointer-down on a non-form-control, which
///   suppressed the mouse events the svg-pan-zoom library listens to. That is why the old code
///   had to install and uninstall the `Draggable` on every Ctrl/Shift key-down/up cycle.
/// * Pointer capture (see [Element.setPointerCapture]) keeps `pointermove` / `pointerup`
///   arriving at [element] even when the pointer leaves its bounds or the window, so there is no
///   need for document-level listeners. The capture is released automatically by the browser on
///   `pointerup` / `pointercancel`, so a drag cannot get stuck the way the old
///   `.dnd-drag-occurring` body class did.
///
/// MIGRATION NOTE (issue #1029): every API used here exists with the same shape in
/// `package:web`, so porting this file is mechanical — swap `import 'dart:html'` for
/// `import 'package:web/web.dart'` and drop the `!` on [PointerEvent.pointerId], which is
/// non-nullable there.
typedef PointerDragCallback = void Function(PointerEvent event);

class SvgDragHandler {
  static const _pointer_down = EventStreamProvider<PointerEvent>('pointerdown');
  static const _pointer_move = EventStreamProvider<PointerEvent>('pointermove');
  static const _pointer_up = EventStreamProvider<PointerEvent>('pointerup');
  static const _pointer_cancel = EventStreamProvider<PointerEvent>('pointercancel');

  /// Pixels the pointer must move before the gesture counts as a drag.
  /// Same default as `package:dnd`'s `minDragStartDistance`; without it a bare Ctrl+click
  /// would create and instantly resolve a zero-size selection box.
  static const int default_min_drag_start_distance = 4;

  final svg.SvgSvgElement element;

  /// Consulted on pointer-down. Return false to ignore the gesture entirely, leaving the event
  /// untouched so svg-pan-zoom (and everything else) behaves normally.
  final bool Function(PointerEvent event) should_start;

  /// Fired once, when the pointer first moves past [min_drag_start_distance].
  final PointerDragCallback on_drag_start;

  /// Fired on each subsequent move.
  final PointerDragCallback on_drag;

  /// Fired on pointer-up / pointer-cancel, but only if [on_drag_start] fired first.
  final PointerDragCallback on_drag_end;

  final int min_drag_start_distance;

  int? _pointer_id;
  Point<num>? _start_client;
  bool _started = false;
  final List<StreamSubscription> _subscriptions = [];

  SvgDragHandler(
    this.element, {
    required this.should_start,
    required this.on_drag_start,
    required this.on_drag,
    required this.on_drag_end,
    this.min_drag_start_distance = default_min_drag_start_distance,
  }) {
    _subscriptions.addAll([
      _pointer_down.forTarget(element).listen(_handle_pointer_down),
      _pointer_move.forTarget(element).listen(_handle_pointer_move),
      _pointer_up.forTarget(element).listen(_handle_pointer_end),
      _pointer_cancel.forTarget(element).listen(_handle_pointer_end),
    ]);
  }

  /// True from pointer-down until pointer-up/cancel, whether or not [min_drag_start_distance]
  /// was exceeded. Used to stop other pointer-down/mouse-down listeners from interfering.
  bool get gesture_in_progress => _pointer_id != null;

  /// True only once the drag threshold has been passed and [on_drag_start] has fired.
  bool get dragging => _started;

  _handle_pointer_down(PointerEvent event) {
    if (_pointer_id != null) return; // already tracking a pointer; ignore a second finger/stylus
    if (event.button != 0) return; // left button only
    if (!should_start(event)) return;

    _pointer_id = event.pointerId;
    _start_client = event.client;
    _started = false;

    element.setPointerCapture(event.pointerId!);

    // Only now that we have committed to the gesture: suppress the compatibility mouse events
    // and text selection. Doing this unconditionally is what broke panning in package:dnd.
    event.preventDefault();
  }

  _handle_pointer_move(PointerEvent event) {
    if (_pointer_id == null || event.pointerId != _pointer_id) return;

    if (!_started) {
      if (_start_client!.distanceTo(event.client) < min_drag_start_distance) return;
      _started = true;
      on_drag_start(event);
    } else {
      on_drag(event);
    }
  }

  _handle_pointer_end(PointerEvent event) {
    if (_pointer_id == null || event.pointerId != _pointer_id) return;

    bool was_dragging = _started;
    _reset(event.pointerId!);
    if (was_dragging) {
      on_drag_end(event);
    }
  }

  _reset(int pointer_id) {
    if (element.hasPointerCapture(pointer_id)) {
      element.releasePointerCapture(pointer_id);
    }
    _pointer_id = null;
    _start_client = null;
    _started = false;
  }

  /// Aborts any gesture in progress *without* firing [on_drag_end]; the caller is responsible for
  /// whatever cleanup it needs. Used when the modifier key is released or the window loses focus.
  ///
  /// Returns true if a drag had actually started (i.e. [on_drag_start] had fired).
  bool cancel() {
    if (_pointer_id == null) return false;
    bool was_dragging = _started;
    _reset(_pointer_id!);
    return was_dragging;
  }

  /// Cancels any gesture in progress and removes all listeners.
  void destroy() {
    cancel();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
