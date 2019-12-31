import 'dart:convert';
import 'dart:html';

import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

import 'select_mode.dart';
import 'selectable.dart';

part 'select_mode_state.g.dart';

// whether to skip re-rendering views of selectables when selection mode changes; faster to do by side-effect
//const OPTIMIZE_SELECTABLE_CSS_CLASS_MODIFICATION = true;
const OPTIMIZE_SELECTABLE_CSS_CLASS_MODIFICATION = false;

final DEFAULT_SelectModeStateBuilder = SelectModeStateBuilder()
  ..modes = SetBuilder<SelectModeChoice>(
      SelectModeChoice.strand_parts.asList() + [SelectModeChoice.staple, SelectModeChoice.scaffold]);

abstract class SelectModeState implements Built<SelectModeState, SelectModeStateBuilder> {
  SelectModeState._();

  factory SelectModeState([void Function(SelectModeStateBuilder) updates]) =>
      _$SelectModeState((s) => s..replace(DEFAULT_SelectModeStateBuilder.build()));

  static Serializer<SelectModeState> get serializer => _$selectModeStateSerializer;

  /************************ begin BuiltValue boilerplate ************************/

  BuiltSet<SelectModeChoice> get modes;

  bool is_selectable(Selectable selectable) => modes.contains(selectable.select_mode());

  bool strands_selectable() => modes.contains(SelectModeChoice.strand);

  bool linkers_selectable() =>
      modes.contains(SelectModeChoice.crossover) || modes.contains(SelectModeChoice.loopout);

  bool ends_selectable() =>
      modes.contains(SelectModeChoice.end_3p_strand) ||
      modes.contains(SelectModeChoice.end_5p_strand) ||
      modes.contains(SelectModeChoice.end_3p_substrand) ||
      modes.contains(SelectModeChoice.end_5p_substrand);

  String to_json() {
    List<String> lst = [for (var mode in modes) mode.name];
    var js = jsonEncode(lst);
    return js;
  }

  static SelectModeState from_json(String json_str) {
    List<String> modes = jsonDecode(json_str);
    return SelectModeState((s) => s..modes = SetBuilder<SelectModeChoice>(modes));
  }

  //XXX: on the CSS selectors, this is doing a side-effect end-run around the Model-View-Update cycle.
  // ThIs is for efficiency; otherwise we'd need to wastefully re-render all strands
  // just because we want to make 5' ends selectable
  SelectModeState add_mode(SelectModeChoice mode) {
    add_selectable_css_selectors(mode);
    return rebuild((s) => s..modes = (modes.toBuilder()..add(mode)));
  }

  SelectModeState remove_mode(SelectModeChoice mode) {
    remove_selectable_css_selectors(mode);
    return rebuild((s) => s..modes = (modes.toBuilder()..remove(mode)));
  }

  SelectModeState add_modes(Iterable<SelectModeChoice> new_modes) {
    for (var mode in new_modes) {
      add_selectable_css_selectors(mode);
    }
    return rebuild((s) => s..modes = (modes.toBuilder()..addAll(new_modes)));
  }

  SelectModeState remove_modes(Iterable<SelectModeChoice> new_modes) {
    for (var mode in new_modes) {
      remove_selectable_css_selectors(mode);
    }
    return rebuild((s) => s..modes = (modes.toBuilder()..removeAll(new_modes)));
  }

  SelectModeState set_modes(Iterable<SelectModeChoice> new_modes) {
    for (var mode in new_modes) {
      if (new_modes.contains(mode)) {
        SelectModeState.add_selectable_css_selectors(mode);
      } else {
        SelectModeState.remove_selectable_css_selectors(mode);
      }
    }
    return rebuild((s) => s.modes = SetBuilder<SelectModeChoice>(new_modes));
  }

  //XXX: this is doing an end-run around the Model-View-Update cycle for efficiency, otherwise we'd need
  // to wastefully re-render all strands just because we want to make 5' ends selectable
  static add_selectable_css_selectors(SelectModeChoice mode) {
    if (OPTIMIZE_SELECTABLE_CSS_CLASS_MODIFICATION) {
      var elts = querySelectorAll('.${mode.css_selector()}');
      for (var elt in elts) {
        elt.classes.add('selectable');
      }
    }
  }

  static remove_selectable_css_selectors(SelectModeChoice mode) {
    if (OPTIMIZE_SELECTABLE_CSS_CLASS_MODIFICATION) {
      var elts = querySelectorAll('.${mode.css_selector()}');
      for (var elt in elts) {
        elt.classes.remove('selectable');
      }
    }
  }
}
