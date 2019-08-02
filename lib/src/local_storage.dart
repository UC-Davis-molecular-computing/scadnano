import 'dart:html';

//TODO: put whole DNADesign (and maybe parts of the *UIModels) in here

/// Aspects of model that can be stored in localStorage.
/// This constitutes more than is saved in jsonStorage, including things like
/// parts of the *UIModels, i.e., where certain visual elements are located.
enum Storable { zoom_speed }

const String _LOCAL_STORAGE_PREFIX = "s-cadnano:";

save(Storable storable) {
//  String storableKey = _LOCAL_STORAGE_PREFIX + storable.toString();
  switch (storable) {
    case Storable.zoom_speed:
//      window.localStorage[storableKey] = model.zoomSpeed.toString();
      break;
  }
}

restore(Storable storable) {
  String storableKey = _LOCAL_STORAGE_PREFIX + storable.toString();
  if (window.localStorage.containsKey(storableKey)) {
    switch (storable) {
      case Storable.zoom_speed:
//        model.zoomSpeed = double.parse(window.localStorage[storableKey]);
        break;
    }
  }
}

saveAllLocalStorage() {
  for (Storable storable in Storable.values) {
    save(storable);
  }
}

restore_all_local_storage() {
  for (Storable storable in Storable.values) {
    restore(storable);
  }
}
