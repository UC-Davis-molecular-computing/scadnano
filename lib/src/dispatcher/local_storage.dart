import 'dart:html';

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

  static final values = [show_dna];
}

const String _LOCAL_STORAGE_PREFIX = "scadnano:";

save(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.key;
  if (storable == Storable.show_dna) {
    window.localStorage[storable_key] = app.model.main_view_ui_model.show_dna.toString();
  }
}

restore(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.key;
  if (window.localStorage.containsKey(storable_key)) {
    var value = window.localStorage[storable_key];

    if (storable == Storable.show_dna) {
      Actions.set_show_dna(value == 'true');
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
