import 'dart:core';

import 'model.dart';
import 'app.dart';

////////////////////////////////////////////////
// MenuViewUIModel

const DEFAULT_FILENAME_NO_EXT = 'default_dna_filename';
const DEFAULT_SCRIPT_FILENAME_NO_EXT = 'default_script_filename';
const DEFAULT_EXT = 'dna';
const DEFAULT_SCRIPT_EXT = 'py';
const ALLOWED_EXTENSIONS_DESIGN = ['dna'];
const ALLOWED_EXTENSIONS_SCRIPT = ['py'];

default_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;

default_script_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;

class MenuViewUIModel {
  String loaded_filename = default_filename();
}

class EditorViewUIModel {
  String loaded_script_filename = default_script_filename();
}

////////////////////////////////////////////////
// MainViewUIModel

class MainViewUIModel {
  MainViewSelection selection = MainViewSelection();
  MouseOverData mouse_over_data = MouseOverData();

  /// disabling this will make it easier to navigate since less SVG needs be rendered
  bool _show_dna = true;
//  bool _show_dna = false;
  bool _show_mismatches = true;
//  bool _show_mismatches = false;

  bool get show_dna => this._show_dna;
  void set show_dna(bool new_show_dna) {
    this._show_dna = new_show_dna;
    app.controller.notifier_show_dna_change.add(this._show_dna);
  }

  bool get show_mismatches => this._show_mismatches;
  void set show_mismatches(bool new_show_mismatches) {
    this._show_mismatches = new_show_mismatches;
    app.controller.notifier_show_mismatches_change.add(this._show_mismatches);
  }

  //TODO: make editing "mode": if editor mode=manual, no code editor. If mode=script, cannot edit design manually.
  //  Then it's ubambiguous what Ctrl+Z should do
  bool show_editor = false;

}

class MouseOverData with ChangeNotifier<MouseOverData> {
  bool _has_data = false;
  bool get has_data => this._has_data;

  MouseOverData.internal();

  MouseOverData() {
    this._set_change_notifier();
  }

  void _set_change_notifier() {
    this.notifier = app.controller.notifier_mouse_over_data;
  }

  give_data(int helix_idx, int offset, Substrand substrand) {
    this._has_data = true;
    this._helix_idx = helix_idx;
    this._offset = offset;
    this._substrand = substrand;
    this.notify_changed();
  }

  remove_data() {
    this._has_data = false;
    this.notify_changed();
  }

  /// Returns clone of this MouseOverData. (Prevents race condition that sometimes results in exceptions.)
  /// Should actually lock some object here to really prevent the race condition but I'm lazy.
  MouseOverData clone() {
    if (this._has_data) {
      int helix_idx = this._helix_idx;
      int offset = this._offset;
      Substrand substrand = this._substrand;
      var ret = MouseOverData.internal();
      ret._helix_idx = helix_idx;
      ret._offset = offset;
      ret._substrand = substrand;
      ret._has_data = true;
      return ret;
    } else {
      var ret = MouseOverData.internal();
      ret._has_data = false;
      return ret;
    }
  }

  int _helix_idx;
  int get helix_idx => this._helix_idx;

  int _offset;
  int get offset => this._offset;

  Substrand _substrand;
  Substrand get substrand => this._substrand;

}

class MainViewSelection {
  List<Substrand> starts = [];
  List<Substrand> ends = [];
  List<Crossover> crossovers = [];
  List<Substrand> substrands = [];
}

class Crossover {
  Substrand substrand_5p = null;
  Substrand substrand_3p = null;
}

////////////////////////////////////////////////
// SideViewUIModel

class SideViewSelection {
  List<Helix> helices = [];
}

class SideViewUIModel {
  SideViewSelection selection = SideViewSelection();
}