import 'dart:convert';

import 'package:scadnano/src/model/bound_substrand.dart';
import 'package:scadnano/src/model/crossover.dart';
import 'package:w_flux/w_flux.dart';

import '../dispatcher/actions.dart';
import '../dispatcher/local_storage.dart' as local_storage;
import 'loopout.dart';
import 'strand.dart';

/// Indicates which objects are selectable in the main view.
class SelectModeChoice {
  final String name;

  static final end_5p_strand = SelectModeChoice._("5' strand");
  static final end_3p_strand = SelectModeChoice._("3' strand");
  static final end_5p_substrand = SelectModeChoice._("5' (all)");
  static final end_3p_substrand = SelectModeChoice._("3' (all)");
  static final crossover = SelectModeChoice._('crossover');
  static final loopout = SelectModeChoice._('loopout');
  static final strand = SelectModeChoice._('strand');
  static final scaffold = SelectModeChoice._('scaffold');
  static final staple = SelectModeChoice._('staple');

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

  SelectModeChoice._(this.name);

  factory SelectModeChoice.from_json(String the_name) {
    for (var val in values) {
      if (val.name == the_name) {
        return val;
      }
    }
    throw ArgumentError('there is no Select Mode with name "${the_name}"');
  }

  String toString() => 'SelectModeChoice(${this.name})';
}

class SelectModeStore extends Store {
  Set<SelectModeChoice> modes = Set<SelectModeChoice>.from(SelectModeChoice.values);

  SelectModeStore() {
    handle_actions();
  }

  bool is_selectable(Object obj) {
    switch(obj.runtimeType) {
      case DNAEnd:
        DNAEnd end = obj as DNAEnd;
        if (end.is_5p) {
          if (end.substrand.is_first()) {
            return modes.contains(SelectModeChoice.end_5p_strand);
          } else {
            return modes.contains(SelectModeChoice.end_5p_substrand);
          }
        } else {
          if (end.substrand.is_last()) {
            return modes.contains(SelectModeChoice.end_3p_strand);
          } else {
            return modes.contains(SelectModeChoice.end_3p_substrand);
          }
        }
        break;

      case Crossover:
        return modes.contains(SelectModeChoice.crossover);
        break;

      case Loopout:
        return modes.contains(SelectModeChoice.loopout);
        break;

      case Strand:
        return modes.contains(SelectModeChoice.strand);
        break;
    }
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
        modes.remove(mode);
      } else {
        modes.add(mode);
      }
      local_storage.save(local_storage.Storable.select_mode);
    });
    triggerOnActionV2<List<SelectModeChoice>>(Actions.set_select_modes, (new_modes) {
      modes = Set<SelectModeChoice>.from(new_modes);
      local_storage.save(local_storage.Storable.select_mode);
    });
  }
}
