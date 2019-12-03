import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import 'bound_substrand.dart';
import 'dna_design.dart';
import 'loopout.dart';
import 'select_mode.dart';

part 'selectable.g.dart';

final DEFAULT_SelectablesStoreBuilder = SelectablesStoreBuilder()
  ..selectables_by_id = MapBuilder<String, Selectable>()
  ..selected_items = SetBuilder<Selectable>();

abstract class SelectablesStore with BuiltJsonSerializable implements Built<SelectablesStore, SelectablesStoreBuilder> {
  SelectablesStore._();

  factory SelectablesStore([void Function(SelectablesStoreBuilder) updates]) = _$SelectablesStore;

  static Serializer<SelectablesStore> get serializer => _$selectablesStoreSerializer;

  /************************ end BuiltValue boilerplate ************************/

  BuiltMap<String, Selectable> get selectables_by_id;

  BuiltSet<Selectable> get selected_items; // => selected_items_factory();

  /// Registers unique ID of this Selectable so it can be reconciled with View component with same HTML id.
  SelectablesStore register(Selectable selectable) {
    var selectables_by_id_builder = selectables_by_id.toBuilder();
    String id = selectable.id();
    selectables_by_id_builder[id] = selectable;
    return rebuild((s) => s..selectables_by_id = selectables_by_id_builder);
  }

  SelectablesStore register_all(Iterable<Selectable> selectables) {
//    return this;
    var selectables_by_id_builder = selectables_by_id.toBuilder();
    for (var selectable in selectables) {
      String id = selectable.id();
      selectables_by_id_builder[id] = selectable;
    }
    var new_selectables_by_id = selectables_by_id_builder.build();
//    return rebuild((s) => s..selectables_by_id = selectables_by_id_builder);
    var new_store = this.rebuild((s) => s..selectables_by_id.replace(new_selectables_by_id));
    return new_store;
  }

  SelectablesStore register_dna_design(DNADesign design) {
    List<Selectable> selectables = [];
    for (var strand in design.strands) {
      selectables.add(strand);
      for (var substrand in strand.substrands) {
        if (substrand is Loopout) {
          selectables.add(substrand);
        } else
          if (substrand is BoundSubstrand) {
          selectables.add(substrand.dnaend_start);
          selectables.add(substrand.dnaend_end);
        }
      }
      for (var crossover in strand.crossovers) {
        selectables.add(crossover);
      }
    }
    return register_all(selectables);
  }

  bool get isEmpty => selected_items.isEmpty;

  bool get isNotEmpty => selected_items.isNotEmpty;

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
    if (app.state.ui_state.select_mode_state.is_selectable(this)) {
      if (event.nativeEvent.ctrlKey || event.nativeEvent.metaKey) {
        app.store.dispatch(actions.Select(this, true));
      } else if (event.nativeEvent.shiftKey) {
        app.store.dispatch(actions.Select(this, false));
      }
    }
  }

//  bool selected_field = false;

  String toString() => id();
}
