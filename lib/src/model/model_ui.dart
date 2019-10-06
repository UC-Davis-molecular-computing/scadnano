import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:w_flux/w_flux.dart';

import 'helix.dart';

//TODO: add ability for user to ctrl+click (or some special key click) at offset on helix to set that helix's notion
// of DNA backbones rotation, which will then be displayed in the side view on all other offsets

////////////////////////////////////////////////
// Stores

class ShowDNAStore extends Store {
  bool _show_dna = true;

  bool get show_dna => this._show_dna;

  ShowDNAStore() {
    triggerOnActionV2<bool>(Actions.set_show_dna, (show) {
      this._show_dna = show;
    });
  }
}

class ShowMismatchesStore extends Store {
  bool _show_mismatches = true;

  bool get show_mismatches => this._show_mismatches;

  ShowMismatchesStore() {
    triggerOnActionV2<bool>(Actions.set_show_mismatches, (show) => this._show_mismatches = show);
  }
}

class ShowEditorStore extends Store {
  bool _show_editor = false;

  bool get show_editor => this._show_editor;

  ShowEditorStore() {
    triggerOnActionV2<bool>(Actions.set_show_editor, (show) => this._show_editor = show);
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
// SideViewUIModel

class SideViewSelection {
  List<Helix> helices = [];
}

class SideViewUIModel {
  SideViewSelection selection = SideViewSelection();
}
