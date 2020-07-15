import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../state/select_mode_state.dart';
import '../state/edit_mode.dart';
import '../state/potential_crossover.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

// This checks actions that are sensitive to the current edit or select mode, and stops them if they
// don't make sense with the current modes. This enables the view components to be more dumb and not
// need to contain information about the current mode (thus avoiding a re-render whenever the modes change.
// It also converts some actions that are "dumb" since the dumb view components didn't have enough
// information into smarted actions that have more information gathered from store.state.
mode_sensitive_actions_filter_middleware(Store<AppState> store, action, NextDispatcher next) {
  var edit_modes = store.state.ui_state.edit_modes;
  var select_mode_state = store.state.ui_state.select_mode_state;

  if (should_skip_action_wrong_edit_mode(edit_modes, action)) {
    return;
  }

  if (should_skip_action_wrong_select_mode(select_mode_state, action)) {
    return;
  }

  if (action is actions.NickOrInsertionOrDeletionAdd) {
    var converted_action = convert_action_domain_clicked(edit_modes, action);
    if (converted_action != null) {
      app.dispatch(converted_action);
    }
    return;
  } else if (action is actions.DNAEndClicked) {
    bool drawing_potential_crossover = store.state.ui_state.drawing_potential_crossover;
    var converted_action = convert_action_dna_end_clicked(edit_modes, drawing_potential_crossover, action);
    if (converted_action != null) {
      app.dispatch(converted_action);
    }
    return;
  }

  next(action);
}

// This is ugly, but Dart doesn't appear to have easy reflection abilities to store this relationship
// of action type to required edit mode in a Map data structure, since the actual runtimeType of each class,
// due to built_value, is actually a subclass of the abstract types below. This "is" keyword seems to be
// about the only tool. (I checked in the dart:mirrors library, but it's not well documented,
// and is also announced as unstable and subject to change.
bool should_skip_action_wrong_edit_mode(BuiltSet<EditModeChoice> edit_modes, action) {
  if (action is actions.StrandsMoveStartSelectedStrands ||
      action is actions.Select ||
      action is actions.DNAEndsMoveStart) {
    return !edit_modes.contains(EditModeChoice.select);
  } else if (action is actions.PotentialCrossoverCreate || action is actions.JoinStrandsByCrossover) {
    return !edit_modes.contains(EditModeChoice.pencil);
  } else if (action is actions.DeletionAdd || action is actions.DeletionRemove) {
    return !edit_modes.contains(EditModeChoice.deletion);
  } else if (action is actions.InsertionAdd || action is actions.InsertionRemove) {
    return !edit_modes.contains(EditModeChoice.insertion);
  } else if (action is actions.MouseoverDataUpdate) {
    return !edit_modes.contains(EditModeChoice.backbone);
  } else if (action is actions.Ligate) {
    return !edit_modes.contains(EditModeChoice.ligate);
  }
  return false;
}

bool should_skip_action_wrong_select_mode(SelectModeState select_mode_state, action) {
  if (action is actions.StrandsMoveStartSelectedStrands) {
    return !select_mode_state.strands_selectable();
  } else if (action is actions.DNAEndsMoveStart) {
    return !select_mode_state.ends_selectable();
  }
  return false;
}

// convert NickOrInsertionOrDeletionAdd dumbly created by Domain view, now that we know the edit mode.
convert_action_domain_clicked(
    BuiltSet<EditModeChoice> edit_modes, actions.NickOrInsertionOrDeletionAdd action) {
  var converted_action;
  if (edit_modes.contains(EditModeChoice.nick)) {
    if (action.offset <= action.domain.start + 1 || action.offset >= action.domain.end - 1) {
      return null; // need remaining domains to be length at least 2
    }
    converted_action = actions.Nick(domain: action.domain, offset: action.offset);
  } else if (edit_modes.contains(EditModeChoice.insertion)) {
    converted_action = actions.InsertionAdd(domain: action.domain, offset: action.offset);
  } else if (edit_modes.contains(EditModeChoice.deletion)) {
    converted_action = actions.DeletionAdd(domain: action.domain, offset: action.offset);
  }
  return converted_action;
}

convert_action_dna_end_clicked(
    BuiltSet<EditModeChoice> edit_modes, bool drawing_potential_crossover, actions.DNAEndClicked action) {
  var converted_action;
  if (edit_modes.contains(EditModeChoice.ligate)) {
    converted_action = actions.Ligate(dna_end: action.dna_end);
  } else if (edit_modes.contains(EditModeChoice.pencil)) {
    if (!drawing_potential_crossover) {
      converted_action = actions.PotentialCrossoverCreate(potential_crossover: action.potential_crossover);
    } else {
      //FIXME: can we avoid this global variable access? probably not since there's multiple stores
      PotentialCrossover potential_crossover = app.store_potential_crossover.state;
      if (action.dna_end.is_5p == potential_crossover.dna_end_first_click.is_5p) {
        // can only connect opposite type ends with crossover
        return null;
      }
      app.dispatch(actions.PotentialCrossoverRemove()); // seems fishy to call dispatch here, but it works.
      if ((action.is_first && potential_crossover.dna_end_first_click.substrand_is_last) ||
          (action.is_last && potential_crossover.dna_end_first_click.substrand_is_first)) {
        converted_action = actions.JoinStrandsByCrossover(
            dna_end_first_click: potential_crossover.dna_end_first_click,
            dna_end_second_click: action.dna_end);
      }
    }
  }
  return converted_action;
}

/*
if (pencil_mode && !props.drawing_potential_crossover && (is_first || is_last)) {
      int offset = props.is_5p ? props.domain.offset_5p : props.domain.offset_3p;
      Point<num> start_point = props.helix.svg_base_pos(offset, props.domain.forward);
      var potential_crossover = PotentialCrossover(
        helix_idx: props.helix.idx,
        forward: props.domain.forward,
        offset: offset,
        color: props.color.toHexColor().toCssString(),
        dna_end_first_click: dna_end,
        start_point: start_point,
        current_point: start_point,
      );
      app.dispatch(actions.PotentialCrossoverCreate(potential_crossover: potential_crossover));
    } else if (pencil_mode && props.drawing_potential_crossover && (is_first || is_last)) {
      PotentialCrossover potential_crossover = app.store_potential_crossover.state;
      if (props.is_5p == potential_crossover.dna_end_first_click.is_5p) {
        // can only connect opposite type ends with crossover
        return;
      }
      //FIXME: can we avoid this global variable access? probably not since there's multiple stores
      app.dispatch(actions.PotentialCrossoverRemove());
      if ((is_first && potential_crossover.dna_end_first_click.substrand_is_last) ||
          (is_last && potential_crossover.dna_end_first_click.substrand_is_first)) {
        app.dispatch(actions.JoinStrandsByCrossover(
            dna_end_first_click: potential_crossover.dna_end_first_click, dna_end_second_click: dna_end));
      }
    } else if (ligate_mode && (is_first || is_last)) {
      app.dispatch(actions.Ligate(dna_end: dna_end));
    }
 */
