import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import '../actions/actions.dart' as actions;
import 'crossover.dart';
import 'loopout.dart';
import 'dna_end.dart';
import 'select_mode.dart';
import 'edit_mode.dart';
import 'strand.dart';
import '../app.dart';

part 'selectable.g.dart';

final DEFAULT_SelectablesStoreBuilder = SelectablesStoreBuilder();

abstract class SelectablesStore
    with BuiltJsonSerializable
    implements Built<SelectablesStore, SelectablesStoreBuilder> {
  BuiltSet<Selectable> get selected_items;

  static void _initializeBuilder(SelectablesStoreBuilder b) {
    b.selected_items = SetBuilder<Selectable>([]);
  }

  @memoized
  BuiltSet<Strand> get selected_strands => BuiltSet<Strand>.from(selected_items.where((s) => s is Strand));

  @memoized
  BuiltSet<Crossover> get selected_crossovers =>
      BuiltSet<Crossover>.from(selected_items.where((s) => s is Crossover));

  @memoized
  BuiltSet<Loopout> get selected_loopouts =>
      BuiltSet<Loopout>.from(selected_items.where((s) => s is Loopout));

  @memoized
  BuiltSet<DNAEnd> get selected_dna_ends => BuiltSet<DNAEnd>.from(selected_items.where((s) => s is DNAEnd));

  bool get isEmpty => selected_items.isEmpty;

  bool get isNotEmpty => selected_items.isNotEmpty;

  bool selected(Selectable selectable) => selected_items.contains(selectable);

  /// adds [selectable] to selected items. If only=true, deselects all other items.
  SelectablesStore select(Selectable selectable, {bool only = false}) {
    var selected_items_builder = selected_items.toBuilder();
    if (only) {
      selected_items_builder.clear();
    }
    selected_items_builder.add(selectable);
    return rebuild((s) => s..selected_items = selected_items_builder);
  }

  /// removes [selectable] from selected items.
  SelectablesStore unselect(Selectable selectable) {
    var selected_items_builder = selected_items.toBuilder();
    selected_items_builder.remove(selectable);
    return rebuild((s) => s..selected_items = selected_items_builder);
  }

  /// removes all selectables from store
  SelectablesStore clear() {
    return rebuild((s) => s..selected_items = SetBuilder<Selectable>());
  }

  // methods below here defined in terms of select and unselect
  SelectablesStore select_all(Iterable<Selectable> selectables, {bool only = false}) {
    var selected_items_builder = selected_items.toBuilder();
    if (only) {
      selected_items_builder.clear();
    }
    selected_items_builder.addAll(selectables);
    return rebuild((s) => s..selected_items = selected_items_builder);
  }

  SelectablesStore toggle(Selectable selectable) {
    if (selected(selectable)) {
      return unselect(selectable);
    } else {
      return select(selectable);
    }
  }

  SelectablesStore toggle_all(Iterable<Selectable> selectables) {
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

  /************************ begin BuiltValue boilerplate ************************/
  SelectablesStore._();

  factory SelectablesStore([void Function(SelectablesStoreBuilder) updates]) = _$SelectablesStore;

  static Serializer<SelectablesStore> get serializer => _$selectablesStoreSerializer;

  @memoized
  int get hashCode;

  BuiltSet<DNAEnd> selected_ends_in_strand(Strand strand) {
    return [
      for (var domain in strand.domains())
        for (var end in [domain.dnaend_5p, domain.dnaend_3p]) if (this.selected_dna_ends.contains(end)) end
    ].toBuiltSet();
  }

  BuiltSet<Crossover> selected_crossovers_in_strand(Strand strand) {
    return [
      for (var crossover in strand.crossovers) if (this.selected_crossovers.contains(crossover)) crossover
    ].toBuiltSet();
  }

  BuiltSet<Loopout> selected_loopouts_in_strand(Strand strand) {
    return [for (var loopout in strand.loopouts()) if (this.selected_loopouts.contains(loopout)) loopout]
        .toBuiltSet();
  }
}

/// Represents a part of the Model that represents a part of the View that is Selectable.
mixin Selectable {
  /// Subclasses must define this to be used to associate view element to state object through CSS selector.
  String id();

  /// Subclasses must define this to be able to be selectively selected.
  SelectModeChoice select_mode();

  bool get is_scaffold;

  //XXX: Previously the type of event was SyntheticMouseEvent, but now we have a pointer event since
  // the Dart dnd library intercepts and prevent mouse events. Luckily that event has the
  // ctrlKey, metaKey, and shiftKey properties we need to check for.
//  handle_selection(react.SyntheticPointerEvent event) {
  handle_selection_mouse_down(MouseEvent event) {
    if (event.ctrlKey || event.metaKey) {
      app.dispatch(actions.Select(this, toggle: true));
    } else {
      // add to selection on mouse down
      app.dispatch(actions.Select(this, toggle: false));
    }
  }

  // We choose to use the mouse up event to deselect other selections. Otherwise it is difficult to select
  // multiple items and then move them, because the click that attempts to move them is done without the
  // Shift or Ctrl key, so if we deselected whenever the user clicks without those keys, we would not be
  // able to move multiple items.
  handle_selection_mouse_up(MouseEvent event) {
    if (!(event.ctrlKey || event.metaKey || event.shiftKey)) {
      app.dispatch(actions.Select(this, toggle: false, only: true));
    }
  }
}

// functions accessing global app variable to detect selectability; WARNING, only call from event handlers

BuiltSet<EditModeChoice> edit_modes() => app.state.ui_state.edit_modes;

BuiltSet<SelectModeChoice> select_modes() => app.state.ui_state.select_mode_state.modes;

bool edit_mode_is_select() => edit_modes().contains(EditModeChoice.select);

bool edit_mode_is_pencil() => edit_modes().contains(EditModeChoice.pencil);

bool edit_mode_is_nick() => edit_modes().contains(EditModeChoice.nick);

bool edit_mode_is_ligate() => edit_modes().contains(EditModeChoice.ligate);

bool edit_mode_is_insertion() => edit_modes().contains(EditModeChoice.insertion);

bool edit_mode_is_deletion() => edit_modes().contains(EditModeChoice.deletion);

bool edit_mode_is_backbone() => edit_modes().contains(EditModeChoice.backbone);

bool strand_selectable(Strand strand) =>
    edit_mode_is_select() &&
    select_modes().contains(SelectModeChoice.strand) &&
    origami_type_selectable(strand);

bool crossover_selectable(Crossover crossover) =>
    edit_mode_is_select() &&
    select_modes().contains(SelectModeChoice.crossover) &&
    origami_type_selectable(crossover);

bool loopout_selectable(Loopout loopout) =>
    edit_mode_is_select() &&
    select_modes().contains(SelectModeChoice.loopout) &&
    origami_type_selectable(loopout);

bool end_selectable(DNAEnd end) =>
    edit_mode_is_select() && end_type_selectable(end) && origami_type_selectable(end);

bool end_type_selectable(DNAEnd end) =>
    (end.is_5p && end.substrand_is_first && select_modes().contains(SelectModeChoice.end_5p_strand)) ||
    (end.is_5p && !end.substrand_is_first && select_modes().contains(SelectModeChoice.end_5p_domain)) ||
    (!end.is_5p && end.substrand_is_last && select_modes().contains(SelectModeChoice.end_3p_strand)) ||
    (!end.is_5p && !end.substrand_is_last && select_modes().contains(SelectModeChoice.end_3p_domain));

bool scaffold_selectable() => select_modes().contains(SelectModeChoice.scaffold);

bool staple_selectable() => select_modes().contains(SelectModeChoice.staple);

bool origami_type_selectable(Selectable selectable) {
  if (!app.state.dna_design.is_origami) {
    return true;
  }
  if (selectable.is_scaffold) {
    return select_modes().contains(SelectModeChoice.scaffold);
  } else {
    return select_modes().contains(SelectModeChoice.staple);
  }
}
