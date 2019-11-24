import 'package:built_collection/built_collection.dart';

import '../app.dart';
import '../actions/actions_OLD.dart';
import 'select_mode.dart';

import 'package:built_value/built_value.dart';

part 'selectable.g.dart';

final DEFAULT_SelectablesStoreBuilder = SelectablesStoreBuilder()
  ..selectables_by_id = MapBuilder<String, Selectable>()
  ..selected_items = SetBuilder<Selectable>();

abstract class SelectablesStore implements Built<SelectablesStore, SelectablesStoreBuilder> {
  SelectablesStore._();

  factory SelectablesStore([void Function(SelectablesStoreBuilder) updates]) = _$SelectablesStore;

  BuiltMap<String, Selectable> get selectables_by_id;

  BuiltSet<Selectable> get selected_items; // => selected_items_factory();

  /// Registers unique ID of this Selectable so it can be reconciled with View component with same HTML id.
  SelectablesStore register(Selectable selectable) {
    String id = selectable.id();
//    selectables_by_id[id] = selectable;
    var selectables_by_id_builder = selectables_by_id.toBuilder();
    selectables_by_id_builder[id] = selectable;
    return rebuild((s) => s..selectables_by_id = selectables_by_id_builder);
  }

//  handle_actions() {
//    triggerOnActionV2(Actions.select, (obj) => select(obj));
//    triggerOnActionV2(Actions.select_all, (objs) => select_all(objs));
//    triggerOnActionV2(Actions.unselect, (obj) => unselect(obj));
//    triggerOnActionV2(Actions.toggle, (obj) => toggle(obj));
//    triggerOnActionV2(Actions.toggle_all, (objs) => toggle_all(objs));
//    triggerOnActionV2(Actions.unselect_all, (_) => clear());
//    triggerOnActionV2(Actions.delete_all, (_) => clear());
//  }

  bool selected(Selectable selectable) => selected_items.contains(selectable);

  SelectablesStore select(Selectable selectable) {
//    bool changed = selected_items.add(selectable);
//    if (changed) {
//      selectable.selected_field = true;
//    }
    var selected_items_builder = selected_items.toBuilder();
    selected_items_builder.add(selectable);
    return rebuild((s) => s..selected_items = selected_items_builder);
  }

  unselect(Selectable selectable) {
//    bool changed = selected_items.remove(selectable);
//    if (changed) {
//      selectable.selected_field = false;
//    }
    var selected_items_builder = selected_items.toBuilder();
    selected_items_builder.remove(selectable);
    return rebuild((s) => s..selected_items = selected_items_builder);
  }

  clear() {
    List<Selectable> old_selected_items = selected_items.toList();
//    selected_items.clear();
//    for (var selectable in old_selected_items) {
//      selectable.selected_field = false;
//    }
    return rebuild((s) => s..selected_items = SetBuilder<Selectable>());
  }

  // methods below here defined in terms of select and unselect
  select_all(Iterable<Selectable> selectables) {
//    for (var selectable in selectables) {
//      select(selectable);
//    }
    var selected_items_builder = selected_items.toBuilder();
    selected_items_builder.addAll(selectables);
    return rebuild((s) => s..selected_items = selected_items_builder);
  }

  toggle(Selectable selectable) {
    if (selected(selectable)) {
      return unselect(selectable);
    } else {
      return select(selectable);
    }
  }

  toggle_all(Iterable<Selectable> selectables) {
//    for (var selectable in selectables) {
//      toggle(selectable);
//    }
    var selected_items_builder = selected_items.toBuilder();
    for (var selectable in selectables) {
      if (selected_items.contains(selectable)) {
        selected_items_builder.remove(selectable);
      } else {
        selected_items_builder.add(selectable);
      }
    }
    return rebuild((s) => s..selected_items = selected_items_builder);
  }
}

/// Represents a part of the Model that represents a part of the View that is Selectable.
mixin Selectable {
  /// Subclasses must define this to be used to associate view element to model object through CSS selector.
  String id();

  /// Subclasses must define this to be able to be selectively selected.
  SelectModeChoice select_mode();

  //TODO: handle_selection is getting called twice on a single pointer down

  //XXX: Previously the type of event was SyntheticMouseEvent, but now we have a pointer event since
  // the Dart dnd library intercepts and prevent mouse events. Luckily that event has the
  // ctrlKey, metaKey, and shiftKey properties we need to check for.
  handle_selection(event) {
    if (app.model.ui_model.select_mode_state.is_selectable(this)) {
      if (event.nativeEvent.ctrlKey || event.nativeEvent.metaKey) {
        Actions_OLD.toggle(this);
      } else if (event.nativeEvent.shiftKey) {
        Actions_OLD.select(this);
      }
    }
  }

  bool selected() => app.model.ui_model.selectables_store.selected(this);

//  bool selected_field = false;

  String toString() => id();
}
