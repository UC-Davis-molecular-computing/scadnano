import 'dart:convert';
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_ui_state.dart';
import 'package:scadnano/src/serializers.dart';

import '../json_serializable.dart';
import '../state/app_state.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;

part 'local_storage.g.dart';

/// Aspects of state that can be stored in localStorage. (More like a StorableType; the thing stored is
/// somewhere in the Model, and this is an "ID" associated with it.
class Storable extends EnumClass {
  const Storable._(String name) : super(name);

  static const Storable dna_design = _$dna_design;
  static const Storable app_ui_state_storables = _$app_ui_state_storables;

  static BuiltSet<Storable> get values => _$values;

  static Storable valueOf(String name) => _$valueOf(name);
}

const String _LOCAL_STORAGE_PREFIX = "scadnano:";

save(AppState state, Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.name;
  String value_string;
  if ((storable == Storable.dna_design) && (state.ui_state.save_dna_design_in_local_storage)) {
    var dna_design = state.dna_design;
    value_string = json_encode(dna_design);
  } else if (storable == Storable.app_ui_state_storables) {
    value_string = jsonEncode(standard_serializers.serialize(state.ui_state.storables));
  }

  if (value_string != null)
    window.localStorage[storable_key] = value_string;
}

String side_pane_width() {
  String key = _LOCAL_STORAGE_PREFIX + 'side_pane_width';
  if (window.localStorage.containsKey(key)) {
    return window.localStorage[key];
  } else {
    return null;
  }
}

restore(Storable storable) {
  try {
    _restore(storable);
  } catch (e, stackTrace) {
    print('ERROR: loading ${storable} from localStorage, encountered this error:'
        '\n${e.toString()}'
        '\n\nstack trace:'
        '\n\n${stackTrace}');
  }
}

_restore(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.name;
  if (window.localStorage.containsKey(storable_key)) {
    var json_str = window.localStorage[storable_key];

    actions.Action action = null;

    if (storable == Storable.dna_design) {
      // TODO(benlee12): Ugly because this forces dna to be loaded before the app
      // state because the filename could be overwritten.
      action = actions.LoadDNAFile(content: json_str, filename: null);
    } else if (storable == Storable.app_ui_state_storables) {
      var storable_json_map = json.decode(json_str);
      AppUIStateStorable storables = standard_serializers.deserialize(storable_json_map);
      action = actions.SetAppUIStateStorable(storables);
      // TODO(benlee12): Ugly because this forces dna to be loaded before the app
      // state because the filename could be overwritten.
      document.title = storables.loaded_filename;
    }

    if (action != null) {
      app.dispatch(action);
    }
  }
}

restore_all_local_storage() {
  for (Storable storable in Storable.values) {
    restore(storable);
  }
}

save_async(AppState state, Iterable<Storable> storables) async {
  for (var storable in storables) {
    save(state, storable);
  }
}

local_storage_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  var state_before = store.state;
  next(action);
  var state_after = store.state;
  if (action is actions.AppUIStateStorableAction) {
    save_async(state_after, [Storable.app_ui_state_storables]);
  }
  if (action is actions.StorableAction) {
    save_async(state_after, action.storables());
  }
}
