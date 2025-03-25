import 'dart:html';

import 'package:built_collection/src/set.dart';
import 'package:redux/redux.dart';

import '../state/app_state.dart';
import '../state/design.dart';
import '../state/edit_mode.dart';
import '../state/select_mode.dart';

import '../actions/actions.dart' as actions;
import '../util.dart' as util;

const selectable_css_style_non_domain_or_end = {
  'filter': 'url("#shadow")',
  'stroke-width': '5pt', // makes thicker when selected so easier to see
};

const selectable_css_style_domain = {
  'stroke': 'hotpink',
  'stroke-width': '5pt',
  // 'filter': 'url("#shadow")',
};

const selectable_css_style_end = {
  'filter': 'url("#shadow")',
  'stroke': 'black',
  'stroke-width': '1pt',
  'visibility': 'visible',
};

edit_select_mode_change_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);
  if (action is actions.EditModesSet ||
      action is actions.EditModeToggle ||
      action is actions.SelectModesSet ||
      action is actions.SelectModesAdd ||
      action is actions.SelectModeToggle ||
      action is actions.SetAppUIStateStorable) {
    var select_modes = store.state.ui_state.select_mode_state.modes;
    var edit_modes = store.state.ui_state.edit_modes;
    if (store.state.maybe_design != null) {
      set_selectables_css_style_rules(store.state.design, edit_modes, select_modes);
    }
  }
}

set_selectables_css_style_rules(
    Design design, BuiltSet<EditModeChoice> edit_modes, BuiltSet<SelectModeChoice> select_modes) {
  bool edit_mode_is_select_or_rope =
      edit_modes.contains(EditModeChoice.select) || edit_modes.contains(EditModeChoice.rope_select);
  bool scaffold_parts_selectable =
      edit_mode_is_select_or_rope && (design.is_origami && select_modes.contains(SelectModeChoice.scaffold));
  bool staple_parts_selectable =
      edit_mode_is_select_or_rope && (design.is_origami && select_modes.contains(SelectModeChoice.staple));
  bool all_parts_selectable = edit_mode_is_select_or_rope &&
      (!design.is_origami || (scaffold_parts_selectable && staple_parts_selectable));

  for (var select_mode_choice in [SelectModeChoice.strand] + SelectModeChoice.strand_parts.toList()) {
    set_strand_part_selectable_css_style_rules(
      select_modes,
      all_parts_selectable: all_parts_selectable,
      staple_parts_selectable: staple_parts_selectable,
      scaffold_parts_selectable: scaffold_parts_selectable,
      select_mode_choice: select_mode_choice,
      is_origami: design.is_origami,
      edit_mode_is_select_or_rope_select: edit_mode_is_select_or_rope,
    );
  }
}

set_strand_part_selectable_css_style_rules(
  BuiltSet<SelectModeChoice> select_modes, {
  required bool all_parts_selectable,
  required bool staple_parts_selectable,
  required bool scaffold_parts_selectable,
  required SelectModeChoice select_mode_choice,
  required bool is_origami,
  required bool edit_mode_is_select_or_rope_select,
}) {
  bool select_mode_contains_part = select_modes.contains(select_mode_choice);
  var selectable_css_style_this_choice;

  if (SelectModeChoice.ends.contains(select_mode_choice)) {
    selectable_css_style_this_choice = selectable_css_style_end;
  } else if (SelectModeChoice.domain == select_mode_choice) {
    selectable_css_style_this_choice = selectable_css_style_domain;
  } else {
    selectable_css_style_this_choice = selectable_css_style_non_domain_or_end;
  }

  var all_strand_selector = '.${select_mode_choice.css_selector()}:hover';
  var staple_only_selector =
      ':not(.${SelectModeChoice.scaffold.css_selector()}).${select_mode_choice.css_selector()}:hover';
  var scaffold_selector =
      '.${SelectModeChoice.scaffold.css_selector()}.${select_mode_choice.css_selector()}:hover';

  if (!edit_mode_is_select_or_rope_select || !select_mode_contains_part) {
    css_class_remove_style(all_strand_selector);
    css_class_remove_style(staple_only_selector);
    css_class_remove_style(scaffold_selector);
  } else if (!is_origami || all_parts_selectable) {
    css_class_set_style(all_strand_selector, selectable_css_style_this_choice);
    css_class_set_style(staple_only_selector, selectable_css_style_this_choice);
    css_class_set_style(scaffold_selector, selectable_css_style_this_choice);
  } else if (scaffold_parts_selectable) {
    css_class_remove_style(all_strand_selector);
    css_class_remove_style(staple_only_selector);
    css_class_set_style(scaffold_selector, selectable_css_style_this_choice);
  } else if (staple_parts_selectable) {
    css_class_remove_style(all_strand_selector);
    css_class_set_style(staple_only_selector, selectable_css_style_this_choice);
    css_class_remove_style(scaffold_selector);
  } else {
    css_class_remove_style(all_strand_selector);
    css_class_remove_style(staple_only_selector);
    css_class_remove_style(scaffold_selector);
  }
}

css_class_set_style(String selector, Map<String, String> new_style_map) {
  var stylesheet = util.get_scadnano_stylesheet();
  var rule = style_rule_with_selector(stylesheet, selector);
  if (rule == null) {
    int new_index = stylesheet.insertRule(selector + ' {}');
    rule = stylesheet.cssRules[new_index] as CssStyleRule;
  }
  var style = rule.style;
  for (var style_key in new_style_map.keys) {
    var style_val = new_style_map[style_key];
    style.setProperty(style_key, style_val);
  }
}

css_class_remove_style(String selector) {
  var stylesheet = util.get_scadnano_stylesheet();
  int? idx = style_rule_index_with_selector(stylesheet, selector);
  if (idx != null) {
    stylesheet.removeRule(idx);
  }
}

CssStyleRule? style_rule_with_selector(CssStyleSheet stylesheet, String selector) {
  int? idx = style_rule_index_with_selector(stylesheet, selector);
  return idx == null ? null : stylesheet.cssRules[idx] as CssStyleRule;
}

int? style_rule_index_with_selector(CssStyleSheet stylesheet, String selector) {
  for (int i = 0; i < stylesheet.cssRules.length; i++) {
    CssRule rule = stylesheet.cssRules[i];
    if (rule is CssStyleRule && rule.selectorText == selector) {
      return i;
    }
  }
  return null;
}
