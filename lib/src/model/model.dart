import 'dart:async';
import 'dart:core';

import 'package:meta/meta.dart';

import 'model_ui.dart';
import '../app.dart';
import 'dna_design.dart';

class Model with ChangeNotifier<Model> {
  DNADesign _dna_design;

  String _editor_content = "";

  MenuViewUIModel menu_view_ui_model = MenuViewUIModel();
  EditorViewUIModel editor_view_ui_model = EditorViewUIModel();
  MainViewUIModel main_view_ui_model = MainViewUIModel();
  SideViewUIModel side_view_ui_model = SideViewUIModel();

  /// Save button is enabled iff this is true
  bool changed_since_last_save = false;

  //It's handy to have convenience getters and setters for Model, but for things delegated to contained
  // model parts like MainViewUIModel, we don't fire a changed notification, but let the sub-part do it.
  bool get show_dna => this.main_view_ui_model.show_dna;

  set show_dna(bool show) {
    this.main_view_ui_model.show_dna = show;
  }

  bool get show_mismatches => this.main_view_ui_model.show_mismatches;

  set show_mismatches(bool show) {
    this.main_view_ui_model.show_mismatches = show;
  }

  bool get show_editor => this.main_view_ui_model.show_editor;

  set show_editor(bool show) {
    this.main_view_ui_model.show_editor = show;
  }

  String _error_message = null;

  //"private" constructor; meta package will warn if it is used outside testing
  @visibleForTesting
  Model.internal() {
    this._set_change_notifier();
  }

  Model.default_model({int num_helices_x = 10, int num_helices_y = 10}) {
    this._dna_design = DNADesign.default_design(num_helices_x: num_helices_x, num_helices_y: num_helices_y);
    this._set_change_notifier();
  }

  Model.empty() {
    this._set_change_notifier();
  }

  _set_change_notifier() {
    this.notifier = app.controller.notifier_model_change;
  }

  //TODO: this is crashing when we save; debug it
  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    return this._dna_design.to_json_serializable();
  }

  DNADesign get dna_design => this._dna_design;

  String get error_message => this._error_message;

  String get editor_content => this._editor_content;

  set dna_design(DNADesign new_dna_design) {
    this._dna_design = new_dna_design;
    this.notify_changed();
  }

  set error_message(String new_msg) {
    this._error_message = new_msg;
    this.notify_changed();
  }

  set editor_content(String new_content) {
    this._editor_content = new_content;
//    context[constants.editor_content_js_key] = new_content;
  }
}

/// Use this mixin to get listener functionality for when an object changes and listeners need to be notified.
/// Must pass an existing instance of a notifier (should be stored in central location like Controller).
/// This avoids the issues of Model and View objects being created and destroyed and the notifiers/listeners
/// not updating properly.
class ChangeNotifier<T> {
//  final StreamController<T> notifier = StreamController<T>.broadcast();
  StreamController<T> notifier;

  listen_for_change(void Function(T) listener) {
    this.notifier.stream.listen(listener);
  }

  notify_changed() {
    if (this.notifier != null) {
      this.notifier.add(this as T);
    }
  }
}
