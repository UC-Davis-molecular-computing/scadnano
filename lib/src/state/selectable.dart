import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import '../actions/actions.dart' as actions;
import 'crossover.dart';
import 'domain.dart';
import 'helix.dart';
import 'loopout.dart';
import 'dna_end.dart';
import 'modification.dart';
import 'select_mode.dart';
import 'edit_mode.dart';
import 'strand.dart';
import '../app.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

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
  BuiltSet<Domain> get selected_domains => BuiltSet<Domain>.from(selected_items.where((s) => s is Domain));

  @memoized
  BuiltSet<DNAEnd> get selected_dna_ends => BuiltSet<DNAEnd>.from(selected_items.where((s) => s is DNAEnd));

  @memoized
  BuiltSet<SelectableDeletion> get selected_deletions =>
      BuiltSet<SelectableDeletion>.from(selected_items.where((s) => s is SelectableDeletion));

  @memoized
  BuiltSet<SelectableInsertion> get selected_insertions =>
      BuiltSet<SelectableInsertion>.from(selected_items.where((s) => s is SelectableInsertion));

  @memoized
  BuiltSet<SelectableModification> get selected_modifications =>
      BuiltSet<SelectableModification>.from(selected_items.where((s) => s is SelectableModification));

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

  BuiltSet<DNAEnd> selected_ends_in_strand(Strand strand) => {
        for (var domain in strand.domains())
          for (var end in [domain.dnaend_5p, domain.dnaend_3p])
            if (selected_dna_ends.contains(end)) end
      }.build();

  BuiltSet<Crossover> selected_crossovers_in_strand(Strand strand) => {
        for (var crossover in strand.crossovers)
          if (selected_crossovers.contains(crossover)) crossover
      }.build();

  BuiltSet<Loopout> selected_loopouts_in_strand(Strand strand) => {
        for (var loopout in strand.loopouts())
          if (selected_loopouts.contains(loopout)) loopout
      }.build();

  BuiltSet<Domain> selected_domains_in_strand(Strand strand) => {
        for (var domain in strand.domains())
          if (selected_domains.contains(domain)) domain
      }.build();

  BuiltSet<SelectableDeletion> selected_deletions_in_strand(Strand strand) {
    Set<SelectableDeletion> deletions = {};
    for (var domain in strand.domains()) {
      for (int offset in domain.deletions) {
        for (var deletion in selected_deletions) {
          if (deletion.offset == offset && deletion.domain == domain) {
            deletions.add(deletion);
          }
        }
      }
    }
    return deletions.build();
  }

  BuiltSet<SelectableInsertion> selected_insertions_in_strand(Strand strand) {
    Set<SelectableInsertion> insertions = {};
    for (var domain in strand.domains()) {
      for (Insertion insertion in domain.insertions) {
        for (var selectable_insertion in selected_insertions) {
          if (selectable_insertion.insertion == insertion && selectable_insertion.domain == domain) {
            insertions.add(selectable_insertion);
          }
        }
      }
    }
    return insertions.build();
  }

  BuiltSet<SelectableModification> selected_modifications_in_strand(Strand strand) {
    Set<SelectableModification> modifications = {};

    for (var mod_selected in selected_modifications) {
      if (mod_selected.strand_id == strand.id) {
        modifications.add(mod_selected);
      }
    }

    return modifications.build();
  }

  /************************ begin BuiltValue boilerplate ************************/
  SelectablesStore._();

  factory SelectablesStore([void Function(SelectablesStoreBuilder) updates]) = _$SelectablesStore;

  static Serializer<SelectablesStore> get serializer => _$selectablesStoreSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectableDeletion
    with SelectableMixin, BuiltJsonSerializable
    implements Built<SelectableDeletion, SelectableDeletionBuilder> {
  int get offset;

  Domain get domain;

  bool get is_scaffold;

  String get strand_id => domain.strand_id;

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.deletion;

  Address get address => Address(helix_idx: domain.helix, offset: offset, forward: domain.forward);

  @memoized
  String get id => util.id_deletion(domain, offset);

  /************************ begin BuiltValue boilerplate ************************/

  factory SelectableDeletion({int offset, Domain domain, bool is_scaffold}) = _$SelectableDeletion._;

  factory SelectableDeletion.from([void Function(SelectableDeletionBuilder) updates]) = _$SelectableDeletion;

  SelectableDeletion._();

  static Serializer<SelectableDeletion> get serializer => _$selectableDeletionSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectableInsertion
    with SelectableMixin, BuiltJsonSerializable
    implements Built<SelectableInsertion, SelectableInsertionBuilder> {
  Insertion get insertion;

  Domain get domain;

  bool get is_scaffold;

  String get strand_id => domain.strand_id;

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.insertion;

  Address get address => Address(helix_idx: domain.helix, offset: insertion.offset, forward: domain.forward);

  @memoized
  String get id => util.id_insertion(domain, insertion.offset);

  // needed to have an ID separate from the curve ID (used for selection box),
  // which is used to intercept the context menu on any right-click in the whole group;
  // see componentDidMount and componentWillUnmount in design_main_strand_insertion.dart
  @memoized
  String get id_group => id + '-group';

  /************************ begin BuiltValue boilerplate ************************/

  factory SelectableInsertion({Insertion insertion, Domain domain, bool is_scaffold}) =
      _$SelectableInsertion._;

  factory SelectableInsertion.from([void Function(SelectableInsertionBuilder) updates]) =
      _$SelectableInsertion;

  SelectableInsertion._();

  static Serializer<SelectableInsertion> get serializer => _$selectableInsertionSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectableModification implements Selectable {
  Modification get modification;

  Strand get strand;

  Address get address;

  bool get is_scaffold => strand.is_scaffold;

  @memoized
  String get strand_id => strand.id;

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.modification;
}

abstract class SelectableModification5Prime
    with SelectableModification, SelectableMixin, BuiltJsonSerializable
    implements Built<SelectableModification5Prime, SelectableModification5PrimeBuilder> {
  Modification5Prime get modification;

  Strand get strand;

  @memoized
  Address get address {
    var dom = strand.first_domain;
    return Address(helix_idx: dom.helix, offset: dom.offset_5p, forward: dom.forward);
  }

  @memoized
  String get id => util.id_modification_5p(strand, modification);

  /************************ begin BuiltValue boilerplate ************************/

  factory SelectableModification5Prime({Modification5Prime modification, Strand strand}) =
      _$SelectableModification5Prime._;

  factory SelectableModification5Prime.from([void Function(SelectableModification5PrimeBuilder) updates]) =
      _$SelectableModification5Prime;

  SelectableModification5Prime._();

  static Serializer<SelectableModification5Prime> get serializer => _$selectableModification5PrimeSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectableModification3Prime
    with SelectableModification, SelectableMixin, BuiltJsonSerializable
    implements Built<SelectableModification3Prime, SelectableModification3PrimeBuilder> {
  Modification3Prime get modification;

  Strand get strand;

  @memoized
  Address get address {
    var dom = strand.last_domain;
    return Address(helix_idx: dom.helix, offset: dom.offset_3p, forward: dom.forward);
  }

  @memoized
  String get id => util.id_modification_3p(strand, modification);

  /************************ begin BuiltValue boilerplate ************************/

  factory SelectableModification3Prime({Modification3Prime modification, Strand strand}) =
      _$SelectableModification3Prime._;

  factory SelectableModification3Prime.from([void Function(SelectableModification3PrimeBuilder) updates]) =
      _$SelectableModification3Prime;

  SelectableModification3Prime._();

  static Serializer<SelectableModification3Prime> get serializer => _$selectableModification3PrimeSerializer;

  @memoized
  int get hashCode;
}

abstract class SelectableModificationInternal
    with SelectableModification, SelectableMixin, BuiltJsonSerializable
    implements Built<SelectableModificationInternal, SelectableModificationInternalBuilder> {
  ModificationInternal get modification;

  Strand get strand;

  Domain get domain;

  int get dna_idx;

  int get offset {
    int dna_idx_ss = dna_idx - strand.get_seq_start_idx(domain);
    return domain.substrand_dna_idx_to_substrand_offset(dna_idx_ss, domain.forward);
  }

  @memoized
  Address get address => Address(helix_idx: domain.helix, offset: offset, forward: domain.forward);

  @memoized
  String get id => util.id_modification_int(strand, modification, address);

  /************************ begin BuiltValue boilerplate ************************/

  factory SelectableModificationInternal(
      {ModificationInternal modification,
      Strand strand,
      Domain domain,
      int dna_idx}) = _$SelectableModificationInternal._;

  factory SelectableModificationInternal.from(
      [void Function(SelectableModificationInternalBuilder) updates]) = _$SelectableModificationInternal;

  SelectableModificationInternal._();

  static Serializer<SelectableModificationInternal> get serializer =>
      _$selectableModificationInternalSerializer;

  @memoized
  int get hashCode;
}

abstract class Selectable {
  /// Subclasses must define this to be used to associate view element to state object through CSS selector.
  String get id;

  /// Subclasses must define this to be able to be selectively selected.
  SelectModeChoice get select_mode;

  bool get is_scaffold;

  handle_selection_mouse_down(MouseEvent event);

  handle_selection_mouse_up(MouseEvent event);
}

/// Represents a part of the Model that represents a part of the View that is Selectable.
mixin SelectableMixin implements Selectable {
  /// Subclasses must define this to be used to associate view element to state object through CSS selector.
  String get id;

  /// Subclasses must define this to be able to be selectively selected.
  SelectModeChoice get select_mode;

  bool get is_scaffold;

  //XXX: Previously the type of event was SyntheticMouseEvent, but now we have a pointer event since
  // the Dart dnd library intercepts and prevent mouse events. Luckily that event has the
  // ctrlKey, metaKey, and shiftKey properties we need to check for.
//  handle_selection(react.SyntheticPointerEvent event) {
  handle_selection_mouse_down(MouseEvent event) {
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (event.ctrlKey || event.metaKey) {
        app.dispatch(actions.Select(this, toggle: true));
      } else {
        // add to selection on mouse down
        app.dispatch(actions.Select(this, toggle: false));
      }
    }
  }

  // We choose to use the mouse up event to deselect other selections. Otherwise it is difficult to select
  // multiple items and then move them, because the click that attempts to move them is done without the
  // Shift or Ctrl key, so if we deselected whenever the user clicks without those keys, we would not be
  // able to move multiple items.
  handle_selection_mouse_up(MouseEvent event) {
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (!(event.ctrlKey || event.metaKey || event.shiftKey)) {
        app.dispatch(actions.Select(this, toggle: false, only: true));
      }
    }
  }
}

// functions accessing global app variable to detect selectability; WARNING, only call from event handlers

BuiltSet<EditModeChoice> edit_modes() => app.state.ui_state.edit_modes;

BuiltSet<SelectModeChoice> select_modes() => app.state.ui_state.select_mode_state.modes;

bool edit_mode_is_select_or_rope_select() => edit_mode_is_select() || edit_mode_is_rope_select();

bool edit_mode_is_select() => edit_modes().contains(EditModeChoice.select);

bool edit_mode_is_rope_select() => edit_modes().contains(EditModeChoice.rope_select);

bool edit_mode_is_pencil() => edit_modes().contains(EditModeChoice.pencil);

bool edit_mode_is_nick() => edit_modes().contains(EditModeChoice.nick);

bool edit_mode_is_ligate() => edit_modes().contains(EditModeChoice.ligate);

bool edit_mode_is_insertion() => edit_modes().contains(EditModeChoice.insertion);

bool edit_mode_is_deletion() => edit_modes().contains(EditModeChoice.deletion);

bool edit_mode_is_move_group() => edit_modes().contains(EditModeChoice.move_group);

bool strand_selectable(Strand strand) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.strand) &&
    origami_type_selectable(strand);

