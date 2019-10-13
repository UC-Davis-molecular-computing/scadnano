import 'dart:convert';
import 'dart:html';

import 'package:scadnano/src/model/edit_mode.dart';
import 'package:scadnano/src/model/select_mode.dart';

import '../app.dart';
import 'actions.dart';

//TODO: put whole DNADesign in here, as well as UI options such as "Show DNA"

/// Aspects of model that can be stored in localStorage.
/// This constitutes more than is saved in jsonStorage, including things like
/// parts of the *UIModels, i.e., where certain visual elements are located.
class Storable {
  final String key;

  Storable(this.key);

  static final show_dna = Storable('show_dna');
  static final edit_mode = Storable('edit_mode');
  static final select_mode = Storable('select_mode');

  static final values = [show_dna, edit_mode, select_mode];
}

const String _LOCAL_STORAGE_PREFIX = "scadnano:";

save(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.key;
  if (storable == Storable.show_dna) {
    window.localStorage[storable_key] = app.model.main_view_ui_model.show_dna.toString();

  } else if (storable == Storable.edit_mode) {
    window.localStorage[storable_key] = app.model.edit_mode_store.to_json();

  } else if (storable == Storable.select_mode) {
    window.localStorage[storable_key] = app.model.select_mode_store.to_json();
  }
}

restore(Storable storable) {
  try {
    _restore(storable);
  } catch (e) {
    print('ERROR: loading from localStorage, encountered this error:\n${e.toString()}');
  }
}

_restore(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.key;
  if (window.localStorage.containsKey(storable_key)) {
    var value = window.localStorage[storable_key];

    if (storable == Storable.show_dna) {
      Actions.set_show_dna(value == 'true');

    } else if (storable == Storable.edit_mode) {
      EditModeChoice mode = EditModeChoice.from_json(value);
      Actions.set_edit_mode(mode);

    } else if (storable == Storable.select_mode) {
      List<dynamic> mode_names = jsonDecode(value);
      List<SelectModeChoice> modes = mode_names.map((name) => SelectModeChoice.from_json(name)).toList();
      Actions.set_select_modes(modes);

    }
  }
}

save_all_local_storage() {
  for (Storable storable in Storable.values) {
    save(storable);
  }
}

restore_all_local_storage() {
  for (Storable storable in Storable.values) {
    restore(storable);
  }
}
