import 'dart:convert';
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/edit_mode.dart';

import '../state/app_state.dart';
import '../state/select_mode.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;

part 'local_storage.g.dart';

/// Aspects of state that can be stored in localStorage. (More like a StorableType; the thing stored is
/// somewhere in the Model, and this is an "ID" associated with it.
class Storable extends EnumClass {
  const Storable._(String name) : super(name);

  static const Storable dna_design = _$dna_design;
  static const Storable show_dna = _$show_dna;
  static const Storable show_mismatches = _$show_mismatches;
  static const Storable show_editor = _$show_editor;
  static const Storable edit_modes = _$edit_modes;
  static const Storable editor_mode = _$editor_mode;
  static const Storable select_modes = _$select_modes;

  static BuiltSet<Storable> get values => _$values;

  static Storable valueOf(String name) => _$valueOf(name);
}

const String _LOCAL_STORAGE_PREFIX = "scadnano:";

save(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.name;
  String value_string;

  if (storable == Storable.show_dna) {
    value_string = app.state.ui_state.show_dna.toString();
  } else if (storable == Storable.show_mismatches) {
    value_string = app.state.ui_state.show_mismatches.toString();
  } else if (storable == Storable.edit_modes) {
    List<String> edit_modes_list = [for (var mode in app.state.ui_state.edit_modes) mode.name];
    value_string = jsonEncode(edit_modes_list);
  } else if (storable == Storable.editor_mode) {
    value_string = app.state.ui_state.show_editor.toString();
  } else if (storable == Storable.select_modes) {
    value_string = app.state.ui_state.select_mode_state.to_json();
  }

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
  } catch (e) {
    print('ERROR: loading from localStorage, encountered this error:\n${e.toString()}');
  }
}

_restore(Storable storable) {
  String storable_key = _LOCAL_STORAGE_PREFIX + storable.name;
  if (window.localStorage.containsKey(storable_key)) {
    var value = window.localStorage[storable_key];

    actions.Action action = null;

    if (storable == Storable.show_dna) {
//      action = dispatcher.SetShowDNA.from((s) => s..show_dna = (value == 'true'));
      action = actions.SetShowDNA(value == 'true');

    } else if (storable == Storable.show_mismatches) {
      action = actions.SetShowMismatches(value == 'true');

    } else if (storable == Storable.show_editor) {
      action = actions.SetShowEditor(value == 'true');

    } else if (storable == Storable.editor_mode) {
//      EditModeChoice mode = EditModeChoice.from_json(value);
      //FIXME: implement this

    } else if (storable == Storable.edit_modes) {
      List<dynamic> mode_names = jsonDecode(value);
      List<EditModeChoice> modes = mode_names.map((name) => EditModeChoice.from_json(name)).toList();
      action = actions.EditModesSet(modes);

    } else if (storable == Storable.select_modes) {
      List<dynamic> mode_names = jsonDecode(value);
      List<SelectModeChoice> modes = mode_names.map((name) => SelectModeChoice.from_json(name)).toList();
      action = actions.SelectModesSet(modes);
    }

    if (action != null) {
      app.dispatch(action);
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

local_storage_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);
  if (action is actions.StorableAction) {
    for (var storable in action.storables()) {
      save(storable);
    }
  }
}
