import 'dart:convert';
import 'dart:core';

import 'package:w_flux/w_flux.dart';

import '../dispatcher/actions.dart';
import 'edit_mode.dart';
import 'composite_stores.dart';
import 'model_ui.dart';
import 'model_ui_side.dart';
import 'model_ui_main.dart';
import '../app.dart';
import 'dna_design.dart';

class Model extends Store {
  MenuViewUIModel menu_view_ui_model = MenuViewUIModel();
  EditorViewUIModel editor_view_ui_model = EditorViewUIModel();
  MainViewUIModel main_view_ui_model = MainViewUIModel();
  SideViewUIModel side_view_ui_model = SideViewUIModel();

  // composite stores
  DNASequencesStore dna_sequences_store;
  MismatchesStore mismatches_store;
  ShowStore show_store;
  DesignOrErrorStore design_or_error_store;

  // basic stores
  DNADesign _dna_design;
  ErrorMessageStore error_message_store = ErrorMessageStore();
  EditModeStore edit_mode_store = EditModeStore();

  String _editor_content = "";

  /// Save button is enabled iff this is true
  bool changed_since_last_save = false;

  //It's handy to have convenience getters and setters for Model, but for things delegated to contained
  // model parts like MainViewUIModel, we don't fire a changed notification, but let the sub-part do it.
  bool get show_dna => this.main_view_ui_model.show_dna;

  bool get show_mismatches => this.main_view_ui_model.show_mismatches;

  bool get show_editor => this.main_view_ui_model.show_editor;

  String _error_message = null;

  Model.default_model({int num_helices_x = 10, int num_helices_y = 10}) {
    this._handle_actions();
    this._dna_design = DNADesign.default_design(num_helices_x: num_helices_x, num_helices_y: num_helices_y);
    this._initialize_composite_stores();
  }

  Model.empty() {
    this._handle_actions();
    this._dna_design = DNADesign();
    this._initialize_composite_stores();
  }

  _initialize_composite_stores() {
    this.dna_sequences_store =
        DNASequencesStore(this._dna_design.strands_store, this.main_view_ui_model.show_dna_store);
    this.mismatches_store =
        MismatchesStore(this._dna_design.strands_store, this.main_view_ui_model.show_mismatches_store);
    this.show_store = ShowStore(this.main_view_ui_model.show_dna_store, this.main_view_ui_model.show_mismatches_store,
        this.main_view_ui_model.show_editor_store);
    this.design_or_error_store = DesignOrErrorStore(this.dna_design, this.error_message_store);
  }

  _handle_actions() {
    this.error_message_store.triggerOnActionV2<String>(Actions.set_error_message, (msg) {
      this.error_message = msg;
      app.undo_redo.reset();
    });

    this.triggerOnActionV2<LoadDNAFileParameters>(Actions.load_dna_file, (params) {
      this.set_new_design_from_json(params.content);
    });
  }

  //TODO: this is crashing when we save; debug it
  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    return this._dna_design.to_json_serializable();
  }

  DNADesign get dna_design => this._dna_design;

  String get error_message => this._error_message;

  String get editor_content => this._editor_content;

  set error_message(String new_msg) {
    this.error_message_store.error_message = new_msg;
  }

  clear_error() {
    this.error_message_store.clear();
  }

  bool has_error() => this.error_message_store.has_error();

  set editor_content(String new_content) {
    this._editor_content = new_content;
//    context[constants.editor_content_js_key] = new_content;
  }

  set_new_design_from_json(String json_model_text) {
    Map<String, dynamic> deserialized_map = jsonDecode(json_model_text);
    this.set_new_design_from_map(deserialized_map);
  }

  set_new_design_from_map(Map map) {
    try {
      this.dna_design.read_from_json(map);
      this.changed_since_last_save = false;
      app.undo_redo.reset();
      this.clear_error();
    } on IllegalDNADesignError catch (error) {
      Actions.set_error_message(error.cause);
    }
  }
}

class ErrorMessageStore extends Store {
  String _error_message;

  String get error_message => this._error_message;

  set error_message(String new_msg) {
    this._error_message = new_msg;
  }

  bool has_error() => this._error_message != null;

  clear() {
    this._error_message = null;
  }
}
