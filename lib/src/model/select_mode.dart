import 'dart:convert';
import 'dart:html';

import 'package:w_flux/w_flux.dart';

import '../dispatcher/actions.dart';
import '../dispatcher/local_storage.dart' as local_storage;
import 'selectable.dart';

/// Indicates which objects are selectable in the main view.
class SelectModeChoice {
  final String name;
  final String _css_selector;

  static final end_5p_strand = SelectModeChoice._("5' strand", 'five-prime-end-first-substrand');
  static final end_3p_strand = SelectModeChoice._("3' strand", 'three-prime-end-last-substrand');
  static final end_5p_substrand = SelectModeChoice._("5' (other)", 'five-prime-end');
  static final end_3p_substrand = SelectModeChoice._("3' (other)", 'three-prime-end');
  static final crossover = SelectModeChoice._('crossover', 'crossover-curve');
  static final loopout = SelectModeChoice._('loopout', 'loopout-line');
  static final strand = SelectModeChoice._('strand', 'strand');
  static final scaffold = SelectModeChoice._('scaffold', 'scaffold');
  static final staple = SelectModeChoice._('staple', 'scaffold');

  static List<SelectModeChoice> values = [
    end_5p_strand,
    end_3p_strand,
    end_5p_substrand,
    end_3p_substrand,
    crossover,
    loopout,
    strand,
    scaffold,
    staple
  ];

  SelectModeChoice._(this.name, this._css_selector);

  factory SelectModeChoice.from_json(String the_name) {
    for (var val in values) {
      if (val.name == the_name) {
        return val;
      }
    }
    throw ArgumentError('there is no Select Mode with name "${the_name}"');
  }

  String toString() => 'SelectModeChoice(${this.name})';

  String css_selector() => _css_selector;
}

class SelectModeStore extends Store {
  Set<SelectModeChoice> modes = Set<SelectModeChoice>.from(SelectModeChoice.values);

  SelectModeStore() {
    handle_actions();
  }

  bool is_selectable(Selectable selectable) {
    return modes.contains(selectable.select_mode());
  }

  String to_json() {
    List<String> lst = [for (var mode in modes) mode.name];
    var js = jsonEncode(lst);
    return js;
  }

  Set<SelectModeChoice> from_json(String json_str) {
    modes = jsonDecode(json_str);
  }

  void handle_actions() {
    triggerOnActionV2<SelectModeChoice>(Actions.toggle_select_mode, (mode) {
      if (modes.contains(mode)) {
        remove_mode(mode);
      } else {
        add_mode(mode);
      }
      local_storage.save(local_storage.Storable.select_mode);
    });

    triggerOnActionV2<List<SelectModeChoice>>(Actions.set_select_modes, (new_modes) {
      modes = Set<SelectModeChoice>.from(new_modes);
      for (var mode in SelectModeChoice.values) {
        if (modes.contains(mode)) {
          add_selectable_css_selectors(mode);
        } else {
          remove_selectable_css_selectors(mode);
        }
      }
      local_storage.save(local_storage.Storable.select_mode);
    });
  }

  add_mode(SelectModeChoice mode) {
    modes.add(mode);
    add_selectable_css_selectors(mode);
  }

  //XXX: this is doing an end-run around the Model-View-Update cycle for efficiency, otherwise we'd need
  // to wastefully re-render all strands just because we want to make 5' ends selectable
  void add_selectable_css_selectors(SelectModeChoice mode) {
    var elts = querySelectorAll('.${mode.css_selector()}');
    for (var elt in elts) {
      elt.classes.add('selectable');
    }
  }

  remove_mode(SelectModeChoice mode) {
    modes.remove(mode);
    remove_selectable_css_selectors(mode);
  }

  void remove_selectable_css_selectors(SelectModeChoice mode) {
    var elts = querySelectorAll('.${mode.css_selector()}');
    for (var elt in elts) {
      elt.classes.remove('selectable');
    }
  }
}
