import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:w_flux/w_flux.dart';

import '../app.dart';
import '../dispatcher/actions.dart';
import 'select_mode.dart';

/// Represents a part of the Model that represents a part of the View that is Selectable.
mixin Selectable {
  /// Subclasses must define this to be used to associate view element to model object through CSS selector.
  String id();

  /// Subclasses must define this to be able to be selectively selected.
  SelectModeChoice select_mode();

  //TODO: handle_selection is getting called twice on a single pointer down

  //XXX: Previously the type of event was SyntheticMouseEvent, but now we have a pointer event since
  // the Dart dnd library intercepts and prevent mouse events. Luckily that event has the
  // ctrlKey and shiftKey properties we need to check for.
  handle_selection(event) {
    if (app.model.select_mode_store.is_selectable(this)) {
      if (event.nativeEvent.ctrlKey) {
        Actions.toggle(this);
      } else if (event.nativeEvent.shiftKey) {
        Actions.select(this);
      }
    }
  }

  bool selected() => app.model.dna_design.selectable_store.selected(this);

  bool selected_field = false;

  String toString() => id();

}

class SelectablesStore extends Store {
  final selectables_by_id = Map<String, Selectable>();
//  final views_by_id = Map<String, UiComponent>();

  final Set<Selectable> Function() selected_items_factory;

  Set<Selectable> get selected_items => selected_items_factory();

  SelectablesStore(this.selected_items_factory);

  /// Registers unique ID of this Selectable so it can be reconciled with View component with same HTML id.
  register(Selectable selectable) {
    String id = selectable.id();
    selectables_by_id[id] = selectable;
  }

//  register_component(UiComponent comp, String id) {
//    views_by_id[id] = comp;
//  }

  handle_actions() {
    triggerOnActionV2(Actions.select, (obj) => select(obj));
    triggerOnActionV2(Actions.select_all, (objs) => select_all(objs));
    triggerOnActionV2(Actions.unselect, (obj) => unselect(obj));
    triggerOnActionV2(Actions.toggle, (obj) => toggle(obj));
    triggerOnActionV2(Actions.toggle_all, (objs) => toggle_all(objs));
    triggerOnActionV2(Actions.unselect_all, (_) => clear());
    triggerOnActionV2(Actions.delete_all, (_) => clear());
  }

  bool selected(Selectable selectable) => selected_items.contains(selectable);

  select(Selectable selectable) {
    bool changed = selected_items.add(selectable);
    if (changed) {
//      selectable.trigger();
      selectable.selected_field = true;
    }
  }

  unselect(Selectable selectable) {
    bool changed = selected_items.remove(selectable);
    if (changed) {
//      selectable.trigger();
      selectable.selected_field = false;
    }
  }

  clear() {
    List<Selectable> old_selected_items = selected_items.toList();
    selected_items.clear();
    for (var selectable in old_selected_items) {
//      selectable.trigger();
      selectable.selected_field = false;
    }
  }

  // methods below here defined in terms of select and unselect
  select_all(Iterable<Selectable> selectables) {
    for (var selectable in selectables) {
      select(selectable);
    }
  }

  toggle(Selectable selectable) {
    if (selected(selectable)) {
      unselect(selectable);
    } else {
      select(selectable);
    }
  }

  toggle_all(Iterable<Selectable> selectables) {
    for (var selectable in selectables) {
      toggle(selectable);
    }
  }

}
