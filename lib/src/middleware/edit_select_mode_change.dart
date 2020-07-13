import 'dart:html';

import 'package:built_collection/src/set.dart';
import 'package:redux/redux.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/select_mode.dart';

import '../actions/actions.dart' as actions;
import '../util.dart' as util;

const selectable_css_style_non_domain_end = {'filter': 'url("#shadow")'};
const selectable_css_style_domain_end = {
  'filter': 'url("#shadow")',
  'stroke': 'black',
  'stroke-width': '0.5px',
  'visibility': 'visible',
};
const unselectable_css_style = {'filter': null};

edit_select_mode_change_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);
  if (action is actions.EditModesSet ||
      action is actions.EditModeToggle ||
      action is actions.SelectModesSet ||
      action is actions.SelectModeToggle ||
      action is actions.SetAppUIStateStorable) {
    var select_modes = store.state.ui_state.select_mode_state.modes;
    var edit_modes = store.state.ui_state.edit_modes;
    var design = store.state.dna_design;
    set_selectables_css_style_rules(design, edit_modes, select_modes);
  }
}

set_selectables_css_style_rules(
    DNADesign design, BuiltSet<EditModeChoice> edit_modes, BuiltSet<SelectModeChoice> select_modes) {
  bool edit_mode_is_select = edit_modes.contains(EditModeChoice.select);
  bool scaffold_parts_selectable =
      edit_mode_is_select && (design.is_origami && select_modes.contains(SelectModeChoice.scaffold));
  bool staple_parts_selectable =
      edit_mode_is_select && (design.is_origami && select_modes.contains(SelectModeChoice.staple));
  bool all_parts_selectable =
      edit_mode_is_select && (!design.is_origami || (scaffold_parts_selectable && staple_parts_selectable));

  for (var select_mode_choice in [SelectModeChoice.strand] + SelectModeChoice.strand_parts.toList()) {
    set_strand_part_selectable_css_style_rules(select_modes,
        all_parts_selectable: all_parts_selectable,
        staple_parts_selectable: staple_parts_selectable,
        scaffold_parts_selectable: scaffold_parts_selectable,
        select_mode_choice: select_mode_choice);
  }
}

set_strand_part_selectable_css_style_rules(BuiltSet<SelectModeChoice> select_modes,
    {bool all_parts_selectable,
    bool staple_parts_selectable,
    bool scaffold_parts_selectable,
    SelectModeChoice select_mode_choice}) {
  bool select_mode_contains_part = select_modes.contains(select_mode_choice);
  String part_classname = '.' + select_mode_choice.css_selector();
  var selectable_css_style_this_choice = SelectModeChoice.ends.contains(select_mode_choice)
      ? selectable_css_style_domain_end
      : selectable_css_style_non_domain_end;

  if (all_parts_selectable && select_mode_contains_part) {
    css_class_set_style('${part_classname}:hover', selectable_css_style_this_choice);
  } else {
    css_class_set_style('${part_classname}:hover', unselectable_css_style);

    if (staple_parts_selectable && select_mode_contains_part) {
      css_class_set_style('${part_classname}:hover', selectable_css_style_this_choice);
    } else {
      css_class_set_style('${part_classname}:hover', unselectable_css_style);
    }

    if (scaffold_parts_selectable && select_mode_contains_part) {
      css_class_set_style('${part_classname}:hover', selectable_css_style_this_choice);
    } else {
      css_class_set_style('${part_classname}:hover', unselectable_css_style);
    }
  }
}

css_class_set_style(String classname, Map<String, String> new_style_map) {
  var styleSheet = util.get_scadnano_stylesheet();
  var rule = style_rule_with_selector(styleSheet, classname);
  var style = rule.style;
  for (var style_key in new_style_map.keys) {
    var style_val = new_style_map[style_key];
    if (style_val != null) {
      style.setProperty(style_key, style_val);
    } else {
      style.removeProperty(style_key);
    }
  }
}

CssStyleRule style_rule_with_selector(CssStyleSheet stylesheet, String classname) {
  for (int i = 0; i < stylesheet.cssRules.length; i++) {
    CssRule rule = stylesheet.cssRules[i];
    if (rule is CssStyleRule && rule.selectorText == classname) {
      return rule;
    }
  }
  throw AssertionError('cannot find CSS style rule matching classname ${classname}');
}
