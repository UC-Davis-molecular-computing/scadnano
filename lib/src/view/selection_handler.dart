import 'dart:html';

import 'package:built_collection/built_collection.dart';

import 'package:scadnano_state_actions/src/actions/actions.dart' as actions;
import '../app.dart';
import 'package:scadnano_state_actions/src/constants.dart' as constants;
import 'package:scadnano_state_actions/src/state/crossover.dart';
import 'package:scadnano_state_actions/src/state/dialog.dart';
import 'package:scadnano_state_actions/src/state/dna_end.dart';
import 'package:scadnano_state_actions/src/state/domain.dart';
import 'package:scadnano_state_actions/src/state/edit_mode.dart';
import 'package:scadnano_state_actions/src/state/extension.dart';
import 'package:scadnano_state_actions/src/state/loopout.dart';
import 'package:scadnano_state_actions/src/state/select_mode.dart';
import 'package:scadnano_state_actions/src/state/selectable.dart';
import 'package:scadnano_state_actions/src/state/strand.dart';
import '../util.dart' as util;
import 'package:scadnano_state_actions/src/util_state.dart' as util_state;

/// Handles mouse down for selection on any [Selectable].
/// Call this from view components instead of selectable.handle_selection_mouse_down.
void handle_selection_mouse_down(Selectable selectable, MouseEvent event) {
  if (event.button == constants.LEFT_CLICK_BUTTON) {
    if (event.ctrlKey || event.metaKey) {
      app.dispatch(actions.Select(selectable, toggle: true));
    } else {
      app.dispatch(actions.Select(selectable, toggle: false));
    }
  }
}

/// Handles mouse up for selection on any [Selectable].
/// Call this from view components instead of selectable.handle_selection_mouse_up.
void handle_selection_mouse_up(Selectable selectable, MouseEvent event) {
  if (event.button == constants.LEFT_CLICK_BUTTON) {
    if (!(event.ctrlKey || event.metaKey || event.shiftKey)) {
      app.dispatch(actions.Select(selectable, toggle: false, only: true));
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

bool extension_selectable(Extension ext) =>
    edit_mode_is_select_or_rope_select() &&
    select_modes().contains(SelectModeChoice.extension_) &&
    origami_type_selectable(ext);

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

Future<void> ask_for_select_all_with_same_as_selected() async {
  var selected_strands = app.state.ui_state.selectables_store.selected_strands.toBuiltList();
  if (selected_strands.length == 0) {
    window.alert('No strands are selected. Select at least one strand before choosing this option.');
    return;
  }

  var all_traits = List<SelectableTrait>.from(SelectableTrait.values);
  util_state.FixedList<DialogItem> items = util_state.FixedList<DialogItem>(all_traits.length + 1);

  for (int idx = 0; idx < all_traits.length; idx++) {
    var trait = all_traits[idx];
    items[idx] = DialogCheckbox(label: trait.description, value: false);
  }
  items[all_traits.length] = DialogCheckbox(
    label: '(Exclude scaffold(s))',
    value: false,
    tooltip: '''\
If checked, then only strands that are not scaffolds will be selected.
However, *currently* selected scaffold strands will remain selected.''',
  );

  var dialog = Dialog(
    title: "Select all strands with same traits as currently selected strand(s)",
    type: DialogType.select_all_with_same_as_selected,
    items: items,
  );
  List<DialogItem>? results = await util.dialog(dialog);
  if (results == null) return;

  List<SelectableTrait> traits_for_selection = [];
  for (int idx = 0; idx < all_traits.length; idx++) {
    var trait = all_traits[idx];
    bool trait_selected = (results[idx] as DialogCheckbox).value;
    if (trait_selected) {
      traits_for_selection.add(trait);
    }
  }
  bool exclude_scaffolds = (results[all_traits.length] as DialogCheckbox).value;

  var action = actions.SelectAllStrandsWithSameAsSelected(
    template_strands: selected_strands,
    traits: traits_for_selection.build(),
    exclude_scaffolds: exclude_scaffolds,
  );
  app.dispatch(action);
}
