import 'dart:async';

import 'package:over_react/over_react.dart';
import 'package:w_flux/w_flux.dart';

import '../dispatcher/actions.dart';

/// Represents a part of the Model that represents a part of the View that is Selectable.
mixin Selectable<T extends Store> {
  Set<Selectable<T>> Function() _selected_items_factory;
  Set<Selectable<T>> get selected_items => _selected_items_factory();

  bool selected() => selected_items.contains(this);

  _select() => selected_items.add(this);

  _unselect() => selected_items.remove(this);

  _toggle() => selected() ? _unselect() : _select();

  handle_selection(SyntheticMouseEvent event) {
    if (_selected_items_factory == null) {
      throw ArgumentError('class ${this.runtimeType} using mixin Selectable must call '
          'trigger_on_select_toggle_actions in constructor');
    }

    if (event.ctrlKey) {
//      print('sending toggle action');
      Actions.toggle(this);
    } else if (event.shiftKey) {
//      print('sending select action');
      Actions.select(this);
    }
  }

  trigger_on_select_toggle_actions(Set<Selectable<T>> Function() selected_items_factory,
      [FutureOr<dynamic> on_action(T the_payload)]) {
    _selected_items_factory = selected_items_factory;
    Actions.select.listen((selectable_obj) {
      if (selectable_obj == this) {
        var store = selectable_obj as Store;
//        print('action select fired');
//        print('  selected before: ${selected_items}');
        _select();
//        print('  selected after:  ${selected_items}');
        store.trigger();

      }
    });

    Actions.toggle.listen((selectable_obj) {
      if (selectable_obj == this) {
        var store = selectable_obj as Store;
//        print('action toggle fired');
//        print('  selected before: ${selected_items}');
        _toggle();
//        print('  selected after:  ${selected_items}');
        store.trigger();
      }
    });

    Actions.remove_all_selections.listen((_) {
      if (selected()) {
        var store = this as Store;
//        print('action unselect fired');
//        print('  selected before: ${selected_items}');
        _unselect();
//        print('  selected after:  ${selected_items}');
        store.trigger();
      }
    });
  }
}
