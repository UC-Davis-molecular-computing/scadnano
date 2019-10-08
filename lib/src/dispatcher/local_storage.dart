import 'dart:html';

//TODO: put whole DNADesign in here, as well as UI options such as "Show DNA"

/// Aspects of model that can be stored in localStorage.
/// This constitutes more than is saved in jsonStorage, including things like
/// parts of the *UIModels, i.e., where certain visual elements are located.
enum Storable { zoom_speed }

const String _LOCAL_STORAGE_PREFIX = "scadnano:";

save(Storable storable) {
//  String storableKey = _LOCAL_STORAGE_PREFIX + storable.toString();
  switch (storable) {
    case Storable.zoom_speed:
//      window.localStorage[storableKey] = model.zoomSpeed.toString();
      break;
  }
}

restore(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.toString();
  if (window.localStorage.containsKey(storable_key)) {
    switch (storable) {
      case Storable.zoom_speed:
//        model.zoomSpeed = double.parse(window.localStorage[storableKey]);
        break;
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