bool domain_selectable(Domain domain) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.domain) &&
    origami_type_selectable(domain);

bool crossover_selectable(Crossover crossover) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.crossover) &&
    origami_type_selectable(crossover);

bool loopout_selectable(Loopout loopout) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.loopout) &&
    origami_type_selectable(loopout);

bool deletion_selectable(SelectableDeletion deletion) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.deletion) &&
    origami_type_selectable(deletion);

bool insertion_selectable(SelectableInsertion insertion) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.insertion) &&
    origami_type_selectable(insertion);

bool modification_selectable(SelectableModification modification) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.modification) &&
    origami_type_selectable(modification);

bool end_selectable(DNAEnd end) =>
    edit_mode_is_select_or_rope_select() && end_type_selectable(end) && origami_type_selectable(end);

bool end_type_selectable(DNAEnd end) =>
    (end.is_5p && end.substrand_is_first && select_modes().contains(SelectModeChoice.end_5p_strand)) ||
    (end.is_5p && !end.substrand_is_first && select_modes().contains(SelectModeChoice.end_5p_domain)) ||
    (!end.is_5p && end.substrand_is_last && select_modes().contains(SelectModeChoice.end_3p_strand)) ||
    (!end.is_5p && !end.substrand_is_last && select_modes().contains(SelectModeChoice.end_3p_domain));

bool scaffold_selectable() => select_modes().contains(SelectModeChoice.scaffold);

bool staple_selectable() => select_modes().contains(SelectModeChoice.staple);

bool origami_type_selectable(Selectable selectable) {
  if (!app.state.design.is_origami) {
    return true;
  }
  if (selectable.is_scaffold) {
    return select_modes().contains(SelectModeChoice.scaffold);
  } else {
    return select_modes().contains(SelectModeChoice.staple);
  }
}
