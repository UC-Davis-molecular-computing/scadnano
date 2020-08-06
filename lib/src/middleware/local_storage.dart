import 'dart:convert';
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/design.dart';
import '../state/app_ui_state_storables.dart';
import '../serializers.dart';
import '../state/local_storage_design_choice.dart';

import '../json_serializable.dart';
import '../state/app_state.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'local_storage.g.dart';

/// Aspects of state that can be stored in localStorage. (More like a StorableType; the thing stored is
/// somewhere in the Model, and this is an "ID" associated with it.
class Storable extends EnumClass {
  const Storable._(String name) : super(name);

  static const Storable design = _$design;
  static const Storable app_ui_state_storables = _$app_ui_state_storables;

  static BuiltSet<Storable> get values => _$values;

  static Storable valueOf(String name) => _$valueOf(name);

  String get key_name => _LOCAL_STORAGE_PREFIX + name;
}

const String _LOCAL_STORAGE_PREFIX = "scadnano:";

save(AppState state, Storable storable) {
  String storable_key = storable.key_name;
  String value_string;
  if (storable == Storable.design) {
    var design = state.design;
//    value_string = json_encode(design);
    value_string = json_encode(design, false);
  } else if (storable == Storable.app_ui_state_storables) {
    value_string = jsonEncode(standard_serializers.serialize(state.ui_state.storables));
  }

  if (value_string != null) window.localStorage[storable_key] = value_string;
}

String side_pane_width() => window.localStorage[_LOCAL_STORAGE_PREFIX + 'side_pane_width'];

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
  String storable_key = storable.key_name;
  if (window.localStorage.containsKey(storable_key)) {
    var json_str = window.localStorage[storable_key];

    actions.Action action = null;

    if (storable == Storable.design) {
      // TODO(benlee12): Ugly because this forces design to be loaded before the app
      // state because the filename could be overwritten.
      var storable_json_str = window.localStorage[Storable.app_ui_state_storables.key_name];
      var storable_json_map = json.decode(storable_json_str);
      AppUIStateStorables storables = null;
      try {
        storables = standard_serializers.deserialize(storable_json_map);
      } catch (e, stackTrace) {
        print('ERROR: in loading design from localStorage, encountered this error trying to load '
            'app_ui_state_storables, so a default filename has been chosen:'
            '\n${e.toString()}'
            '\n\nstack trace:'
            '\n\n${stackTrace}');
      }
      action = actions.LoadDNAFile(
          content: json_str,
          filename: storables?.loaded_filename ?? 'default_filename.sc',
          write_local_storage: false);
    } else if (storable == Storable.app_ui_state_storables) {
      var storable_json_map = json.decode(json_str);
      AppUIStateStorables storables = standard_serializers.deserialize(storable_json_map);
      action = actions.SetAppUIStateStorable(storables);
      // TODO(benlee12): Ugly because this forces design to be loaded before the app
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

save_storable_async(AppState state, Storable storable) async {
  save(state, storable);
}

local_storage_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  AppUIStateStorables storables_before = store.state.ui_state.storables;
  Design design_before = store.state.design;
  next(action);
  AppUIStateStorables storables_after = store.state.ui_state.storables;
  Design design_after = store.state.design;
  var state_after = store.state;

  if (storables_before != storables_after) {
    if (action is actions.LoadDNAFile && action.write_local_storage || action is! actions.LoadDNAFile) {
      save_storable_async(state_after, Storable.app_ui_state_storables);
    }
  }

  if (storables_after.local_storage_design_choice.option == LocalStorageDesignOption.on_edit &&
      design_before != design_after) {
    if (action is! actions.UndoableAction &&
        action is! actions.LoadDNAFile &&
        action is! actions.Undo &&
        action is! actions.Redo) {
      print('WARNING: some Action changed the design, so I am writing the Design to localStorage,\n'
          'but that action is not UndoableAction, LoadDNAFile, Undo, or Redo\n'
          'action is ${action}');
    }
    save_storable_async(state_after, Storable.design);
  }

  // if user selects to save DNADesign on every edit or periodically,
  // we should save even before they've made an edit
  if (action is actions.LocalStorageDesignChoiceSet &&
      (action.choice.option == LocalStorageDesignOption.on_edit ||
          action.choice.option == LocalStorageDesignOption.periodic)) {
    save_storable_async(state_after, Storable.design);
  }
}
