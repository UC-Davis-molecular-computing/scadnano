import 'dart:core';

import 'package:w_flux/w_flux.dart';

import 'mouseover_data.dart';
import 'strand.dart';
import '../app.dart';
import 'helix.dart';

////////////////////////////////////////////////
// Stores

class ShowDNAStore extends Store {
  static final Action<bool> set_show_dna_global = Action<bool>();

  Action<bool> get set_show_dna => set_show_dna_global;

  bool _show_dna = true;

  bool get show_dna => this._show_dna;

  ShowDNAStore() {
    triggerOnActionV2<bool>(this.set_show_dna, (show) {
      this._show_dna = show;
    });
  }
}

class ShowMismatchesStore extends Store {
  static final Action<bool> set_show_mismatches_global = Action<bool>();

  Action<bool> get set_show_mismatches => set_show_mismatches_global;

  bool _show_mismatches = true;

  bool get show_mismatches => this._show_mismatches;

  ShowMismatchesStore() {
    triggerOnActionV2<bool>(this.set_show_mismatches, (show) => this._show_mismatches = show);
  }
}

class ShowEditorStore extends Store {
  static final Action<bool> set_show_editor_global = Action<bool>();

  Action<bool> get set_show_editor => set_show_editor_global;

  bool _show_editor = false;

  bool get show_editor => this._show_editor;

  ShowEditorStore() {
    triggerOnActionV2<bool>(this.set_show_editor, (show) => this._show_editor = show);
  }
}

// end Stores
////////////////////////////////////////////////

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

  MouseoverDataStore mouse_over_store = MouseoverDataStore();
  ShowDNAStore show_dna_store = ShowDNAStore();
  ShowMismatchesStore show_mismatches_store = ShowMismatchesStore();
  ShowEditorStore show_editor_store = ShowEditorStore();

  bool get show_dna => this.show_dna_store.show_dna;

  void set show_dna(bool new_show_dna) {
    this.show_dna_store.set_show_dna(new_show_dna);
  }

  bool get show_mismatches => this.show_mismatches_store.show_mismatches;

  void set show_mismatches(bool new_show_mismatches) {
    this.show_mismatches_store.set_show_mismatches(new_show_mismatches);
  }

  //TODO: make editing "mode": if editor mode=manual, no code editor. If mode=script, cannot edit design manually.
  //  Then it's ubambiguous what Ctrl+Z should do
  bool get show_editor => this.show_editor_store.show_editor;

  void set show_editor(bool new_show_editor) {
    this.show_editor_store.set_show_editor(new_show_editor);
  }

}

class MainViewSelection {
  List<BoundSubstrand> starts = [];
  List<BoundSubstrand> ends = [];
  List<Crossover> crossovers = [];
  List<BoundSubstrand> substrands = [];
}

class Crossover {
  BoundSubstrand substrand_5p = null;
  BoundSubstrand substrand_3p = null;
}

////////////////////////////////////////////////
// SideViewUIModel

class SideViewSelection {
  List<Helix> helices = [];
}

class SideViewUIModel {
  SideViewSelection selection = SideViewSelection();
}
