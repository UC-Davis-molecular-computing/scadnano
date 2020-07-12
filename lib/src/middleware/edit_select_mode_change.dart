import 'dart:html';

import 'package:redux/redux.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/select_mode_state.dart';

import '../actions/actions.dart' as actions;
import '../util.dart' as util;

const strand_classname = '.strand';

const selectable_css_rule = '{ filter: url("#shadow"); }';
const unselectable_css_rule = '{}';

edit_select_mode_change_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.EditModesSet ||
      action is actions.EditModeToggle ||
      action is actions.SelectModesSet ||
      action is actions.SelectModeToggle) {
    var select_modes_before = store.state.ui_state.select_mode_state.modes;
    var edit_modes_before = store.state.ui_state.edit_modes;
    next(action);
    var select_modes_after = store.state.ui_state.select_mode_state.modes;
    var edit_modes_after = store.state.ui_state.edit_modes;

    if (action is actions.EditModesSet) {}

    if (action is actions.EditModeToggle) {}

    if (action is actions.SelectModesSet && store.state.ui_state.edit_modes.contains(EditModeChoice.select)) {}

    if (action is actions.SelectModeToggle && store.state.ui_state.edit_modes.contains(EditModeChoice.select)) {
      if (select_strand_turning_on(store.state.ui_state.select_mode_state, action)) {
        give_css_class_new_style('${strand_classname}:hover', selectable_css_rule);
      } else if (select_strand_turning_off(store.state.ui_state.select_mode_state, action)) {
        give_css_class_new_style('${strand_classname}:hover', unselectable_css_rule);
      }
    }

  } else {
    next(action);
  }
  next(action);
}

bool select_strand_turning_on(SelectModeState select_mode_state, actions.SelectModeToggle action) =>
    !select_mode_state.modes.contains(SelectModeChoice.strand) &&
    action.select_mode_choice == SelectModeChoice.strand;

bool select_strand_turning_off(SelectModeState select_mode_state, actions.SelectModeToggle action) =>
    select_mode_state.modes.contains(SelectModeChoice.strand) &&
    (action.select_mode_choice == SelectModeChoice.strand || // either strand turning off on its own
        action.select_mode_choice == SelectModeChoice.loopout || // or going to be turned off by
        action.select_mode_choice == SelectModeChoice.crossover ||
        action.select_mode_choice == SelectModeChoice.end_5p_strand ||
        action.select_mode_choice == SelectModeChoice.end_3p_strand ||
        action.select_mode_choice == SelectModeChoice.end_5p_substrand ||
        action.select_mode_choice == SelectModeChoice.end_3p_substrand);

give_css_class_new_style(String classname, String new_style) {
  var styleSheet = util.get_scadnano_stylesheet();
  int index = index_of_rule_with_selector(styleSheet, classname);
  int index_to_insert = styleSheet.rules.length;
  if (index >= 0) {
    styleSheet.removeRule(index);
    index_to_insert = index;
  }
  var rule = '${classname} ${new_style}';
  styleSheet.insertRule(rule, index_to_insert);
}

int index_of_rule_with_selector(CssStyleSheet styleSheet, String classname) {
  int index = -1;
  for (int i = 0; i < styleSheet.cssRules.length; i++) {
    CssRule rule = styleSheet.cssRules[i];
    if (rule is CssStyleRule && rule.selectorText == classname) {
      index = i;
      break;
    }
  }
  return index;
}
